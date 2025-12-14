{{
    config(
        materialized='table',
        schema='silver',
        tags=['silver', 'cleaned', 'transactions']
    )
}}

/*
    Capa Silver - Transacciones Limpias
    ====================================
    Transformaciones aplicadas:
    1. Filtrado de transacciones canceladas (InvoiceNo que inicia con 'C')
    2. Filtrado de registros sin CustomerID
    3. Filtrado de cantidades y precios negativos o cero
    4. Cálculo de TotalVenta (Quantity * UnitPrice)
    5. Creación de clave subrogada (transaction_id)
    6. Conversión de tipos de datos
    7. Extracción de componentes de fecha
*/

WITH cleaned_data AS (
    SELECT
        -- Clave subrogada
        {{ dbt_utils.generate_surrogate_key(['InvoiceNo', 'StockCode', 'InvoiceDate']) }} AS transaction_id,
        
        -- Campos originales
        "InvoiceNo" AS invoice_no,
        "StockCode" AS stock_code,
        "Description" AS description,
        CAST("Quantity" AS INTEGER) AS quantity,
        CAST("InvoiceDate" AS TIMESTAMP) AS invoice_date,
        CAST("UnitPrice" AS DECIMAL(10,2)) AS unit_price,
        CAST("CustomerID" AS INTEGER) AS customer_id,
        "Country" AS country,
        
        -- Campos calculados
        CAST("Quantity" AS DECIMAL(10,2)) * CAST("UnitPrice" AS DECIMAL(10,2)) AS total_sale,
        
        -- Componentes de fecha
        DATE_TRUNC('day', CAST("InvoiceDate" AS TIMESTAMP)) AS invoice_date_only,
        EXTRACT(YEAR FROM CAST("InvoiceDate" AS TIMESTAMP)) AS invoice_year,
        EXTRACT(MONTH FROM CAST("InvoiceDate" AS TIMESTAMP)) AS invoice_month,
        EXTRACT(DAY FROM CAST("InvoiceDate" AS TIMESTAMP)) AS invoice_day,
        DAYNAME(CAST("InvoiceDate" AS TIMESTAMP)) AS day_of_week,
        
        -- Metadata
        CURRENT_TIMESTAMP AS loaded_at
        
    FROM {{ ref('bronze_raw_data') }}
    
    WHERE 1=1
        -- Excluir transacciones canceladas
        AND "InvoiceNo" NOT LIKE 'C%'
        
        -- Excluir registros sin cliente
        AND "CustomerID" IS NOT NULL
        
        -- Excluir cantidades inválidas
        AND "Quantity" > 0
        
        -- Excluir precios inválidos
        AND "UnitPrice" > 0
)

SELECT * FROM cleaned_data
