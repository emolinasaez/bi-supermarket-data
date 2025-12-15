# 🏪 Retail Analytics - Data-Driven Transformation

> **Descubriendo £429K en pérdidas ocultas mediante Arquitectura Medallion y Análisis Six Sigma**

[![Live Demo](https://img.shields.io/badge/Demo-Live-success?style=for-the-badge)](https://emolinasaez.github.io/bi-supermarket-data/)
[![dbt](https://img.shields.io/badge/dbt-FF694B?style=for-the-badge&logo=dbt&logoColor=white)](https://www.getdbt.com/)
[![DuckDB](https://img.shields.io/badge/DuckDB-FFF000?style=for-the-badge&logo=duckdb&logoColor=black)](https://duckdb.org/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)

---

## 🎯 Executive Summary

Este proyecto demuestra cómo **transformar datos crudos en insights accionables** que generan valor de negocio real. A través de una arquitectura moderna de datos y metodologías analíticas avanzadas, descubrí:

- **£429,410** en pérdidas no reportadas (costos ocultos en inventario)
- **£824,410+** en oportunidades anuales de mejora
- **1 evento "Cisne Negro"** detectado mediante control estadístico Six Sigma
- **71% de ingresos** concentrados en el 20% superior de clientes (Pareto confirmado)

**[📊 Ver Presentación Ejecutiva Interactiva →](https://emolinasaez.github.io/bi-supermarket-data/)**

---

## 💼 Business Impact

### El Problema
Una empresa retail con **541,909 transacciones** (Dic 2010 - Sep 2011) reportaba ganancias saludables, pero los datos contaban otra historia:

- ❌ **1,336 ajustes de inventario** registrados a costo £0.00
- ❌ **15.97% de productos** con datos inconsistentes
- ❌ **Profit inflado** por no contabilizar pérdidas reales

### La Solución
Implementé una **Arquitectura Medallion** (Bronze → Silver → Gold) con **4 Pilares Analíticos**:

1. **💰 Financial Performance** - Profit ajustado con costos reales
2. **👥 Customer Analytics** - Segmentación RFM y CLV
3. **⚙️ Operational Excellence** - Control Six Sigma de mermas
4. **📦 Product Intelligence** - Clasificación Stars vs Zombies

### Los Resultados

| Métrica | Valor | Impacto |
|---------|-------|---------|
| **Pérdidas Ocultas Identificadas** | £429,410 | Ajuste de estados financieros |
| **Clientes en Riesgo** | 1,392 (32%) | Oportunidad de retención £245K |
| **Productos Zombie** | 53 | Candidatos para descontinuar |
| **Black Swan Events** | 1 (7.26σ) | Investigación de causa raíz |
| **Oportunidad Total Anual** | **£824,410+** | ROI 10:1 estimado |

---

## 🏗️ Technical Architecture

### Stack Tecnológico

```
Data Ingestion    → Polars + Kaggle API
Data Storage      → DuckDB (OLAP optimizado)
Transformation    → dbt (SQL-first, versionado)
Analysis          → Python + Jupyter
Visualization     → Chart.js (presentación web)
Orchestration     → Medallion Architecture
```

### Arquitectura Medallion

```
┌─────────────────────────────────────────────────────────────┐
│  BRONZE LAYER - Raw Data (Immutable)                        │
│  • 541,909 transacciones sin transformar                    │
│  • Ingesta desde Kaggle API con Polars                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  SILVER LAYER - Curated Data (Clean & Structured)           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Foundation (Dimensions)                              │   │
│  │  • dim_products (4,070) - Descripciones normalizadas│   │
│  │  • dim_customers (4,342) - Customer master           │   │
│  │  • dim_calendar (285) - Calendario de negocio        │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Transactions (Facts)                                 │   │
│  │  • fact_sales (~537K) - Ventas y devoluciones       │   │
│  │  • fact_inventory_losses (1,336) - Mermas con costos│   │
│  │  • fact_accounting_adjustments (2,866) - Ajustes    │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  GOLD LAYER - Business Intelligence (Actionable Insights)   │
│  ┌──────────────────┬──────────────────┬─────────────────┐ │
│  │ 1. Financial     │ 2. Customer      │ 3. Operational  │ │
│  │ Performance      │ Analytics        │ Excellence      │ │
│  │                  │                  │                 │ │
│  │ • Revenue        │ • RFM Segments   │ • Six Sigma     │ │
│  │ • Loss Impact    │ • CLV            │ • Anomalies     │ │
│  │ • KPIs           │ • Cohorts        │ • Control Chart │ │
│  └──────────────────┴──────────────────┴─────────────────┘ │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 4. Product Intelligence                              │   │
│  │  • Performance (Stars/Zombies)                       │   │
│  │  • Pricing Analysis                                  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔬 Key Analytical Techniques

### 1. Six Sigma Statistical Process Control
**Objetivo:** Detectar anomalías en pérdidas semanales de inventario

**Metodología:**
- Cálculo de media (μ) y desviación estándar (σ)
- Límites de control: UCL = μ + 3σ, LCL = μ - 3σ
- Z-score para cada semana
- Clasificación: Normal, 2σ Warning, 3σ Out of Control, 6σ Black Swan

**Resultado:**
```
Semana 2011-W24: 28,258 unidades perdidas (7.26σ)
→ Evento Cisne Negro detectado
→ Impacto financiero: £13,780
→ Acción: Investigación de causa raíz
```

### 2. RFM Customer Segmentation
**Objetivo:** Clasificar clientes por valor y comportamiento

**Metodología:**
- **Recency:** Días desde última compra
- **Frequency:** Número de transacciones
- **Monetary:** Valor total gastado
- Quintiles (1-5) para cada dimensión
- Segmentos: Champions, Loyal, At Risk, etc.

**Resultado:**
```
Champions (981 clientes):
  • 22.6% de la base
  • £5.72M en revenue (59.8% del total)
  • Avg CLV: £32,244
  
At Risk (1,392 clientes):
  • 32.1% de la base
  • £491K en revenue (5.1% del total)
  • Oportunidad de retención: £245K/año
```

### 3. Product Portfolio Analysis
**Objetivo:** Optimizar mix de productos

**Metodología:**
- Clasificación ABC por revenue
- Tasa de devolución como indicador de calidad
- Matriz 2x2: Revenue vs Return Rate

**Resultado:**
```
⭐ Stars (698): £6.85M revenue, 1.21% return rate
📦 Regular (3,067): £2.86M revenue, 1.08% return rate
⚠️ Problem (95): £571K revenue, 50.85% return rate
🧟 Zombies (53): £2.4K revenue, 60.26% return rate
```

---

## 📊 Data Quality Findings

### Problema 1: Descripciones Inconsistentes
- **Impacto:** 15.97% de productos (650 de 4,070)
- **Ejemplo:** StockCode "84879" con 8 descripciones diferentes
- **Solución:** Normalización por frecuencia en `dim_products`

### Problema 2: Costos de Inventario a Cero
- **Impacto:** 1,336 registros (0.25% de transacciones)
- **Problema:** Mermas registradas a £0.00 → Profit inflado
- **Solución:** Imputación de costos usando precio promedio del producto
- **Resultado:** £429,410 en pérdidas NO reportadas descubiertas

### Problema 3: Transacciones Mezcladas
- **Impacto:** 2,866 registros (0.53% de transacciones)
- **Problema:** Descuentos, envíos, ajustes mezclados con ventas
- **Solución:** Separación en `fact_accounting_adjustments`

---

## 🚀 Quick Start

### Prerrequisitos
```bash
Python 3.10+
Git
```

### Instalación

```bash
# 1. Clonar repositorio
git clone https://github.com/emolinasaez/bi-supermarket-data.git
cd bi-supermarket-data

# 2. Crear entorno virtual
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 3. Instalar dependencias
pip install -r requirements.txt

# 4. Configurar Kaggle API (opcional, para re-ingesta)
# Colocar kaggle.json en ~/.kaggle/

# 5. Ejecutar transformaciones dbt
cd dwh
dbt run

# 6. Ejecutar tests de calidad
dbt test

# 7. Ver presentación
# Abrir docs/index.html en navegador
```

### Comandos dbt Útiles

```bash
# Ejecutar solo Silver layer
dbt run --select silver.*

# Ejecutar solo Gold layer
dbt run --select gold.*

# Ejecutar un pilar específico
dbt run --select gold.1_financial_performance.*

# Ver documentación
dbt docs generate
dbt docs serve

# Ejecutar tests
dbt test --select silver.*
```

---

## 📁 Project Structure

```
bi-supermarket-data/
├── data/                          # Datos crudos (gitignored)
├── dwh/                           # Data Warehouse (dbt)
│   ├── models/
│   │   ├── bronze/               # Raw data
│   │   ├── silver/               # Curated data
│   │   │   ├── foundation/       # Dimensions
│   │   │   └── transactions/     # Facts
│   │   └── gold/                 # Business Intelligence
│   │       ├── 1_financial_performance/
│   │       ├── 2_customer_analytics/
│   │       ├── 3_operational_excellence/
│   │       └── 4_product_intelligence/
│   ├── dbt_project.yml
│   └── profiles.yml
├── src/                           # Python scripts
│   └── analysis/
│       └── extract_presentation_data.py
├── notebooks/                     # Jupyter notebooks
│   └── data_quality_checks.ipynb
├── docs/                          # Documentation & Presentation
│   ├── index.html                # Presentación ES
│   ├── index-en.html             # Presentation EN
│   ├── presentation_data.json    # Metrics data
│   ├── executive_presentation_strategy.md
│   └── data_quality_findings.md
└── README.md
```

---

## 📈 Key Insights & Recommendations

### 1. Implementar Contabilidad de Costos Reales
**Problema:** £429K en pérdidas no contabilizadas  
**Acción:** Imputar costos promedio a ajustes de inventario  
**Impacto:** Estados financieros precisos, mejor toma de decisiones

### 2. Programa de Retención de Clientes en Riesgo
**Problema:** 1,392 clientes "At Risk" (32% de la base)  
**Acción:** Campaña de reactivación personalizada  
**Impacto:** Retener 50% = £245K/año en revenue

### 3. Descontinuar Productos Zombie
**Problema:** 53 productos con revenue mínimo y alta devolución  
**Acción:** Eliminar del catálogo, liberar inventario  
**Impacto:** £50K/año en costos operativos

### 4. Investigar Evento Cisne Negro
**Problema:** Semana 2011-W24 con 28,258 unidades perdidas  
**Acción:** Root cause analysis, implementar controles  
**Impacto:** Prevenir recurrencia, £100K/año en eficiencia

---

## 🛠️ Technologies & Skills Demonstrated

### Data Engineering
- ✅ **Medallion Architecture** - Bronze/Silver/Gold layers
- ✅ **dbt** - SQL transformations, testing, documentation
- ✅ **DuckDB** - OLAP database for analytics
- ✅ **Polars** - High-performance data ingestion
- ✅ **Data Quality** - Automated testing with dbt

### Analytics & BI
- ✅ **Six Sigma** - Statistical process control
- ✅ **RFM Analysis** - Customer segmentation
- ✅ **CLV Modeling** - Customer lifetime value
- ✅ **ABC Classification** - Product portfolio optimization
- ✅ **Anomaly Detection** - Black Swan events

### Visualization & Storytelling
- ✅ **Chart.js** - Interactive web visualizations
- ✅ **Storytelling with Data** - Executive presentations
- ✅ **Harvard Case Method** - Business narrative structure
- ✅ **Responsive Design** - Mobile-first web development

### Software Engineering
- ✅ **Python** - Data processing, automation
- ✅ **SQL** - Complex analytical queries
- ✅ **Git** - Version control
- ✅ **Documentation** - Technical & business docs

---

## 📚 Documentation

- **[Executive Presentation Strategy](docs/executive_presentation_strategy.md)** - Storytelling framework
- **[Data Quality Findings](docs/data_quality_findings.md)** - EDA results
- **[Project Structure](PROJECT_STRUCTURE.md)** - Directory organization
- **[Enterprise Analytics Strategy](docs/enterprise_analytics_strategy.md)** - 4 Pillars design

---

## 🎓 Learning Outcomes

Este proyecto demuestra competencia en:

1. **Arquitectura de Datos Moderna**
   - Diseño e implementación de Medallion Architecture
   - Separación de concerns (Bronze/Silver/Gold)
   - Data quality testing automatizado

2. **Análisis de Negocio**
   - Traducción de datos a insights accionables
   - Cuantificación de impacto financiero
   - Priorización de iniciativas por ROI

3. **Comunicación Ejecutiva**
   - Presentaciones data-driven
   - Storytelling con estructura de 3 actos
   - Visualizaciones impactantes

4. **Metodologías Analíticas**
   - Six Sigma para control de calidad
   - RFM para segmentación de clientes
   - Portfolio analysis para optimización de productos

---

## 🤝 Connect

**Esteban Molina**  
Data Analytics Professional | Business Intelligence | Data Engineering

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/emolinasaez/)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/emolinasaez)
[![Portfolio](https://img.shields.io/badge/Portfolio-FF5722?style=for-the-badge&logo=google-chrome&logoColor=white)](https://emolinasaez.github.io/bi-supermarket-data/)

---

## 📄 License

Este proyecto utiliza datos públicos del [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/Online+Retail) para fines educativos y de demostración.

---

## 🙏 Acknowledgments

- **Dataset:** UCI Machine Learning Repository - Online Retail Dataset
- **Inspiration:** Storytelling with Data (Cole Nussbaumer Knaflic)
- **Methodology:** Harvard Business School Case Method
- **Tools:** dbt Labs, DuckDB Foundation, Polars

---

<div align="center">

**[🚀 Ver Demo en Vivo](https://emolinasaez.github.io/bi-supermarket-data/)** | **[📧 Contacto](mailto:emolinasaez@example.com)**

*Transformando datos en decisiones estratégicas*

</div>
