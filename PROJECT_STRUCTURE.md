# 📁 Project Structure - Retail Analytics

> **Última actualización:** 2025-12-14  
> **Arquitectura:** Medallion (Bronze → Silver → Gold)  
> **Estrategia:** 4 Pilares Analíticos

---

## 🗂️ Estructura de Directorios

```
bi-supermarket-data/
├── data/                          # Datos crudos (gitignored)
├── dwh/                           # Data Warehouse (DuckDB + dbt)
│   ├── models/
│   │   ├── bronze/               # Capa Bronze (raw data)
│   │   │   └── bronze_raw_data.sql
│   │   ├── silver/               # Capa Silver (curated data)
│   │   │   ├── foundation/       # Tablas de referencia
│   │   │   │   ├── dim_products.sql
│   │   │   │   ├── dim_customers.sql
│   │   │   │   └── dim_calendar.sql
│   │   │   ├── transactions/     # Transacciones por tipo
│   │   │   │   ├── fact_sales.sql
│   │   │   │   ├── fact_returns.sql
│   │   │   │   ├── fact_inventory_losses.sql
│   │   │   │   └── fact_accounting_adjustments.sql
│   │   │   └── aggregations/     # Pre-agregaciones
│   │   │       ├── sales_daily.sql
│   │   │       ├── sales_weekly.sql
│   │   │       └── sales_monthly.sql
│   │   └── gold/                 # Capa Gold (business intelligence)
│   │       ├── 1_financial_performance/
│   │       │   ├── revenue_analysis.sql
│   │       │   ├── loss_impact_analysis.sql
│   │       │   └── financial_kpis.sql
│   │       ├── 2_customer_analytics/
│   │       │   ├── customer_rfm.sql
│   │       │   ├── customer_lifetime_value.sql
│   │       │   └── customer_cohorts.sql
│   │       ├── 3_operational_excellence/
│   │       │   ├── inventory_loss_control.sql
│   │       │   ├── loss_anomaly_detection.sql
│   │       │   └── operational_kpis.sql
│   │       └── 4_product_intelligence/
│   │           ├── product_performance.sql
│   │           ├── product_pricing_analysis.sql
│   │           └── product_affinity.sql
│   ├── dbt_project.yml
│   └── profiles.yml
├── src/                           # Scripts de análisis
│   ├── analysis/                 # Notebooks y análisis exploratorio
│   │   └── (Jupyter notebooks aquí)
│   └── utils/                    # Utilidades y helpers
│       └── (Scripts Python aquí)
├── notebooks/                     # Análisis EDA
│   └── data_quality_checks.ipynb
├── docs/                          # Documentación
│   ├── data_quality_findings.md
│   ├── data_cleaning_strategy.md
│   ├── enterprise_analytics_strategy.md
│   └── kaggle_setup.md
├── archive/                       # Archivos antiguos
│   └── old_models/
│       ├── silver/
│       └── gold/
├── requirements.txt
├── .env
├── .gitignore
└── README.md
```

---

## 🎯 Arquitectura Medallion - 4 Pilares

### 🥉 Bronze Layer
**Objetivo:** Almacenamiento inmutable de datos crudos

- `bronze_raw_data` - 541,909 registros sin transformar

### 🥈 Silver Layer
**Objetivo:** Datos limpios, normalizados y clasificados

#### Foundation (Dimensiones)
- `dim_products` - Product Master con descripciones normalizadas
- `dim_customers` - Customer Master
- `dim_calendar` - Calendario de negocio

#### Transactions (Hechos)
- `fact_sales` - Ventas (98.04%)
- `fact_returns` - Devoluciones (1.71%)
- `fact_inventory_losses` - Mermas con costos imputados (0.25%)
- `fact_accounting_adjustments` - Ajustes contables (0.53%)

#### Aggregations (Performance)
- `sales_daily` - Agregación diaria
- `sales_weekly` - Agregación semanal
- `sales_monthly` - Agregación mensual

### 🥇 Gold Layer
**Objetivo:** Modelos analíticos para decisiones ejecutivas

#### 1️⃣ Financial Performance
- P&L Analysis
- Revenue vs Profitability
- Loss Impact (costos ocultos)

#### 2️⃣ Customer Analytics
- RFM Segmentation
- Customer Lifetime Value
- Cohort Analysis
- Churn Prediction

#### 3️⃣ Operational Excellence
- Inventory Loss Control (Six Sigma)
- Anomaly Detection (Cisnes Negros)
- Quality KPIs

#### 4️⃣ Product Intelligence
- Product Performance
- Pricing Optimization
- Market Basket Analysis
- Portfolio Optimization

---

## 📊 Flujo de Datos

```
Kaggle API
    ↓
data/OnlineRetail.csv (raw)
    ↓
ingestion_polars.py
    ↓
Bronze: raw_data (DuckDB)
    ↓
dbt run --models silver.*
    ↓
Silver: foundation + transactions + aggregations
    ↓
dbt run --models gold.*
    ↓
Gold: 4 pilares analíticos
    ↓
BI Dashboards / Reports
```

---

## 🚀 Comandos Principales

### Ingesta de Datos
```bash
python ingestion_polars.py
```

### Transformaciones dbt

```bash
# Ejecutar todo
dbt run

# Solo Bronze
dbt run --models bronze.*

# Solo Silver
dbt run --models silver.*

# Solo Gold
dbt run --models gold.*

# Un pilar específico
dbt run --models gold.1_financial_performance.*
dbt run --models gold.2_customer_analytics.*
dbt run --models gold.3_operational_excellence.*
dbt run --models gold.4_product_intelligence.*

# Tests de calidad
dbt test

# Documentación
dbt docs generate
dbt docs serve
```

### Análisis Exploratorio
```bash
# Activar entorno virtual
.\venv\Scripts\Activate.ps1

# Jupyter
jupyter notebook notebooks/data_quality_checks.ipynb
```

---

## 📚 Documentación

- **[Data Quality Findings](docs/data_quality_findings.md)** - Problemas identificados en Bronze
- **[Data Cleaning Strategy](docs/data_cleaning_strategy.md)** - Estrategia de limpieza Silver
- **[Enterprise Analytics Strategy](docs/enterprise_analytics_strategy.md)** - Arquitectura 4 pilares
- **[Kaggle Setup](docs/kaggle_setup.md)** - Configuración de ingesta

---

## 🔄 Changelog

### 2025-12-14 - Rediseño de Arquitectura
- ✅ Creada nueva estructura de carpetas
- ✅ Archivados modelos antiguos de Silver/Gold
- ✅ Implementada arquitectura de 4 pilares
- ✅ Creada carpeta `src/` para scripts
- ⏳ Pendiente: Implementar nuevos modelos Silver
- ⏳ Pendiente: Implementar modelos Gold por pilar

### 2025-12-14 - EDA Completado
- ✅ Análisis de calidad de datos en Bronze
- ✅ Identificados 3 problemas críticos
- ✅ Documentación completa de hallazgos

---

**Mantenido por:** Insights Lead - Tier One  
**Última revisión:** 2025-12-14
