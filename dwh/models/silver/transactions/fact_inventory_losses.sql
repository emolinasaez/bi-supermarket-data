{{
    config(
        materialized='table',
        schema='silver'
    )
}}

/*
    Fact Inventory Losses - Ajustes de inventario con costos imputados
    
    Objetivo: Análisis de mermas y control operacional
    Incluye: Registros con UnitPrice=0, CustomerID=NULL, Quantity<0
    
    Transformación crítica:
      - Imputación de precio usando precio promedio del producto
      - Cálculo de pérdida real (estimated_loss)
      - Clasificación de categoría de pérdida
*/

WITH product_avg_price AS (
    SELECT 
        stock_code,
        AVG(unit_price) as avg_price,
        COUNT(*) as num_sales
    FROM {{ ref('fact_sales') }}
    WHERE unit_price > 0 AND quantity > 0
    GROUP BY stock_code
),

inventory_adjustments AS (
    SELECT 
        "InvoiceNo" as invoice_no,
        STRPTIME("InvoiceDate", '%m/%d/%Y %H:%M') as invoice_date,
        "StockCode" as stock_code,
        "Description" as description,
        CAST("Quantity" AS INTEGER) as quantity,
        CAST("UnitPrice" AS DECIMAL(10,2)) as recorded_price
    FROM {{ source('bronze', 'raw_data') }}
    WHERE "UnitPrice" = '0' 
      AND "CustomerID" IS NULL 
      AND CAST("Quantity" AS INTEGER) < 0
)

SELECT 
    ia.invoice_no,
    ia.invoice_date,
    EXTRACT(YEAR FROM ia.invoice_date) as year,
    EXTRACT(MONTH FROM ia.invoice_date) as month,
    EXTRACT(WEEK FROM ia.invoice_date) as week_number,
    EXTRACT(YEAR FROM ia.invoice_date) || '-' || LPAD(CAST(EXTRACT(MONTH FROM ia.invoice_date) AS VARCHAR), 2, '0') as year_month,
    EXTRACT(YEAR FROM ia.invoice_date) || '-W' || LPAD(CAST(EXTRACT(WEEK FROM ia.invoice_date) AS VARCHAR), 2, '0') as year_week,
    ia.stock_code,
    ia.description,
    ia.quantity,
    ia.recorded_price,
    
    -- Imputación de precio
    COALESCE(p.avg_price, 0) as imputed_price,
    ia.quantity * COALESCE(p.avg_price, 0) as estimated_loss,
    
    -- Clasificación de pérdida
    CASE 
        WHEN LOWER(ia.description) LIKE '%damage%' THEN 'DAMAGED'
        WHEN LOWER(ia.description) LIKE '%lost%' THEN 'LOST'
        WHEN LOWER(ia.description) LIKE '%unsaleable%' OR LOWER(ia.description) LIKE '%destroyed%' THEN 'UNSALEABLE'
        WHEN LOWER(ia.description) LIKE '%thrown away%' OR LOWER(ia.description) LIKE '%smudge%' THEN 'DISCARDED'
        WHEN LOWER(ia.description) LIKE '%breakage%' THEN 'BROKEN'
        ELSE 'OTHER'
    END as loss_category,
    
    -- Metadatos
    CURRENT_TIMESTAMP as processed_at
    
FROM inventory_adjustments ia
LEFT JOIN product_avg_price p ON ia.stock_code = p.stock_code
ORDER BY ia.invoice_date
