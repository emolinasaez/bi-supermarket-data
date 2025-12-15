{{
    config(
        materialized='table',
        schema='silver'
    )
}}

/*
    Calendar Dimension - Tabla de calendario de negocio
    
    Objetivo: Facilitar análisis temporal
    Rango: Basado en datos reales (Dic 2010 - Sep 2011)
*/

WITH date_range AS (
    SELECT 
        MIN(STRPTIME("InvoiceDate", '%m/%d/%Y %H:%M'))::DATE as min_date,
        MAX(STRPTIME("InvoiceDate", '%m/%d/%Y %H:%M'))::DATE as max_date
    FROM {{ source('bronze', 'raw_data') }}
),

date_spine AS (
    SELECT 
        UNNEST(generate_series(
            (SELECT min_date FROM date_range),
            (SELECT max_date FROM date_range),
            INTERVAL '1 day'
        ))::DATE as calendar_date
)

SELECT 
    calendar_date,
    EXTRACT(YEAR FROM calendar_date) as year,
    EXTRACT(MONTH FROM calendar_date) as month,
    EXTRACT(DAY FROM calendar_date) as day,
    EXTRACT(QUARTER FROM calendar_date) as quarter,
    EXTRACT(WEEK FROM calendar_date) as week_of_year,
    EXTRACT(DOW FROM calendar_date) as day_of_week,
    EXTRACT(DOY FROM calendar_date) as day_of_year,
    STRFTIME(calendar_date, '%B') as month_name,
    STRFTIME(calendar_date, '%A') as day_name,
    CASE WHEN EXTRACT(DOW FROM calendar_date) IN (0, 6) THEN TRUE ELSE FALSE END as is_weekend,
    EXTRACT(YEAR FROM calendar_date) || '-' || LPAD(CAST(EXTRACT(MONTH FROM calendar_date) AS VARCHAR), 2, '0') as year_month,
    EXTRACT(YEAR FROM calendar_date) || '-W' || LPAD(CAST(EXTRACT(WEEK FROM calendar_date) AS VARCHAR), 2, '0') as year_week,
    CURRENT_TIMESTAMP as processed_at
FROM date_spine
ORDER BY calendar_date
