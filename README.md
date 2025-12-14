# 🛒 Retail Analytics Portfolio - Análisis RFM de Ventas

## 📊 Descripción del Proyecto

Proyecto de portafolio de analítica de datos que implementa un pipeline completo de datos utilizando la **arquitectura Medallion** (Bronze, Silver, Gold) para analizar transacciones de retail y generar segmentación de clientes mediante el modelo **RFM (Recency, Frequency, Monetary)**.

### 🎯 Objetivos de Negocio

- Identificar patrones de comportamiento de clientes
- Segmentar clientes según su valor y engagement
- Proporcionar insights accionables para estrategias de marketing
- Detectar clientes en riesgo de abandono
- Optimizar campañas de retención y adquisición

## 🏗️ Arquitectura Técnica

### Stack Tecnológico

- **Motor de Base de Datos:** DuckDB
- **Transformación de Datos:** dbt (data build tool)
- **Ingesta de Datos:** Polars (Python)
- **Visualización:** Tableau / Power BI
- **Orquestación:** dbt + Python scripts

### Arquitectura Medallion

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   BRONZE    │ ───> │   SILVER    │ ───> │    GOLD     │
│  (Raw Data) │      │  (Cleaned)  │      │ (Analytics) │
└─────────────┘      └─────────────┘      └─────────────┘
```

#### 🥉 Capa Bronze
- **Propósito:** Ingesta cruda de datos desde fuentes externas
- **Tecnología:** Polars + DuckDB
- **Proceso:** Carga dinámica desde API/URL sin almacenamiento local

#### 🥈 Capa Silver
- **Propósito:** Limpieza, validación y transformación de datos
- **Transformaciones:**
  - Filtrado de transacciones canceladas
  - Cálculo de métricas derivadas (TotalVenta)
  - Creación de claves subrogadas
  - Normalización de datos

#### 🥇 Capa Gold
- **Propósito:** Modelos analíticos listos para consumo
- **Modelos:**
  - Cálculo de métricas RFM por cliente
  - Segmentación de clientes (Champions, Loyal, At Risk, etc.)
  - Agregaciones para dashboards

## 📁 Estructura del Proyecto

```
bi-supermarket-data/
├── .env                          # Variables de entorno
├── .gitignore                    # Archivos excluidos de Git
├── dbt_project.yml               # Configuración de dbt
├── README.md                     # Este archivo
├── requirements.txt              # Dependencias Python
├── ingestion_polars.py           # Script de ingesta (Bronze)
│
├── bi/                           # Dashboards de BI
│   └── dashboard_final.md        # Placeholder para Tableau/Power BI
│
├── docs/                         # Documentación técnica
│   ├── arquitectura.md           # Flujo de datos Medallion
│   └── diccionario_datos.md      # Diccionario de datos
│
└── dwh/                          # Data Warehouse (dbt)
    ├── profiles.yml              # Conexión a DuckDB
    └── models/
        ├── bronze/               # Capa Bronze
        │   └── bronze_raw_data.sql
        ├── silver/               # Capa Silver
        │   ├── silver_cleaned_transactions.sql
        │   └── silver_cancellation_log.sql
        └── gold/                 # Capa Gold (RFM)
            ├── gold_customer_rfm.sql
            └── gold_rfm_segments.sql
```

## 🚀 Guía de Inicio Rápido

### Opción A: Con Docker 🐳 (Recomendado)

**Requisitos:** Docker Desktop instalado

```bash
# Clonar el repositorio
git clone https://github.com/emolinasaez/bi-supermarket-data.git
cd bi-supermarket-data

# Ejecutar pipeline completo con un solo comando
make quick-start

# O paso por paso:
make build          # Construir imagen Docker
make ingestion      # Ingesta de datos (Bronze)
make dbt-deps       # Instalar dependencias dbt
make dbt-run        # Transformaciones (Silver + Gold)
make dbt-test       # Tests de calidad
make dbt-docs       # Documentación (http://localhost:8080)
```

**Comandos útiles:**
```bash
make help           # Ver todos los comandos disponibles
make shell          # Abrir shell interactivo
make logs           # Ver logs del contenedor
make clean          # Limpiar volúmenes y contenedores
```

---

### Opción B: Instalación Local (Sin Docker)

**Requisitos:** Python 3.11+


### 1. Configuración del Entorno (Local)

```bash
# Clonar el repositorio
git clone https://github.com/emolinasaez/bi-supermarket-data.git
cd bi-supermarket-data

# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt
```

### 2. Configurar Variables de Entorno (Local)

Editar el archivo `.env` con tus credenciales:

```env
DATASET_URL=https://archive.ics.uci.edu/ml/machine-learning-databases/00352/Online%20Retail.xlsx
DUCKDB_PATH=dwh/retail_analytics.duckdb
```

### 3. Ejecutar Ingesta de Datos (Bronze) - Local

```bash
python ingestion_polars.py
```

### 4. Ejecutar Transformaciones dbt (Silver + Gold) - Local

```bash
cd dwh
dbt deps
dbt run
dbt test
```

### 5. Generar Documentación - Local

```bash
dbt docs generate
dbt docs serve
```

## 📈 Modelo RFM

### Definición de Métricas

- **Recency (R):** Días desde la última compra
- **Frequency (F):** Número total de transacciones
- **Monetary (M):** Valor total gastado

### Segmentación de Clientes

| Segmento | R | F | M | Estrategia |
|----------|---|---|---|------------|
| **Champions** | 5 | 5 | 5 | Recompensar y retener |
| **Loyal Customers** | 3-5 | 4-5 | 3-5 | Upselling |
| **At Risk** | 1-2 | 3-4 | 3-4 | Campañas de reactivación |
| **Lost** | 1 | 1-2 | 1-2 | Recuperación agresiva |

## 📊 Resultados y Visualizaciones

Los dashboards finales están disponibles en:
- **Tableau Public:** [Link pendiente]
- **Power BI:** Ver `bi/dashboard_final.md`

## 🧪 Testing y Calidad de Datos

```bash
# Ejecutar tests de dbt
dbt test

# Validar calidad de datos
dbt test --select tag:data_quality
```

## 📚 Documentación Adicional

- [Arquitectura Medallion](docs/arquitectura.md)
- [Diccionario de Datos](docs/diccionario_datos.md)

## 👤 Autor

**Eduardo Molina Sáez**
- GitHub: [@emolinasaez](https://github.com/emolinasaez)
- LinkedIn: [Eduardo Molina Sáez]

## 📝 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

---

⭐ **Si este proyecto te resulta útil, considera darle una estrella en GitHub!**
