# 🎯 Enterprise Analytics Strategy - Medallion Architecture

> **Proyecto:** Retail Analytics - BI Supermarket Data  
> **Rol:** Insights Lead - Tier One  
> **Objetivo:** Arquitectura de datos orientada a decisiones ejecutivas  
> **Fecha:** 2025-12-14

---

## 📊 Executive Summary

Basado en el análisis exhaustivo de 541,909 transacciones (Dic 2010 - Sep 2011), hemos identificado **4 pilares estratégicos de análisis** que requieren una arquitectura Medallion rediseñada para maximizar el valor de negocio.

### 🎯 Los 4 Pilares de Análisis

1. **💰 Financial Performance** - P&L, Revenue, Profitability
2. **👥 Customer Analytics** - Segmentation, Lifetime Value, Behavior
3. **⚙️ Operational Excellence** - Inventory Loss Control, Quality Management
4. **📦 Product Intelligence** - Performance, Pricing, Portfolio Optimization

---

## 🏗️ Arquitectura Medallion Rediseñada

### 🥉 Bronze Layer (Raw Data Lake)
**Objetivo:** Almacenamiento inmutable de datos crudos

```
bronze/
└── raw_data (541,909 registros)
    ├── Ventas: 531,285 (98.04%)
    ├── Devoluciones: 9,288 (1.71%)
    ├── Ajustes Inventario: 1,336 (0.25%)
    └── Ajustes Contables: 2,866 (0.53%)
```

**Sin cambios** - Mantener datos crudos tal cual

---

### 🥈 Silver Layer (Curated Data Assets)
**Objetivo:** Datos limpios, normalizados y clasificados por dominio

```
silver/
├── foundation/                    # Tablas de referencia
│   ├── dim_products              # Product Master
│   ├── dim_customers             # Customer Master
│   └── dim_calendar              # Calendario de negocio
│
├── transactions/                  # Transacciones por tipo
│   ├── fact_sales                # Ventas (SALE)
│   ├── fact_returns              # Devoluciones (RETURN)
│   ├── fact_inventory_losses     # Mermas (INVENTORY_ADJUSTMENT)
│   └── fact_accounting_adjustments # Ajustes contables (M, D, POST, etc.)
│
└── aggregations/                  # Pre-agregaciones para performance
    ├── sales_daily               # Ventas diarias
    ├── sales_weekly              # Ventas semanales
    └── sales_monthly             # Ventas mensuales
```

---

### 🥇 Gold Layer (Business Intelligence Marts)
**Objetivo:** Modelos analíticos orientados a decisiones ejecutivas

```
gold/
├── 1_financial_performance/
│   ├── revenue_analysis          # Análisis de ingresos
│   ├── profitability_analysis    # Análisis de rentabilidad
│   ├── loss_impact_analysis      # Impacto de pérdidas (con costos imputados)
│   └── financial_kpis            # KPIs financieros consolidados
│
├── 2_customer_analytics/
│   ├── customer_rfm              # Segmentación RFM
│   ├── customer_lifetime_value   # CLV
│   ├── customer_cohorts          # Análisis de cohortes
│   ├── customer_churn            # Predicción de churn
│   └── customer_kpis             # KPIs de clientes
│
├── 3_operational_excellence/
│   ├── inventory_loss_control    # Control de mermas (Six Sigma)
│   ├── loss_anomaly_detection    # Detección de cisnes negros
│   ├── operational_efficiency    # Eficiencia operacional
│   └── operational_kpis          # KPIs operacionales
│
└── 4_product_intelligence/
    ├── product_performance       # Performance por producto
    ├── product_pricing_analysis  # Análisis de precios
    ├── product_portfolio         # Optimización de portfolio
    ├── product_affinity          # Market basket analysis
    └── product_kpis              # KPIs de productos
```

---

## 📋 Detalle de Cada Pilar Analítico

### 1️⃣ Financial Performance (P&L Analysis)

