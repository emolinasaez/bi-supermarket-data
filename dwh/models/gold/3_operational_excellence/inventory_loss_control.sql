{{
    config(
        materialized='table',
        schema='gold'
    )
}}

/*
    Inventory Loss Control - Control Six Sigma de mermas
    
    Objetivo: Monitoreo estadístico de pérdidas semanales
    Incluye: Límites de control, z-scores, clasificación sigma
*/

WITH weekly_losses AS (
    SELECT 
        year_week,
        MIN(invoice_date) as week_start,
        loss_category,
        SUM(ABS(quantity)) as units_lost,
        SUM(ABS(estimated_loss)) as financial_loss,
        COUNT(*) as num_incidents
    FROM {{ ref('fact_inventory_losses') }}
    GROUP BY year_week, loss_category
)

SELECT 
    year_week,
    week_start,
    loss_category,
    units_lost,
    financial_loss,
    num_incidents,
    
    -- Estadísticas de control
    AVG(units_lost) OVER () as mean_weekly_loss,
    STDDEV(units_lost) OVER () as stddev_weekly_loss,
    
    -- Z-score
    (units_lost - AVG(units_lost) OVER ()) / 
        NULLIF(STDDEV(units_lost) OVER (), 0) as z_score,
    
    -- Límites de control (3σ)
    AVG(units_lost) OVER () + 3 * STDDEV(units_lost) OVER () as ucl_3sigma,
    AVG(units_lost) OVER () - 3 * STDDEV(units_lost) OVER () as lcl_3sigma,
    
    -- Clasificación sigma
    CASE 
        WHEN ABS((units_lost - AVG(units_lost) OVER ()) / 
                 NULLIF(STDDEV(units_lost) OVER (), 0)) >= 6 THEN '6σ - Black Swan'
        WHEN ABS((units_lost - AVG(units_lost) OVER ()) / 
                 NULLIF(STDDEV(units_lost) OVER (), 0)) >= 3 THEN '3σ - Out of Control'
        WHEN ABS((units_lost - AVG(units_lost) OVER ()) / 
                 NULLIF(STDDEV(units_lost) OVER (), 0)) >= 2 THEN '2σ - Warning'
        ELSE 'Normal'
    END as control_status,
    
    CURRENT_TIMESTAMP as processed_at
    
FROM weekly_losses
ORDER BY year_week, loss_category
