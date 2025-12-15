{{
    config(
        materialized='table',
        schema='gold'
    )
}}

/*
    Customer Lifetime Value - Valor de vida del cliente
    
    Objetivo: Estimar CLV para priorizar clientes de alto valor
*/

SELECT 
    customer_id,
    country,
    customer_segment,
    
    -- Métricas históricas
    monetary_value as total_revenue,
    frequency as total_orders,
    monetary_value / NULLIF(frequency, 0) as avg_order_value,
    
    -- Tiempo de vida
    customer_lifetime_days,
    
    -- CLV estimado (simple: proyección anual basada en histórico)
    CASE 
        WHEN customer_lifetime_days > 0 THEN
            (monetary_value / NULLIF(frequency, 0)) * 
            (365.0 / NULLIF(customer_lifetime_days, 0)) * 
            frequency
        ELSE 0
    END as estimated_annual_value,
    
    -- Proyección 3 años (CLV simplificado)
    CASE 
        WHEN customer_lifetime_days > 0 THEN
            (monetary_value / NULLIF(frequency, 0)) * 
            (365.0 / NULLIF(customer_lifetime_days, 0)) * 
            frequency * 3
        ELSE 0
    END as clv_3year,
    
    -- Clasificación de valor
    CASE 
        WHEN customer_segment = 'Champions' THEN 'High Value'
        WHEN customer_segment IN ('Loyal Customers', 'Big Spenders') THEN 'Medium Value'
        WHEN customer_segment = 'At Risk' THEN 'At Risk Value'
        ELSE 'Low Value'
    END as value_tier,
    
    CURRENT_TIMESTAMP as processed_at
    
FROM {{ ref('customer_rfm') }}
ORDER BY clv_3year DESC