#### Objetivos de Negocio
- Entender **revenue real** vs **revenue reportado**
- Cuantificar **impacto de pérdidas** no registradas
- Optimizar **márgenes de ganancia**
- Identificar **oportunidades de crecimiento**

#### Modelos Gold

##### `revenue_analysis`
```sql
-- Análisis de ingresos con ajustes
SELECT 
    year_month,
    country,
    
    -- Revenue Bruto
    SUM(CASE WHEN transaction_type = 'SALE' THEN total_sale ELSE 0 END) as gross_revenue,
    
    -- Devoluciones
    SUM(CASE WHEN transaction_type = 'RETURN' THEN total_sale ELSE 0 END) as returns,
    
    -- Revenue Neto
    SUM(total_sale) as net_revenue,
    
    -- Número de transacciones
    COUNT(DISTINCT invoice_no) as num_transactions,
    
    -- Ticket promedio
    AVG(total_sale) as avg_transaction_value
FROM silver.fact_sales
GROUP BY year_month, country;
```

##### `loss_impact_analysis`
```sql
-- Impacto financiero de pérdidas (con costos imputados)
SELECT 
    year_month,
    loss_category,
    
    -- Unidades perdidas
    SUM(ABS(quantity)) as units_lost,
    
    -- Costo registrado (siempre 0)
    SUM(quantity * recorded_price) as recorded_loss,
    
    -- Costo REAL estimado
    SUM(quantity * imputed_price) as real_loss,
    
    -- Pérdida NO reportada
    SUM(quantity * imputed_price) - SUM(quantity * recorded_price) as unreported_loss
FROM silver.fact_inventory_losses
GROUP BY year_month, loss_category;
```

##### `financial_kpis`
```sql
-- KPIs financieros consolidados
SELECT 
    year_month,
    
    -- Revenue
    SUM(net_revenue) as total_revenue,
    
    -- Costos (pérdidas reales)
    SUM(real_loss) as total_costs,
    
    -- Profit ajustado
    SUM(net_revenue) + SUM(real_loss) as adjusted_profit,
    
    -- Margen
    (SUM(net_revenue) + SUM(real_loss)) / NULLIF(SUM(net_revenue), 0) * 100 as profit_margin_pct,
    
    -- Return rate
    SUM(returns) / NULLIF(SUM(gross_revenue), 0) * 100 as return_rate_pct
FROM gold.revenue_analysis r
LEFT JOIN gold.loss_impact_analysis l USING (year_month);
```

#### Dashboards Ejecutivos
- 📊 **P&L Dashboard** - Profit & Loss statement
- 💰 **Revenue Waterfall** - Gross → Net → Adjusted
- 📉 **Loss Impact** - Costos ocultos de mermas

---

### 2️⃣ Customer Analytics (Customer Intelligence)

#### Objetivos de Negocio
- **Segmentar clientes** por valor y comportamiento
- Identificar **clientes de alto valor** (VIP)
- Predecir **churn** y retención
- Optimizar **estrategias de marketing**

#### Modelos Gold

