{{
    config(
        materialized='table',
        schema='silver',
        tags=['silver', 'cancellations', 'audit']
    )
}}

/*
    Capa Silver - Log de Cancelaciones
    ===================================
    Tabla separada para analizar transacciones canceladas.
    Útil para análisis de devoluciones y comportamiento de cancelación.
    
    Las facturas que inician con 'C' son cancelaciones/devoluciones.
*/

SELECT
    -- Clave subrogada
    {{ dbt_utils.generate_surrogate_key(['InvoiceNo', 'StockCode', 'InvoiceDate']) }} AS cancellation_id,
    
    -- Campos originales
    "InvoiceNo" AS invoice_no,
    SUBSTRING("InvoiceNo", 2) AS original_invoice_no,  -- Remover la 'C' inicial
    "StockCode" AS stock_code,
    "Description" AS description,
    CAST("Quantity" AS INTEGER) AS quantity,
    CAST("InvoiceDate" AS TIMESTAMP) AS cancellation_date,
    CAST("UnitPrice" AS DECIMAL(10,2)) AS unit_price,
    CAST("CustomerID" AS INTEGER) AS customer_id,
    "Country" AS country,
    
    -- Valor de la cancelación (negativo)
    CAST("Quantity" AS DECIMAL(10,2)) * CAST("UnitPrice" AS DECIMAL(10,2)) AS cancellation_amount,
    
    -- Metadata
    CURRENT_TIMESTAMP AS loaded_at
    
FROM {{ ref('bronze_raw_data') }}

WHERE "InvoiceNo" LIKE 'C%'
    AND "CustomerID" IS NOT NULL
