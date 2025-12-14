{{
    config(
        materialized='table',
        schema='gold',
        tags=['gold', 'analytics', 'rfm', 'segmentation']
    )
}}

/*
    Capa Gold - Segmentación RFM de Clientes
    =========================================
    Asigna scores RFM (1-5) y segmentos de negocio a cada cliente.
    
    Metodología:
    1. Calcular quintiles para R, F, M
    2. Asignar scores (1=peor, 5=mejor)
       - Para Recency: menor es mejor (invertido)
       - Para Frequency y Monetary: mayor es mejor
    3. Crear RFM Score combinado
    4. Asignar segmentos de negocio basados en scores
*/

WITH rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value,
        
        -- Scores RFM (1-5)
        -- Recency: invertido (menor recency = mejor score)
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        
        -- Frequency: mayor es mejor
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        
        -- Monetary: mayor es mejor
        NTILE(5) OVER (ORDER BY monetary_value ASC) AS m_score,
        
        -- Métricas adicionales
        avg_transaction_value,
        total_items_purchased,
        customer_lifetime_days,
        first_purchase_date,
        last_purchase_date
        
    FROM {{ ref('gold_customer_rfm') }}
),

rfm_segments AS (
    SELECT
        *,
        
        -- RFM Score combinado (concatenación)
        CONCAT(r_score, f_score, m_score) AS rfm_score,
        
        -- RFM Score numérico (suma ponderada)
        (r_score * 100) + (f_score * 10) + m_score AS rfm_score_numeric,
        
        -- Segmentación de negocio
        CASE
            -- Champions: Mejores clientes (R=5, F=5, M=5)
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            
            -- Loyal Customers: Compran frecuentemente
            WHEN r_score >= 3 AND f_score >= 4 THEN 'Loyal Customers'
            
            -- Potential Loyalists: Clientes recientes con potencial
            WHEN r_score >= 4 AND f_score >= 2 AND f_score <= 3 THEN 'Potential Loyalists'
            
            -- New Customers: Clientes muy recientes
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
            
            -- Promising: Compradores recientes con buen gasto
            WHEN r_score >= 3 AND f_score <= 2 AND m_score >= 3 THEN 'Promising'
            
            -- Need Attention: Clientes que necesitan atención
            WHEN r_score = 3 AND f_score = 3 THEN 'Need Attention'
            
            -- About to Sleep: En riesgo de inactividad
            WHEN r_score <= 2 AND f_score >= 2 AND f_score <= 3 THEN 'About to Sleep'
            
            -- At Risk: Clientes valiosos en riesgo
            WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
            
            -- Cannot Lose Them: Clientes de alto valor que se están perdiendo
            WHEN r_score <= 1 AND f_score >= 4 AND m_score >= 4 THEN 'Cannot Lose Them'
            
            -- Hibernating: Clientes inactivos
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating'
            
            -- Lost: Clientes perdidos
            WHEN r_score <= 1 AND f_score <= 2 THEN 'Lost'
            
            ELSE 'Other'
        END AS customer_segment,
        
        -- Prioridad de acción (1=alta, 5=baja)
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 1  -- Champions
            WHEN r_score <= 1 AND f_score >= 4 AND m_score >= 4 THEN 1  -- Cannot Lose
            WHEN r_score <= 2 AND f_score >= 4 THEN 2  -- At Risk
            WHEN r_score >= 4 AND f_score <= 2 THEN 3  -- New Customers
            WHEN r_score <= 2 AND f_score <= 2 THEN 4  -- Hibernating/Lost
            ELSE 3
        END AS action_priority
        
    FROM rfm_scores
)

SELECT
    customer_id,
    
    -- Métricas RFM
    recency_days,
    frequency,
    monetary_value,
    
    -- Scores RFM
    r_score,
    f_score,
    m_score,
    rfm_score,
    rfm_score_numeric,
    
    -- Segmentación
    customer_segment,
    action_priority,
    
    -- Métricas adicionales
    avg_transaction_value,
    total_items_purchased,
    customer_lifetime_days,
    first_purchase_date,
    last_purchase_date,
    
    -- Metadata
    CURRENT_TIMESTAMP AS segmented_at
    
FROM rfm_segments

ORDER BY rfm_score_numeric DESC
