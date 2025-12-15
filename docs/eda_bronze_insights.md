# 📊 EDA Insights - Bronze Layer

> **Proyecto:** Retail Analytics - BI Supermarket Data  
> **Fecha de análisis:** 2025-12-14  
> **Capa analizada:** Bronze (raw_data)  
> **Notebook:** `notebooks/data_quality_checks.ipynb`

---

## 🎯 Objetivo del EDA

Realizar un análisis exploratorio exhaustivo de los datos crudos en la capa Bronze para:
1. Entender la estructura y distribución de los datos
2. Identificar problemas de calidad
3. Detectar patrones y anomalías
4. Informar decisiones de limpieza para Silver

---

## 📦 1. Descripción General del Dataset

### Métricas Básicas
```
Total de registros: [PENDIENTE]
Período de datos: [PENDIENTE]
Países únicos: [PENDIENTE]
Clientes únicos: [PENDIENTE]
Productos únicos: 4,070
```

### Estructura de Datos
- **InvoiceNo:** Identificador de factura
- **StockCode:** Código de producto
- **Description:** Descripción del producto ⚠️ (Ver data_quality_findings.md)
- **Quantity:** Cantidad vendida
- **InvoiceDate:** Fecha de la transacción
- **UnitPrice:** Precio unitario
- **CustomerID:** Identificador del cliente
- **Country:** País del cliente

---

## 🔍 2. Análisis por Campo

### 2.1 StockCode & Description
✅ **Análisis completado** - Ver `data_quality_findings.md`

**Hallazgo principal:** 15.97% de productos con descripciones inconsistentes

---

### 2.2 InvoiceNo (PENDIENTE)

**Preguntas a responder:**
- [ ] ¿Hay facturas canceladas? (InvoiceNo que empieza con 'C')
- [ ] ¿Cuántas transacciones por factura en promedio?
- [ ] ¿Hay duplicados en InvoiceNo?

**Query sugerida:**
```sql
-- Análisis de facturas canceladas
SELECT 
    CASE WHEN "InvoiceNo" LIKE 'C%' THEN 'Cancelled' ELSE 'Valid' END as invoice_type,
    COUNT(*) as num_records,
    COUNT(DISTINCT "InvoiceNo") as num_invoices
FROM retail.bronze.raw_data
GROUP BY invoice_type;
```

---

### 2.3 Quantity (PENDIENTE)

**Preguntas a responder:**
- [ ] ¿Hay cantidades negativas? (devoluciones)
- [ ] ¿Hay cantidades = 0?
- [ ] Distribución de cantidades (min, max, avg, percentiles)
- [ ] Outliers en cantidad

**Query sugerida:**
```sql
-- Análisis de cantidades
SELECT 
    COUNT(*) as total_records,
    SUM(CASE WHEN "Quantity" < 0 THEN 1 ELSE 0 END) as negative_qty,
    SUM(CASE WHEN "Quantity" = 0 THEN 1 ELSE 0 END) as zero_qty,
    MIN("Quantity") as min_qty,
    MAX("Quantity") as max_qty,
    ROUND(AVG("Quantity"), 2) as avg_qty,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "Quantity") as median_qty
FROM retail.bronze.raw_data;
```

---

### 2.4 UnitPrice (PENDIENTE)

**Preguntas a responder:**
- [ ] ¿Hay precios negativos o cero?
- [ ] Distribución de precios
- [ ] Outliers en precios
- [ ] Productos con precios inconsistentes

**Query sugerida:**
```sql
-- Análisis de precios
SELECT 
    COUNT(*) as total_records,
    SUM(CASE WHEN "UnitPrice" <= 0 THEN 1 ELSE 0 END) as invalid_price,
    MIN("UnitPrice") as min_price,
    MAX("UnitPrice") as max_price,
    ROUND(AVG("UnitPrice"), 2) as avg_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "UnitPrice") as median_price
FROM retail.bronze.raw_data;
```

---

### 2.5 InvoiceDate (PENDIENTE)

**Preguntas a responder:**
- [ ] Rango de fechas (min, max)
- [ ] ¿Hay valores NULL?
- [ ] ¿Hay fechas futuras o muy antiguas (anomalías)?
- [ ] Distribución temporal (por mes, día de semana)