##### `customer_rfm`
```sql
-- Segmentación RFM mejorada
WITH customer_metrics AS (
    SELECT 
        customer_id,
        country,
        
        -- Recency (días desde última compra)
        DATEDIFF('day', MAX(invoice_date), CURRENT_DATE) as recency,
        
        -- Frequency (número de compras)
        COUNT(DISTINCT invoice_no) as frequency,
        
        -- Monetary (valor total)
        SUM(total_sale) as monetary,
        
        -- Métricas adicionales
        AVG(total_sale) as avg_order_value,
        MIN(invoice_date) as first_purchase,
        MAX(invoice_date) as last_purchase
    FROM silver.fact_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id, country
)
SELECT 
    *,
    -- Scores RFM (1-5)
    NTILE(5) OVER (ORDER BY recency DESC) as r_score,
    NTILE(5) OVER (ORDER BY frequency) as f_score,
    NTILE(5) OVER (ORDER BY monetary) as m_score,
    
    -- RFM Score combinado
    CAST(NTILE(5) OVER (ORDER BY recency DESC) AS VARCHAR) ||
    CAST(NTILE(5) OVER (ORDER BY frequency) AS VARCHAR) ||
    CAST(NTILE(5) OVER (ORDER BY monetary) AS VARCHAR) as rfm_score,
    
    -- Segmento de negocio
    CASE 
        WHEN NTILE(5) OVER (ORDER BY recency DESC) >= 4 AND 
             NTILE(5) OVER (ORDER BY frequency) >= 4 AND 
             NTILE(5) OVER (ORDER BY monetary) >= 4 THEN 'Champions'
        WHEN NTILE(5) OVER (ORDER BY recency DESC) >= 3 AND 
             NTILE(5) OVER (ORDER BY frequency) >= 3 THEN 'Loyal Customers'
        WHEN NTILE(5) OVER (ORDER BY monetary) >= 4 THEN 'Big Spenders'
        WHEN NTILE(5) OVER (ORDER BY recency DESC) >= 4 THEN 'Recent Customers'
        WHEN NTILE(5) OVER (ORDER BY recency DESC) <= 2 THEN 'At Risk'
        ELSE 'Regular'
    END as customer_segment
FROM customer_metrics;
```

##### `customer_lifetime_value`
```sql
-- Customer Lifetime Value (CLV)
SELECT 
    customer_id,
    customer_segment,
    
    -- Métricas históricas
    monetary as total_revenue,
    frequency as total_orders,
    monetary / NULLIF(frequency, 0) as avg_order_value,
    
    -- Tiempo de vida
    DATEDIFF('day', first_purchase, last_purchase) as customer_lifetime_days,
    
    -- CLV estimado (simple)
    (monetary / NULLIF(frequency, 0)) * 
    (365.0 / NULLIF(DATEDIFF('day', first_purchase, last_purchase), 0)) * 
    frequency as estimated_annual_value,
    
    -- Proyección 3 años
    estimated_annual_value * 3 as clv_3year
FROM gold.customer_rfm;
```

##### `customer_cohorts`
```sql
-- Análisis de cohortes (por mes de primera compra)
WITH cohorts AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date)) as cohort_month,
        DATE_TRUNC('month', invoice_date) as purchase_month,
        SUM(total_sale) as revenue
    FROM silver.fact_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id, cohort_month, purchase_month
)
SELECT 
    cohort_month,
    purchase_month,
    DATEDIFF('month', cohort_month, purchase_month) as months_since_first,
    
    -- Métricas de cohorte
    COUNT(DISTINCT customer_id) as active_customers,
    SUM(revenue) as cohort_revenue,
    AVG(revenue) as avg_revenue_per_customer,
    
    -- Retención
    COUNT(DISTINCT customer_id) * 100.0 / 
        FIRST_VALUE(COUNT(DISTINCT customer_id)) OVER (
            PARTITION BY cohort_month 
            ORDER BY purchase_month
        ) as retention_rate
FROM cohorts
GROUP BY cohort_month, purchase_month;
```

#### Dashboards Ejecutivos
- 👥 **Customer Segmentation** - Distribución RFM
- 💎 **VIP Customers** - Top 20% por valor
- 📈 **Cohort Analysis** - Retención por cohorte
- ⚠️ **Churn Risk** - Clientes en riesgo

---

### 3️⃣ Operational Excellence (Quality & Efficiency)

#### Objetivos de Negocio
- **Reducir mermas** de inventario
- **Detectar anomalías** operacionales (cisnes negros)
- **Optimizar procesos** de control de calidad
- **Prevenir pérdidas** futuras

#### Modelos Gold

