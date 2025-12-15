{{
    config(
        materialized='table',
        schema='gold'
    )
}}

/*
    Loss Impact Analysis - Análisis del impacto financiero de mermas
    
    Objetivo: Cuantificar pérdidas NO reportadas
    Crítico: Muestra el costo real de inventario perdido (UnitPrice=0 en Bronze)
*/

SELECT 
    -- Dimensiones temporales
    year,
    month,
    year_month,
    year_week,
    
    -- Categoría de pérdida
    loss_category,
    
    -- Métricas de pérdida
    COUNT(*) as num_loss_incidents,
    COUNT(DISTINCT invoice_no) as num_loss_invoices,
    COUNT(DISTINCT stock_code) as unique_products_lost,
    
    -- Unidades perdidas
    SUM(ABS(quantity)) as total_units_lost,
    
    -- Impacto financiero
    SUM(quantity * recorded_price) as recorded_loss,  -- Siempre 0
    SUM(quantity * imputed_price) as real_loss,       -- Costo real estimado
    SUM(quantity * imputed_price) - SUM(quantity * recorded_price) as unreported_loss,
    
    -- Promedio por incidente
    AVG(ABS(quantity)) as avg_units_per_incident,
    AVG(ABS(quantity * imputed_price)) as avg_loss_per_incident,
    
    -- Metadatos
    CURRENT_TIMESTAMP as processed_at
    
FROM {{ ref('fact_inventory_losses') }}
GROUP BY year, month, year_month, year_week, loss_category
ORDER BY year, month, loss_category
