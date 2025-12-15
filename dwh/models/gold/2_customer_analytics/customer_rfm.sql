{{
    config(
        materialized='table',
        schema='gold'
    )
}}

/*
    Customer RFM - Segmentación de clientes
    
    Objetivo: Clasificar clientes por Recency, Frequency, Monetary
    Segmentos: Champions, Loyal, At Risk, etc.
*/

WITH customer_metrics AS (
    SELECT 
        customer_id,
        country,
        
        -- Recency (días desde última compra)
        DATEDIFF('day', MAX(invoice_date), CURRENT_DATE) as recency_days,
        
        -- Frequency (número de compras)
        COUNT(DISTINCT invoice_no) as frequency,
        
        -- Monetary (valor total)
        SUM(total_sale) as monetary_value,
        
        -- Métricas adicionales
        AVG(total_sale) as avg_order_value,
        MIN(invoice_date) as first_purchase_date,
        MAX(invoice_date) as last_purchase_date,
        DATEDIFF('day', MIN(invoice_date), MAX(invoice_date)) as customer_lifetime_days
        
    FROM {{ ref('fact_sales') }}
    WHERE customer_id IS NOT NULL
      AND transaction_type = 'SALE'
    GROUP BY customer_id, country
)

SELECT 
    customer_id,
    country,
    recency_days,
    frequency,
    monetary_value,
    avg_order_value,
    first_purchase_date,
    last_purchase_date,
    customer_lifetime_days,
    
    -- Scores RFM (1-5, donde 5 es mejor)
    NTILE(5) OVER (ORDER BY recency_days DESC) as r_score,  -- Menos días = mejor
    NTILE(5) OVER (ORDER BY frequency) as f_score,
    NTILE(5) OVER (ORDER BY monetary_value) as m_score,
    
    -- RFM Score combinado (ej: "555" = Champion)
    CAST(NTILE(5) OVER (ORDER BY recency_days DESC) AS VARCHAR) ||
    CAST(NTILE(5) OVER (ORDER BY frequency) AS VARCHAR) ||
    CAST(NTILE(5) OVER (ORDER BY monetary_value) AS VARCHAR) as rfm_score,
    
    -- Segmento de negocio
    CASE 
        WHEN NTILE(5) OVER (ORDER BY recency_days DESC) >= 4 AND 
             NTILE(5) OVER (ORDER BY frequency) >= 4 AND 
             NTILE(5) OVER (ORDER BY monetary_value) >= 4 THEN 'Champions'
        WHEN NTILE(5) OVER (ORDER BY recency_days DESC) >= 3 AND 
             NTILE(5) OVER (ORDER BY frequency) >= 3 THEN 'Loyal Customers'
        WHEN NTILE(5) OVER (ORDER BY monetary_value) >= 4 THEN 'Big Spenders'
        WHEN NTILE(5) OVER (ORDER BY recency_days DESC) >= 4 THEN 'Recent Customers'
        WHEN NTILE(5) OVER (ORDER BY recency_days DESC) <= 2 THEN 'At Risk'
        ELSE 'Regular'
    END as customer_segment,
    
    CURRENT_TIMESTAMP as processed_at
    
FROM customer_metrics
