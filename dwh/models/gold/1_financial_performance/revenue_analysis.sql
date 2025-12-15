{{
    config(
        materialized='table',
        schema='gold'
    )
}}

/*
    Revenue Analysis - Análisis de ingresos por período y país
    
    Objetivo: Entender revenue bruto vs neto
    Incluye: Ventas y devoluciones
*/

SELECT 
    -- Dimensiones temporales
    invoice_year,
    invoice_month,
    invoice_year || '-' || LPAD(CAST(invoice_month AS VARCHAR), 2, '0') as year_month,
    country,
    
    -- Métricas de ventas
    COUNT(DISTINCT CASE WHEN transaction_type = 'SALE' THEN invoice_no END) as num_sales_invoices,
    SUM(CASE WHEN transaction_type = 'SALE' THEN 1 ELSE 0 END) as num_sale_lines,
    SUM(CASE WHEN transaction_type = 'SALE' THEN total_sale ELSE 0 END) as gross_revenue,
    
    -- Métricas de devoluciones
    COUNT(DISTINCT CASE WHEN transaction_type = 'RETURN' THEN invoice_no END) as num_return_invoices,
    SUM(CASE WHEN transaction_type = 'RETURN' THEN 1 ELSE 0 END) as num_return_lines,
    SUM(CASE WHEN transaction_type = 'RETURN' THEN total_sale ELSE 0 END) as returns,
    
    -- Revenue neto
    SUM(total_sale) as net_revenue,
    
    -- Métricas adicionales
    COUNT(DISTINCT invoice_no) as total_invoices,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(quantity) as total_units_sold,
    
    -- Promedios
    AVG(CASE WHEN transaction_type = 'SALE' THEN total_sale END) as avg_sale_line_value,
    AVG(CASE WHEN transaction_type = 'SALE' THEN unit_price END) as avg_unit_price,
    
    -- Tasa de devolución
    ABS(SUM(CASE WHEN transaction_type = 'RETURN' THEN total_sale ELSE 0 END)) * 100.0 / 
        NULLIF(SUM(CASE WHEN transaction_type = 'SALE' THEN total_sale ELSE 0 END), 0) as return_rate_pct,
    
    -- Metadatos
    CURRENT_TIMESTAMP as processed_at
    
FROM {{ ref('fact_sales') }}
GROUP BY invoice_year, invoice_month, year_month, country
ORDER BY invoice_year, invoice_month, country
