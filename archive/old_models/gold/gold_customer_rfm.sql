{{
    config(
        materialized='table',
        schema='gold',
        tags=['gold', 'analytics', 'rfm']
    )
}}

/*
    Capa Gold - Métricas RFM por Cliente
    =====================================
    Calcula las tres métricas fundamentales del análisis RFM:
    
    - Recency (R): Días desde la última compra hasta la fecha de análisis
    - Frequency (F): Número total de transacciones únicas del cliente
    - Monetary (M): Valor total gastado por el cliente
    
    Fecha de análisis: Configurable en dbt_project.yml (var: analysis_date)
*/

WITH customer_metrics AS (
    SELECT
        customer_id,
        
        -- RECENCY: Días desde la última compra
        DATEDIFF('day', 
                 MAX(invoice_date_only), 
                 CAST('{{ var("analysis_date") }}' AS DATE)
        ) AS recency_days,
        
        -- FREQUENCY: Número de facturas únicas
        COUNT(DISTINCT invoice_no) AS frequency,
        
        -- MONETARY: Valor total de compras
        SUM(total_sale) AS monetary_value,
        
        -- Métricas adicionales
        COUNT(*) AS total_items_purchased,
        AVG(total_sale) AS avg_transaction_value,
        MIN(invoice_date_only) AS first_purchase_date,
        MAX(invoice_date_only) AS last_purchase_date,
        
        -- Metadata
        CURRENT_TIMESTAMP AS calculated_at
        
    FROM {{ ref('silver_cleaned_transactions') }}
    
    GROUP BY customer_id
)

SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary_value, 2) AS monetary_value,
    total_items_purchased,
    ROUND(avg_transaction_value, 2) AS avg_transaction_value,
    first_purchase_date,
    last_purchase_date,
    
    -- Tiempo como cliente (días)
    DATEDIFF('day', first_purchase_date, last_purchase_date) AS customer_lifetime_days,
    
    calculated_at
    
FROM customer_metrics

-- Filtrar clientes con al menos una compra válida
WHERE frequency > 0
    AND monetary_value > 0