##### `inventory_loss_control`
```sql
-- Control estadístico de mermas (Six Sigma)
WITH weekly_losses AS (
    SELECT 
        EXTRACT(YEAR FROM invoice_date) || '-W' || 
        LPAD(CAST(EXTRACT(WEEK FROM invoice_date) AS VARCHAR), 2, '0') as year_week,
        DATE_TRUNC('week', invoice_date) as week_start,
        loss_category,
        
        SUM(ABS(quantity)) as units_lost,
        SUM(ABS(estimated_loss)) as financial_loss,
        COUNT(*) as num_incidents
    FROM silver.fact_inventory_losses
    GROUP BY year_week, week_start, loss_category
)
SELECT 
    *,
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
    END as control_status
FROM weekly_losses;
```

##### `loss_anomaly_detection`
```sql
-- Detección de cisnes negros y análisis de causas
SELECT 
    year_week,
    week_start,
    control_status,
    z_score,
    units_lost,
    financial_loss,
    
    -- Top productos afectados
    (SELECT STRING_AGG(stock_code || ': ' || ABS(quantity), ', ')
     FROM (
         SELECT stock_code, quantity
         FROM silver.fact_inventory_losses
         WHERE DATE_TRUNC('week', invoice_date) = ilc.week_start
         ORDER BY ABS(quantity) DESC
         LIMIT 5
     )) as top_affected_products,
    
    -- Categoría predominante
    loss_category
FROM gold.inventory_loss_control ilc
WHERE control_status IN ('3σ - Out of Control', '6σ - Black Swan')
ORDER BY z_score DESC;
```

##### `operational_kpis`
```sql
-- KPIs operacionales
SELECT 
    year_month,
    
    -- Mermas
    SUM(units_lost) as total_units_lost,
    SUM(financial_loss) as total_financial_loss,
    
    -- Tasa de merma (% del inventario movido)
    SUM(units_lost) * 100.0 / 
        (SELECT SUM(ABS(quantity)) FROM silver.fact_sales WHERE year_month = l.year_month) as loss_rate_pct,
    
    -- Semanas fuera de control
    COUNT(CASE WHEN control_status LIKE '%Out of Control%' THEN 1 END) as weeks_out_of_control,
    
    -- Cisnes negros
    COUNT(CASE WHEN control_status LIKE '%Black Swan%' THEN 1 END) as black_swan_events
FROM gold.inventory_loss_control l
GROUP BY year_month;
```

#### Dashboards Ejecutivos
- 📉 **Loss Control Chart** - Gráfico de control Six Sigma
- 🦢 **Anomaly Alerts** - Cisnes negros detectados
- 📊 **Loss Breakdown** - Por categoría y producto
- 🎯 **Operational Efficiency** - KPIs de calidad

---

### 4️⃣ Product Intelligence (Portfolio Optimization)

#### Objetivos de Negocio
- Identificar **productos estrella** y **productos zombies**
- Optimizar **estrategia de precios**
- Analizar **afinidad de productos** (market basket)
- **Optimizar portfolio** de productos

#### Modelos Gold

