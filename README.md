# 🏪 Retail Analytics - Interactive Executive Report

> **Strategic Data Brief: Uncovering £257K in Hidden Costs Through Advanced Analytics**

[![Live Report](https://img.shields.io/badge/Report-Live-success?style=for-the-badge)](https://emolinasaez.github.io/bi-supermarket-data/)
[![dbt](https://img.shields.io/badge/dbt-FF694B?style=for-the-badge&logo=dbt&logoColor=white)](https://www.getdbt.com/)
[![DuckDB](https://img.shields.io/badge/DuckDB-FFF000?style=for-the-badge&logo=duckdb&logoColor=black)](https://duckdb.org/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)

---

## 🎯 Executive Summary

This project demonstrates how to **transform raw data into strategic insights** through modern data architecture and advanced analytical methodologies. Designed as a **Quarterly Business Review (Q3 2011)**, this interactive report reveals:

- **£257,646** in unreported inventory losses (COGS-based, not inflated retail price)
- **£494,646+** in total annual improvement opportunities
- **1 Black Swan event** detected via Six Sigma statistical process control
- **71% of revenue** concentrated in top 20% of customers (Pareto principle confirmed)

**[📊 View Interactive Executive Report →](https://emolinasaez.github.io/bi-supermarket-data/)**

> **Note on Format:** This is an **immutable strategic report** (frozen snapshot), not an operational dashboard. The static architecture ensures narrative integrity and portability for board presentations without dependency on live database connections or BI server licenses.

---

## 💼 Business Impact

### The Problem
A retail company with **541,909 transactions** (Dec 2010 - Sep 2011) reported healthy profits, but the data told a different story:

- ❌ **1,336 inventory adjustments** recorded at £0.00 cost
- ❌ **15.97% of products** with inconsistent data
- ❌ **Profit inflated** by not accounting for real losses at cost

### The Solution
Implemented a **Medallion Architecture** (Bronze → Silver → Gold) with **4 Analytical Pillars**:

1. **💰 Financial Performance** - Adjusted profit with real COGS-based losses
2. **👥 Customer Analytics** - RFM segmentation and CLV modeling
3. **⚙️ Operational Excellence** - Six Sigma loss control
4. **📦 Product Intelligence** - Stars vs Zombies classification

### The Results

| Metric | Value | Impact |
|---------|-------|---------|
| **Hidden Losses Identified (COGS)** | £257,646 | Financial statement adjustment |
| **At-Risk Customers** | 1,392 (32%) | Retention opportunity £245K |
| **Zombie Products** | 53 | Candidates for discontinuation |
| **Black Swan Events** | 1 (7.26σ) | Root cause investigation required |
| **Total Annual Opportunity** | **£494,646+** | Estimated 8:1 ROI |

> **Financial Methodology Note:** Losses calculated at estimated COGS (60% of retail price), not retail price. This distinction is critical: **Cash Out (COGS)** vs **Opportunity Cost (Retail Price)**. Using a typical 40% retail margin ensures we don't inflate losses by including expected profit margin.

---

## 🏗️ Technical Architecture

### Stack Tecnológico

```
Data Ingestion    → Polars + Kaggle API
Data Storage      → DuckDB (OLAP optimized)
Transformation    → dbt (SQL-first, versioned)
Analysis          → Python + Jupyter
Presentation      → Chart.js (static web report)
Orchestration     → Medallion Architecture
```

### Medallion Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  BRONZE LAYER - Raw Data (Immutable)                        │
│  • 541,909 transactions untransformed                       │
│  • Ingestion from Kaggle API with Polars                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  SILVER LAYER - Curated Data (Clean & Structured)           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Foundation (Dimensions)                              │   │
│  │  • dim_products (4,070) - Normalized descriptions    │   │
│  │  • dim_customers (4,342) - Customer master           │   │
│  │  • dim_calendar (285) - Business calendar            │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Transactions (Facts)                                 │   │
│  │  • fact_sales (~537K) - Sales and returns           │   │
│  │  • fact_inventory_losses (1,336) - Losses w/ COGS   │   │
│  │  • fact_accounting_adjustments (2,866) - Adjustments│   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Reference Data (Seeds)                               │   │
│  │  • excluded_stock_codes - Non-product codes (11)    │   │
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
**Objective:** Detect anomalies in weekly inventory losses

**Methodology:**
- Calculate mean (μ) and standard deviation (σ)
- Control limits: UCL = μ + 3σ, LCL = μ - 3σ
- Z-score for each week
- Classification: Normal, 2σ Warning, 3σ Out of Control, 6σ Black Swan

**Result:**
```
Week 2011-W24: 28,258 units lost (7.26σ)
→ Black Swan event detected
→ Financial impact: £13,780 (COGS)
→ Action: Root cause investigation
```

### 2. RFM Customer Segmentation
**Objective:** Classify customers by value and behavior

**Methodology:**
- **Recency:** Days since last purchase
- **Frequency:** Number of transactions
- **Monetary:** Total value spent
- Quintiles (1-5) for each dimension
- Segments: Champions, Loyal, At Risk, etc.

**Result:**
```
Champions (981 customers):
  • 22.6% of base
  • £5.72M in revenue (59.8% of total)
  • Avg CLV: £32,244
  
At Risk (1,392 customers):
  • 32.1% of base
  • £491K in revenue (5.1% of total)
  • Retention opportunity: £245K/year
```

### 3. COGS-Based Loss Calculation (Critical)
**Objective:** Accurately quantify financial impact of inventory losses

**Methodology:**
- **Problem:** Inventory adjustments recorded at £0.00
- **Solution:** Impute using average product price × cost factor
- **Cost Factor:** 0.60 (assumes 40% retail margin)
- **Formula:** Loss = Quantity × Avg Price × 0.60

**Why This Matters:**
```
❌ Wrong: Loss = Quantity × Retail Price (£429K)
   → Inflates losses by including expected profit margin
   → This is "Opportunity Cost", not actual cash out

✅ Correct: Loss = Quantity × COGS (£257K)
   → Reflects actual cash out / cost of acquisition
   → This is "Financial Loss" for accounting purposes
```

---

## 📊 Data Quality Findings

### Problem 1: Inconsistent Descriptions
- **Impact:** 15.97% of products (650 of 4,070)
- **Example:** StockCode "84879" with 8 different descriptions
- **Solution:** Normalization by frequency in `dim_products`

### Problem 2: Zero-Cost Inventory Adjustments
- **Impact:** 1,336 records (0.25% of transactions)
- **Problem:** Losses recorded at £0.00 → Profit inflated
- **Solution:** COGS imputation using average price × 0.60
- **Result:** £257,646 in unreported losses (COGS) discovered

### Problem 3: Hardcoded Exclusions (Technical Debt)
- **Impact:** Maintenance risk, scalability issues
- **Problem:** NOT IN clause with magic strings in SQL
- **Solution:** Seed table `excluded_stock_codes.csv` (11 codes)
- **Benefit:** Scalable, version-controlled, auditable

---

## 🚀 Quick Start

### Prerequisites
```bash
Python 3.10+
Git
```

### Installation

```bash
# 1. Clone repository
git clone https://github.com/emolinasaez/bi-supermarket-data.git
cd bi-supermarket-data

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure Kaggle API (optional, for re-ingestion)
# Place kaggle.json in ~/.kaggle/

# 5. Run dbt transformations
cd dwh
dbt seed  # Load excluded_stock_codes.csv
dbt run

# 6. Run quality tests
dbt test

# 7. View interactive report
# Open docs/index.html in browser
```

### Useful dbt Commands

```bash
# Run only Silver layer
dbt run --select silver.*

# Run only Gold layer
dbt run --select gold.*

# Run specific pillar
dbt run --select gold.1_financial_performance.*

# View documentation
dbt docs generate
dbt docs serve

# Run tests
dbt test --select silver.*
```

---

## 📁 Project Structure

```
bi-supermarket-data/
├── data/                          # Raw data (gitignored)
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
│   ├── seeds/
│   │   └── excluded_stock_codes.csv  # Non-product codes
│   ├── dbt_project.yml
│   └── profiles.yml
├── src/                           # Python scripts
│   └── analysis/
│       └── extract_presentation_data.py
├── notebooks/                     # Jupyter notebooks
│   └── data_quality_checks.ipynb
├── docs/                          # Documentation & Report
│   ├── index.html                # Report ES
│   ├── index-en.html             # Report EN
│   ├── presentation_data.json    # Metrics data (frozen snapshot)
│   ├── executive_presentation_strategy.md
│   └── data_quality_findings.md
└── README.md
```

---

## 📈 Key Insights & Recommendations

### 1. Implement Real Cost Accounting
**Problem:** £257K in unaccounted losses (COGS)  
**Action:** Impute average costs to inventory adjustments  
**Impact:** Accurate financial statements, better decision-making

### 2. At-Risk Customer Retention Program
**Problem:** 1,392 "At Risk" customers (32% of base)  
**Action:** Personalized reactivation campaign  
**Impact:** Retain 50% = £245K/year in revenue

### 3. Discontinue Zombie Products
**Problem:** 53 products with minimal revenue and high returns  
**Action:** Remove from catalog, free up inventory  
**Impact:** £50K/year in operational costs

### 4. Investigate Black Swan Event
**Problem:** Week 2011-W24 with 28,258 units lost  
**Action:** Root cause analysis, implement controls  
**Impact:** Prevent recurrence, £60K/year in efficiency

---

## 🛠️ Technologies & Skills Demonstrated

### Data Engineering
- ✅ **Medallion Architecture** - Bronze/Silver/Gold layers
- ✅ **dbt** - SQL transformations, testing, documentation
- ✅ **DuckDB** - OLAP database for analytics
- ✅ **Polars** - High-performance data ingestion
- ✅ **Data Quality** - Automated testing with dbt
- ✅ **Seed Tables** - Reference data management

### Analytics & BI
- ✅ **Six Sigma** - Statistical process control
- ✅ **RFM Analysis** - Customer segmentation
- ✅ **CLV Modeling** - Customer lifetime value
- ✅ **ABC Classification** - Product portfolio optimization
- ✅ **Anomaly Detection** - Black Swan events
- ✅ **COGS Estimation** - Financial modeling

### Presentation & Storytelling
- ✅ **Chart.js** - Interactive web visualizations
- ✅ **Storytelling with Data** - Executive narratives
- ✅ **Harvard Case Method** - Business narrative structure
- ✅ **Responsive Design** - Mobile-first web development
- ✅ **Static Site Generation** - Immutable reports

### Software Engineering
- ✅ **Python** - Data processing, automation
- ✅ **SQL** - Complex analytical queries
- ✅ **Git** - Version control
- ✅ **Documentation** - Technical & business docs
- ✅ **Best Practices** - No magic strings, seed tables

---

## 📚 Documentation

- **[Interactive Executive Report](https://emolinasaez.github.io/bi-supermarket-data/)** - Live presentation
- **[Executive Presentation Strategy](docs/executive_presentation_strategy.md)** - Storytelling framework
- **[Data Quality Findings](docs/data_quality_findings.md)** - EDA results
- **[Project Structure](PROJECT_STRUCTURE.md)** - Directory organization

---

## 🎓 Learning Outcomes

This project demonstrates competence in:

1. **Modern Data Architecture**
   - Design and implementation of Medallion Architecture
   - Separation of concerns (Bronze/Silver/Gold)
   - Automated data quality testing
   - Reference data management with seeds

2. **Business Analysis**
   - Translation of data to actionable insights
   - Quantification of financial impact
   - Prioritization of initiatives by ROI
   - **Critical:** COGS vs Retail Price distinction

3. **Executive Communication**
   - Data-driven presentations
   - Storytelling with 3-act structure
   - Impactful visualizations
   - **Strategic positioning:** Report vs Dashboard

4. **Analytical Methodologies**
   - Six Sigma for quality control
   - RFM for customer segmentation
   - Portfolio analysis for product optimization
   - Financial modeling for cost estimation

---

## 🤝 Connect

**Esteban Molina**  
Data Analytics Professional | Business Intelligence | Data Engineering

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/emolinasaez/)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/emolinasaez)
[![Portfolio](https://img.shields.io/badge/Portfolio-FF5722?style=for-the-badge&logo=google-chrome&logoColor=white)](https://emolinasaez.github.io/bi-supermarket-data/)

---

## 📄 License

This project uses public data from **Marc Szafraniec** - [Online Retail Sales and Customer Data](https://www.kaggle.com/datasets/marian447/retail-store-sales-transactions) from Kaggle for educational and demonstration purposes.

---

## 🙏 Acknowledgments

- **Dataset:** Marc Szafraniec - Online Retail Sales and Customer Data from Kaggle
- **Inspiration:** Storytelling with Data (Cole Nussbaumer Knaflic)
- **Methodology:** Harvard Business School Case Method
- **Tools:** dbt Labs, DuckDB Foundation, Polars

---

<div align="center">

**[🚀 View Interactive Report](https://emolinasaez.github.io/bi-supermarket-data/)** | **[📧 Contact](mailto:emolinasaez@example.com)**

*Transforming data into strategic decisions*

**Format:** Interactive Executive Report (Q3 2011) | **Architecture:** Frozen Snapshot for Narrative Integrity

</div>
