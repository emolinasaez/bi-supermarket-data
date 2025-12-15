{{
    config(
        materialized='table',
        schema='silver'
    )
}}

/*
    Fact Accounting Adjustments - Ajustes contables (descuentos, envíos, etc.)
    
    Objetivo: Análisis de ajustes contables separado de transacciones de productos
    Incluye: Códigos especiales M, D, POST, DOT, BANK CHARGES, etc.
*/

SELECT 
    "InvoiceNo" as invoice_no,
    STRPTIME("InvoiceDate", '%m/%d/%Y %H:%M') as invoice_date,
    EXTRACT(YEAR FROM STRPTIME("InvoiceDate", '%m/%d/%Y %H:%M')) as year,
    EXTRACT(MONTH FROM STRPTIME("InvoiceDate", '%m/%d/%Y %H:%M')) as month,
    "StockCode" as stock_code,
    "Description" as description,
    CAST("CustomerID" AS INTEGER) as customer_id,
    TRIM("Country") as country,
    CAST("Quantity" AS INTEGER) as quantity,
    CAST("UnitPrice" AS DECIMAL(10,2)) as unit_price,
    CAST("Quantity" AS INTEGER) * CAST("UnitPrice" AS DECIMAL(10,2)) as total_amount,
    
    -- Clasificación de ajuste
    CASE 
        WHEN "StockCode" = 'M' THEN 'MANUAL_ADJUSTMENT'
        WHEN "StockCode" = 'D' THEN 'DISCOUNT'
        WHEN "StockCode" = 'POST' THEN 'POSTAGE'
        WHEN "StockCode" = 'DOT' THEN 'DOTCOM_ADJUSTMENT'
        WHEN "StockCode" = 'BANK CHARGES' THEN 'BANK_CHARGES'
        WHEN "StockCode" = 'C2' THEN 'CARRIAGE'
        WHEN "StockCode" = 'S' THEN 'SAMPLES'
        WHEN "StockCode" = 'B' THEN 'BAD_DEBT_ADJUSTMENT'
        ELSE 'OTHER'
    END as adjustment_type,
    
    -- Metadatos
    CURRENT_TIMESTAMP as processed_at
    
FROM {{ source('bronze', 'raw_data') }}
WHERE "StockCode" IN ('M', 'D', 'POST', 'DOT', 'BANK CHARGES', 'C2', 'PADS', 'S', 'B', 'AMAZONFEE', 'CRUK')
   OR LENGTH("StockCode") = 1
ORDER BY invoice_date
