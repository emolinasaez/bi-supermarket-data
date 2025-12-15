{{
    config(
        materialized='table',
        schema='gold'
    )
}}

/*
    Financial KPIs - KPIs financieros consolidados
    
    Objetivo: Dashboard ejecutivo con métricas clave
    Incluye: Revenue, costos, profit ajustado, márgenes
*/

WITH revenue_summary AS (
    SELECT 
        year_month,
        SUM(gross_revenue) as total_gross_revenue,
        SUM(returns) as total_returns,
        SUM(net_revenue) as total_net_revenue,
        SUM(num_sales_invoices) as total_sales_invoices,
        SUM(num_return_invoices) as total_return_invoices,
        SUM(unique_customers) as total_customers,
        AVG(return_rate_pct) as avg_return_rate_pct
    FROM {{ ref('revenue_analysis') }}
    GROUP BY year_month
),

loss_summary AS (
    SELECT 
        year_month,
        SUM(total_units_lost) as total_units_lost,
        SUM(recorded_loss) as total_recorded_loss,
        SUM(real_loss) as total_real_loss,
        SUM(unreported_loss) as total_unreported_loss,
        COUNT(DISTINCT loss_category) as num_loss_categories
    FROM {{ ref('loss_impact_analysis') }}
    GROUP BY year_month
)

SELECT 
    r.year_month,
    
    -- Revenue metrics
    r.total_gross_revenue,
    r.total_returns,
    r.total_net_revenue,
    
    -- Loss metrics
    COALESCE(l.total_units_lost, 0) as total_units_lost,
    COALESCE(l.total_real_loss, 0) as total_real_loss,
    COALESCE(l.total_unreported_loss, 0) as total_unreported_loss,
    
    -- Adjusted profit (revenue - real losses)
    r.total_net_revenue + COALESCE(l.total_real_loss, 0) as adjusted_profit,
    
    -- Margins
    (r.total_net_revenue + COALESCE(l.total_real_loss, 0)) * 100.0 / 
        NULLIF(r.total_net_revenue, 0) as adjusted_profit_margin_pct,
    
    -- Return rate
    r.avg_return_rate_pct,
    
    -- Loss rate (% of revenue)
    ABS(COALESCE(l.total_real_loss, 0)) * 100.0 / 
        NULLIF(r.total_gross_revenue, 0) as loss_rate_pct,
    
    -- Customer metrics
    r.total_customers,
    r.total_net_revenue / NULLIF(r.total_customers, 0) as revenue_per_customer,
    
    -- Invoice metrics
    r.total_sales_invoices,
    r.total_return_invoices,
    r.total_net_revenue / NULLIF(r.total_sales_invoices, 0) as avg_invoice_value,
    
    -- Metadatos
    CURRENT_TIMESTAMP as processed_at
    
FROM revenue_summary r
LEFT JOIN loss_summary l ON r.year_month = l.year_month
ORDER BY r.year_month
