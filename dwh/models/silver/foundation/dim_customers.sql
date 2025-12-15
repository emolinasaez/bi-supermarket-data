{{
    config(
        materialized='table',
        schema='silver'
    )
}}

/*
    Customer Master - Dimensión de clientes
    
    Objetivo: Crear tabla de referencia de clientes únicos
    Nota: 24.93% de transacciones tienen CustomerID NULL (transacciones anónimas)
*/

WITH customer_data AS (
    SELECT 
        CAST("CustomerID" AS INTEGER) as customer_id,
        "Country" as country,
        MIN(STRPTIME("InvoiceDate", '%m/%d/%Y %H:%M')) as first_purchase_date,
        MAX(STRPTIME("InvoiceDate", '%m/%d/%Y %H:%M')) as last_purchase_date,
        COUNT(DISTINCT "InvoiceNo") as total_orders,
        COUNT(*) as total_line_items
    FROM {{ source('bronze', 'raw_data') }}
    WHERE "CustomerID" IS NOT NULL
      AND "CustomerID" != ''
    GROUP BY CAST("CustomerID" AS INTEGER), "Country"
)

SELECT 
    customer_id,
    country,
    first_purchase_date,
    last_purchase_date,
    total_orders,
    total_line_items,
    DATEDIFF('day', first_purchase_date, last_purchase_date) as customer_lifetime_days,
    CURRENT_TIMESTAMP as processed_at
FROM customer_data
ORDER BY customer_id
