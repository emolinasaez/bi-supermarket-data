{{
    config(
        materialized='table',
        schema='silver'
    )
}}

/*
    Fact Sales - Transacciones de ventas y devoluciones limpias
    
    Objetivo: Tabla principal para análisis de ventas
    Incluye: SALE y RETURN
    Excluye: 
      - Ajustes de inventario (UnitPrice=0, CustomerID=NULL)
      - Códigos especiales (referenciados desde seed table)
      - Registros inválidos
    
    Transformaciones:
      - JOIN con dim_products para descripción normalizada
      - JOIN con excluded_stock_codes (seed) para filtrar no-productos
      - Conversión de tipos de datos
      - Campos calculados (total_sale, year, month, week)
      - Clasificación de transaction_type
*/

WITH excluded_codes AS (
    SELECT stock_code
    FROM {{ ref('excluded_stock_codes') }}
),

classified_transactions AS (
    SELECT 
        -- Identificadores
        b."InvoiceNo" as invoice_no,
        b."StockCode" as stock_code,
        CAST(b."CustomerID" AS INTEGER) as customer_id,
        TRIM(b."Country") as country,
        
        -- Fechas
        STRPTIME(b."InvoiceDate", '%m/%d/%Y %H:%M') as invoice_date,
        
        -- Métricas
        CAST(b."Quantity" AS INTEGER) as quantity,
        CAST(b."UnitPrice" AS DECIMAL(10,2)) as unit_price,
        
        -- Clasificación de transacción
        CASE 
            WHEN b."InvoiceNo" LIKE 'C%' THEN 'RETURN'
            WHEN CAST(b."Quantity" AS INTEGER) > 0 THEN 'SALE'
            ELSE 'OTHER'
        END as transaction_type
        
    FROM {{ source('bronze', 'raw_data') }} b
    LEFT JOIN excluded_codes e ON b."StockCode" = e.stock_code
    WHERE 
        -- Excluir códigos especiales usando seed table (no hardcoding)
        e.stock_code IS NULL
        AND LENGTH(b."StockCode") > 1
        
        -- Excluir ajustes de inventario
        AND NOT (b."UnitPrice" = '0' AND b."CustomerID" IS NULL AND CAST(b."Quantity" AS INTEGER) < 0)
        
        -- Validaciones básicas
        AND b."StockCode" IS NOT NULL
        AND b."InvoiceNo" IS NOT NULL
        AND b."InvoiceDate" IS NOT NULL
        AND b."UnitPrice" IS NOT NULL
        AND b."Quantity" IS NOT NULL
        AND CAST(b."UnitPrice" AS DECIMAL(10,2)) > 0
)

SELECT 
    -- Identificadores
    ct.invoice_no,
    ct.stock_code,
    COALESCE(p.canonical_description, ct.stock_code) as description,  -- JOIN con product_master
    ct.customer_id,
    ct.country,
    
    -- Fechas
    ct.invoice_date,
    EXTRACT(YEAR FROM ct.invoice_date) as invoice_year,
    EXTRACT(MONTH FROM ct.invoice_date) as invoice_month,
    EXTRACT(WEEK FROM ct.invoice_date) as invoice_week,
    EXTRACT(QUARTER FROM ct.invoice_date) as invoice_quarter,
    EXTRACT(DOW FROM ct.invoice_date) as day_of_week,
    ct.invoice_date::DATE as invoice_date_only,
    
    -- Métricas
    ct.quantity,
    ct.unit_price,
    ct.quantity * ct.unit_price as total_sale,
    
    -- Clasificación
    ct.transaction_type,
    
    -- Flags
    CASE WHEN ct.customer_id IS NULL THEN TRUE ELSE FALSE END as is_anonymous,
    CASE WHEN ct.transaction_type = 'RETURN' THEN TRUE ELSE FALSE END as is_return,
    
    -- Metadatos
    CURRENT_TIMESTAMP as processed_at
    
FROM classified_transactions ct
LEFT JOIN {{ ref('dim_products') }} p ON ct.stock_code = p.stock_code
WHERE ct.transaction_type IN ('SALE', 'RETURN')
ORDER BY ct.invoice_date, ct.invoice_no