**Query sugerida:**
```sql
-- Análisis temporal
SELECT 
    MIN("InvoiceDate") as first_transaction,
    MAX("InvoiceDate") as last_transaction,
    COUNT(DISTINCT DATE_TRUNC('month', "InvoiceDate")) as num_months,
    COUNT(*) as total_transactions
FROM retail.bronze.raw_data;
```

---

### 2.6 CustomerID (PENDIENTE)

**Preguntas a responder:**
- [ ] ¿Cuántos valores NULL? (transacciones sin cliente)
- [ ] Clientes únicos
- [ ] Distribución de transacciones por cliente
- [ ] Top clientes por volumen

**Query sugerida:**
```sql
-- Análisis de CustomerID NULL
SELECT 
    COUNT(*) as total_records,
    SUM(CASE WHEN "CustomerID" IS NULL THEN 1 ELSE 0 END) as null_customer,
    ROUND(100.0 * SUM(CASE WHEN "CustomerID" IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as pct_null
FROM retail.bronze.raw_data;
```

---

### 2.7 Country (PENDIENTE)

**Preguntas a responder:**
- [ ] Países únicos
- [ ] Distribución de transacciones por país
- [ ] Top 10 países
- [ ] ¿Hay valores NULL o inconsistentes?

**Query sugerida:**
```sql
-- Top países
SELECT 
    "Country",
    COUNT(*) as num_transactions,
    COUNT(DISTINCT "CustomerID") as num_customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as pct_transactions
FROM retail.bronze.raw_data
WHERE "Country" IS NOT NULL
GROUP BY "Country"
ORDER BY num_transactions DESC
LIMIT 10;
```

---

## 📈 3. Análisis de Valores Nulos

### Resumen de Nulos por Campo (PENDIENTE)

| Campo | Registros NULL | % NULL | Acción |
|-------|----------------|--------|--------|
| InvoiceNo | ? | ? | ? |
| StockCode | ? | ? | ? |
| Description | ? | ? | Ver data_quality_findings.md |
| Quantity | ? | ? | ? |
| InvoiceDate | ? | ? | ? |
| UnitPrice | ? | ? | ? |
| CustomerID | ? | ? | ? |
| Country | ? | ? | ? |

---

## ⚠️ 4. Detección de Anomalías

### 4.1 Transacciones Canceladas (PENDIENTE)
- Facturas que empiezan con 'C'
- Impacto en el análisis

### 4.2 Valores Negativos (PENDIENTE)
- Cantidades negativas (devoluciones)
- Precios negativos (errores)

### 4.3 Outliers (PENDIENTE)
- Transacciones con valores extremos
- Método: IQR (Interquartile Range)

---

## 💡 5. Insights de Negocio

### 5.1 Patrones Temporales (PENDIENTE)
- Estacionalidad
- Días/meses con más ventas
- Tendencias

### 5.2 Patrones Geográficos (PENDIENTE)
- Concentración de ventas por país
- Productos más vendidos por región

### 5.3 Productos (PENDIENTE)
- Top productos por revenue
- Productos con mayor frecuencia de compra
- Productos problemáticos

---

## ✅ 6. Checklist de Análisis

### Análisis Completados
- [x] StockCode & Description (inconsistencias identificadas)

### Pendientes
- [ ] Análisis de InvoiceNo y facturas canceladas
- [ ] Análisis de Quantity (negativos, outliers)
- [ ] Análisis de UnitPrice (distribución, outliers)
- [ ] Análisis temporal de InvoiceDate
- [ ] Análisis de CustomerID NULL
- [ ] Análisis geográfico de Country
- [ ] Resumen de valores nulos por campo
- [ ] Detección de outliers (IQR method)
- [ ] Top productos por revenue
- [ ] Distribución temporal de ventas

---

## 📎 Archivos Relacionados

- **Notebook:** `notebooks/data_quality_checks.ipynb`
- **Hallazgos de calidad:** `docs/data_quality_findings.md`
- **Estrategia de limpieza:** `docs/data_cleaning_strategy.md` (pendiente)

---

**Última actualización:** 2025-12-14  
**Estado:** 🟡 En progreso - 10% completado