##### `product_performance`
```sql
-- Performance por producto
SELECT 
    p.stock_code,
    p.canonical_description,
    
    -- Métricas de ventas
    COUNT(DISTINCT s.invoice_no) as num_transactions,
    SUM(s.quantity) as total_units_sold,
    SUM(s.total_sale) as total_revenue,
    AVG(s.unit_price) as avg_price,
    
    -- Métricas de devoluciones
    (SELECT COUNT(*) FROM silver.fact_returns r 
     WHERE r.stock_code = p.stock_code) as num_returns,
    (SELECT SUM(ABS(quantity)) FROM silver.fact_returns r 
     WHERE r.stock_code = p.stock_code) as units_returned,
    
    -- Tasa de devolución
    units_returned * 100.0 / NULLIF(total_units_sold, 0) as return_rate_pct,
    
    -- Métricas de pérdidas
    (SELECT SUM(ABS(quantity)) FROM silver.fact_inventory_losses l 
     WHERE l.stock_code = p.stock_code) as units_lost,
    (SELECT SUM(ABS(estimated_loss)) FROM silver.fact_inventory_losses l 
     WHERE l.stock_code = p.stock_code) as loss_amount,
    
    -- Clasificación ABC
    NTILE(3) OVER (ORDER BY total_revenue DESC) as abc_class,
    
    -- Clasificación de producto
    CASE 
        WHEN total_revenue > PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY total_revenue) OVER () 
             AND return_rate_pct < 5 THEN 'Star Product'
        WHEN total_revenue < PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY total_revenue) OVER () 
             AND return_rate_pct > 10 THEN 'Zombie Product'
        WHEN return_rate_pct > 15 THEN 'Problem Product'
        ELSE 'Regular Product'
    END as product_classification
FROM silver.dim_products p
LEFT JOIN silver.fact_sales s ON p.stock_code = s.stock_code
GROUP BY p.stock_code, p.canonical_description;
```

##### `product_pricing_analysis`
```sql
-- Análisis de elasticidad de precios
WITH price_variations AS (
    SELECT 
        stock_code,
        country,
        AVG(unit_price) as avg_price,
        STDDEV(unit_price) as price_stddev,
        MIN(unit_price) as min_price,
        MAX(unit_price) as max_price,
        COUNT(DISTINCT unit_price) as num_price_points,
        SUM(quantity) as total_quantity
    FROM silver.fact_sales
    GROUP BY stock_code, country
)
SELECT 
    stock_code,
    country,
    avg_price,
    
    -- Variación de precio
    (max_price - min_price) / NULLIF(min_price, 0) * 100 as price_variation_pct,
    
    -- Elasticidad estimada (simplificada)
    -- % cambio en cantidad / % cambio en precio
    CASE 
        WHEN price_variation_pct > 50 THEN 'High Price Sensitivity'
        WHEN price_variation_pct > 20 THEN 'Medium Price Sensitivity'
        ELSE 'Low Price Sensitivity'
    END as price_elasticity
FROM price_variations
WHERE num_price_points > 1;
```

##### `product_affinity`
```sql
-- Market Basket Analysis (productos comprados juntos)
WITH product_pairs AS (
    SELECT 
        a.stock_code as product_a,
        b.stock_code as product_b,
        COUNT(DISTINCT a.invoice_no) as times_bought_together
    FROM silver.fact_sales a
    JOIN silver.fact_sales b 
        ON a.invoice_no = b.invoice_no 
        AND a.stock_code < b.stock_code
    GROUP BY a.stock_code, b.stock_code
)
SELECT 
    product_a,
    product_b,
    times_bought_together,
    
    -- Support (% de transacciones con ambos productos)
    times_bought_together * 100.0 / 
        (SELECT COUNT(DISTINCT invoice_no) FROM silver.fact_sales) as support_pct,
    
    -- Confidence (si compran A, probabilidad de comprar B)
    times_bought_together * 100.0 / 
        (SELECT COUNT(DISTINCT invoice_no) FROM silver.fact_sales WHERE stock_code = product_a) as confidence_pct
FROM product_pairs
WHERE times_bought_together >= 10
ORDER BY times_bought_together DESC;
```

#### Dashboards Ejecutivos
- ⭐ **Product Portfolio Matrix** - Stars vs Zombies
- 💰 **Pricing Optimization** - Elasticidad por producto
- 🛒 **Market Basket** - Productos complementarios
- 📊 **ABC Analysis** - Clasificación de productos

---

## 🎯 Roadmap de Implementación

### Fase 1: Foundation (Semana 1-2)
- [ ] Implementar Silver Foundation
  - [ ] `dim_products` (Product Master)
  - [ ] `dim_customers` (Customer Master)
  - [ ] `dim_calendar` (Calendario)
