{{
    config(
        materialized='table',
        schema='silver'
    )
}}

/*
    Product Master - Fuente única de verdad para nombres de productos
    
    Objetivo: Normalizar descripciones inconsistentes identificadas en Bronze
    Problema resuelto: 15.97% de productos (650 de 4,070) con múltiples descripciones
    
    Reglas de selección de descripción canónica:
    1. Excluir NULL
    2. Excluir notas operativas: 'check', 'test', 'manual', 'found', 'adjustment', 'Amazon'
    3. Excluir notas de inventario: 'damaged', 'wet/rusty', 'missing', '???'
    4. Excluir descripciones muy cortas (< 3 caracteres)
    5. Excluir palabras clave problemáticas
    6. Seleccionar la descripción con MAYOR FRECUENCIA
    7. En caso de empate, seleccionar la MÁS LARGA (más descriptiva)
*/

WITH product_descriptions AS (
    SELECT 
        "StockCode" as stock_code,
        "Description" as description,
        COUNT(*) as frequency,
        LENGTH("Description") as description_length
    FROM {{ source('bronze', 'raw_data') }}
    WHERE "StockCode" IS NOT NULL
      AND "Description" IS NOT NULL
      -- Excluir notas operativas
      AND LOWER("Description") NOT IN ('check', 'test', 'manual', 'found', 'adjustment', 'amazon')
      -- Excluir notas de inventario
      AND LOWER("Description") NOT IN ('damaged', 'wet/rusty', 'missing', '???', 'lost', 'lost??')
      -- Excluir descripciones muy cortas
      AND LENGTH("Description") >= 3
      -- Excluir palabras clave problemáticas
      AND "Description" NOT LIKE '%wrongly%'
      AND "Description" NOT LIKE '%marked%'
      AND "Description" NOT LIKE '%cant manage%'
      AND "Description" NOT LIKE '%alan hodge%'
    GROUP BY "StockCode", "Description"
),

ranked_descriptions AS (
    SELECT 
        stock_code,
        description,
        frequency,
        description_length,
        ROW_NUMBER() OVER (
            PARTITION BY stock_code 
            ORDER BY 
                frequency DESC,           -- Prioridad 1: Más frecuente
                description_length DESC   -- Prioridad 2: Más larga
        ) as rank
    FROM product_descriptions
),

canonical_products AS (
    SELECT 
        stock_code,
        description as canonical_description,
        frequency as times_used,
        description_length
    FROM ranked_descriptions
    WHERE rank = 1
),

product_stats AS (
    SELECT 
        "StockCode" as stock_code,
        COUNT(DISTINCT "Description") as num_variations,
        COUNT(*) as total_transactions,
        MIN(STRPTIME("InvoiceDate", '%m/%d/%Y %H:%M')) as first_seen,
        MAX(STRPTIME("InvoiceDate", '%m/%d/%Y %H:%M')) as last_seen
    FROM {{ source('bronze', 'raw_data') }}
    WHERE "StockCode" IS NOT NULL
    GROUP BY "StockCode"
)

SELECT 
    cp.stock_code,
    cp.canonical_description,
    cp.times_used,
    ps.num_variations,
    ps.total_transactions,
    ps.first_seen,
    ps.last_seen,
    CURRENT_TIMESTAMP as processed_at
FROM canonical_products cp
LEFT JOIN product_stats ps ON cp.stock_code = ps.stock_code
ORDER BY cp.stock_code
