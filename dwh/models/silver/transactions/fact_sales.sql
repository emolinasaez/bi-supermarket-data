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
      - Códigos especiales (M, D, POST, DOT, etc.)
      - Registros inválidos
    
    Transformaciones:
      - JOIN con dim_products para descripción normalizada
      - Conversión de tipos de datos
      - Campos calculados (total_sale, year, month, week)
      - Clasificación de transaction_type
*/

WITH classified_transactions AS (
    SELECT 
        -- Identificadores
        "InvoiceNo" as invoice_no,
        "StockCode" as stock_code,
        CAST("CustomerID" AS INTEGER) as customer_id,
        TRIM("Country") as country,
        
        -- Fechas
        STRPTIME("InvoiceDate", '%m/%d/%Y %H:%M') as invoice_date,
        
        -- Métricas
        CAST("Quantity" AS INTEGER) as quantity,
        CAST("UnitPrice" AS DECIMAL(10,2)) as unit_price,
        
        -- Clasificación de transacción
        CASE 
            WHEN "InvoiceNo" LIKE 'C%' THEN 'RETURN'
            WHEN CAST("Quantity" AS INTEGER) > 0 THEN 'SALE'
            ELSE 'OTHER'
        END as transaction_type
        
    FROM {{ source('bronze', 'raw_data') }}
    WHERE 
        -- Excluir códigos especiales
        "StockCode" NOT IN ('M', 'D', 'POST', 'DOT', 'BANK CHARGES', 'C2', 'PADS', 'S', 'B')
        AND LENGTH("StockCode") > 1
        
        -- Excluir ajustes de inventario
        AND NOT ("UnitPrice" = '0' AND "CustomerID" IS NULL AND CAST("Quantity" AS INTEGER) < 0)
        
        -- Validaciones básicas
        AND "StockCode" IS NOT NULL
        AND "InvoiceNo" IS NOT NULL
        AND "InvoiceDate" IS NOT NULL
        AND "UnitPrice" IS NOT NULL
        AND "Quantity" IS NOT NULL
        AND CAST("UnitPrice" AS DECIMAL(10,2)) > 0
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