- [ ] Implementar Silver Transactions
  - [ ] `fact_sales`
  - [ ] `fact_returns`
  - [ ] `fact_inventory_losses`
  - [ ] `fact_accounting_adjustments`

### Fase 2: Pilar 1 - Financial Performance (Semana 3)
- [ ] `revenue_analysis`
- [ ] `loss_impact_analysis`
- [ ] `financial_kpis`
- [ ] Dashboard P&L

### Fase 3: Pilar 2 - Customer Analytics (Semana 4)
- [ ] `customer_rfm`
- [ ] `customer_lifetime_value`
- [ ] `customer_cohorts`
- [ ] Dashboard Customer Segmentation

### Fase 4: Pilar 3 - Operational Excellence (Semana 5)
- [ ] `inventory_loss_control`
- [ ] `loss_anomaly_detection`
- [ ] `operational_kpis`
- [ ] Dashboard Loss Control (Six Sigma)

### Fase 5: Pilar 4 - Product Intelligence (Semana 6)
- [ ] `product_performance`
- [ ] `product_pricing_analysis`
- [ ] `product_affinity`
- [ ] Dashboard Product Portfolio

### Fase 6: Integration & Presentation (Semana 7-8)
- [ ] Executive Dashboard (consolidado)
- [ ] Automated reporting
- [ ] Presentación a ejecutivos
- [ ] Documentación final

---

## 📈 Valor de Negocio Esperado

### Impacto Financiero
- 💰 **Visibilidad de costos ocultos:** £XX,XXX+ en pérdidas no reportadas
- 📊 **Optimización de márgenes:** 2-5% mejora estimada
- 🎯 **Reducción de mermas:** 10-15% mediante control Six Sigma

### Impacto en Clientes
- 👥 **Segmentación efectiva:** Identificar top 20% de clientes (80% revenue)
- 💎 **Retención VIP:** Programas personalizados para Champions
- ⚠️ **Prevención de churn:** Identificar clientes en riesgo

### Impacto Operacional
- 📉 **Control de calidad:** Detección automática de anomalías
- 🦢 **Gestión de crisis:** Alertas de cisnes negros
- ⚙️ **Eficiencia:** Reducción de tiempo de análisis en 70%

### Impacto en Productos
- ⭐ **Portfolio optimizado:** Eliminar productos zombies
- 💰 **Pricing inteligente:** Ajustes basados en elasticidad
- 🛒 **Cross-selling:** Oportunidades de venta cruzada

---

## 🎤 Presentación Ejecutiva

### Slide Deck Recomendado

1. **Executive Summary** (1 slide)
   - 4 pilares de análisis
   - Valor de negocio esperado

2. **Current State Analysis** (2 slides)
   - Problemas identificados en Bronze
   - Costos ocultos (£XX,XXX+ no reportados)

3. **Proposed Architecture** (2 slides)
   - Medallion rediseñado
   - 4 pilares analíticos

4. **Financial Performance** (3 slides)
   - P&L ajustado
   - Impacto de pérdidas
   - Oportunidades de mejora

5. **Customer Analytics** (3 slides)
   - Segmentación RFM
   - CLV y retención
   - Estrategias de marketing

6. **Operational Excellence** (3 slides)
   - Control de mermas Six Sigma
   - Cisnes negros detectados
   - Plan de reducción de pérdidas

7. **Product Intelligence** (3 slides)
   - Portfolio optimization
   - Pricing strategy
   - Cross-selling opportunities

8. **Implementation Roadmap** (1 slide)
   - 8 semanas
   - Quick wins vs long-term value

9. **Investment & ROI** (1 slide)
   - Recursos necesarios
   - ROI esperado

10. **Next Steps** (1 slide)
    - Aprobación
    - Kick-off

---

**Preparado por:** Insights Lead - Tier One  
**Fecha:** 2025-12-14  
**Estado:** 🟢 Listo para presentación ejecutiva
