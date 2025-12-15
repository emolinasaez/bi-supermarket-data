{{
    config(
        materialized='table',
        schema='gold'
    )
}}

/*
    Product Performance - Análisis de performance por producto
    
    Objetivo: Identificar Stars, Zombies, y Problem Products
    Clasificación ABC por revenue
*/

WITH product_sales AS (
    SELECT 
        p.stock_code,
        p.canonical_description,
        COUNT(DISTINCT s.invoice_no) as num_transactions,
        SUM(s.quantity) as total_units_sold,
        SUM(s.total_sale) as total_revenue,
        AVG(s.unit_price) as avg_price
    FROM {{ ref('dim_products') }} p
    LEFT JOIN {{ ref('fact_sales') }} s ON p.stock_code = s.stock_code
    WHERE s.transaction_type = 'SALE'
    GROUP BY p.stock_code, p.canonical_description
),

product_returns AS (
    SELECT 
        stock_code,
        COUNT(*) as num_returns,
        SUM(ABS(quantity)) as units_returned
    FROM {{ ref('fact_sales') }}
    WHERE transaction_type = 'RETURN'
    GROUP BY stock_code
),

product_losses AS (
    SELECT 
        stock_code,
        SUM(ABS(quantity)) as units_lost,
        SUM(ABS(estimated_loss)) as loss_amount
    FROM {{ ref('fact_inventory_losses') }}
    GROUP BY stock_code
)

SELECT 
    ps.stock_code,
    ps.canonical_description,
    ps.num_transactions,
    ps.total_units_sold,
    ps.total_revenue,
    ps.avg_price,
    
    -- Returns
    COALESCE(pr.num_returns, 0) as num_returns,
    COALESCE(pr.units_returned, 0) as units_returned,
    COALESCE(pr.units_returned, 0) * 100.0 / NULLIF(ps.total_units_sold, 0) as return_rate_pct,
    
    -- Losses
    COALESCE(pl.units_lost, 0) as units_lost,
    COALESCE(pl.loss_amount, 0) as loss_amount,
    
    -- Clasificación ABC
    NTILE(3) OVER (ORDER BY ps.total_revenue DESC) as abc_class,
    
    -- Clasificación de producto
    CASE 
        WHEN ps.total_revenue > (SELECT PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY total_revenue) FROM product_sales)
             AND COALESCE(pr.units_returned, 0) * 100.0 / NULLIF(ps.total_units_sold, 0) < 5 THEN 'Star Product'
        WHEN ps.total_revenue < (SELECT PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY total_revenue) FROM product_sales)
             AND COALESCE(pr.units_returned, 0) * 100.0 / NULLIF(ps.total_units_sold, 0) > 10 THEN 'Zombie Product'
        WHEN COALESCE(pr.units_returned, 0) * 100.0 / NULLIF(ps.total_units_sold, 0) > 15 THEN 'Problem Product'
        ELSE 'Regular Product'
    END as product_classification,
    
    CURRENT_TIMESTAMP as processed_at
    
FROM product_sales ps
LEFT JOIN product_returns pr ON ps.stock_code = pr.stock_code
LEFT JOIN product_losses pl ON ps.stock_code = pl.stock_code
ORDER BY ps.total_revenue DESC
