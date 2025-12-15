# 🎯 Data Cleaning Strategy - Silver Layer

> **Proyecto:** Retail Analytics - BI Supermarket Data  
> **Objetivo:** Transformar Bronze → Silver con reglas de calidad de datos  
> **Basado en:** Hallazgos documentados en `data_quality_findings.md`

---

## 📊 Resumen Ejecutivo

La capa Silver aplicará **5 estrategias principales de limpieza** para resolver los problemas identificados en Bronze:

1. ✅ **Product Master** - Normalización de nombres de productos
2. ✅ **Transaction Type Classification** - Separación de tipos de transacción
3. ✅ **Price Imputation** - Imputación de costos a mermas
4. ✅ **Data Quality Filters** - Exclusión de registros inválidos
5. ✅ **Standardization** - Normalización de campos y tipos de datos

---

## 🗺️ Roadmap de Implementación

### Fase 1: Tablas de Referencia (Foundation)

#### 1.1 Product Master (`silver_product_master.sql`)

**Objetivo:** Crear fuente única de verdad para nombres de productos.

**Reglas de selección de descripción canónica:**

```sql
-- Prioridad de selección (de mayor a menor):
1. Excluir NULL
2. Excluir notas operativas: 'check', 'test', 'manual', 'found', 'adjustment', 'Amazon'
3. Excluir notas de inventario: 'damaged', 'wet/rusty', 'missing', '???'
4. Excluir descripciones muy cortas (< 3 caracteres)
5. Excluir palabras clave problemáticas: 'wrongly', 'marked', 'cant manage', 'alan hodge'
6. Seleccionar la descripción con MAYOR FRECUENCIA
7. En caso de empate, seleccionar la MÁS LARGA (más descriptiva)
```

**Estructura de salida:**

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `stock_code` | VARCHAR | Código único del producto |
| `canonical_description` | VARCHAR | Descripción normalizada |
| `num_variations` | INTEGER | Número de variaciones encontradas |
| `total_transactions` | INTEGER | Total de transacciones del producto |
| `first_seen` | TIMESTAMP | Primera aparición |
| `last_seen` | TIMESTAMP | Última aparición |

**Impacto:** Resuelve Problema 1 (15.97% de productos con descripciones inconsistentes)

---

#### 1.2 Transaction Type Classifier

**Objetivo:** Clasificar todas las transacciones en categorías operacionales.

**Tipos de transacción:**

| Tipo | Criterios | Acción en Silver |
|------|-----------|------------------|
| **SALE** | `Quantity > 0` AND `InvoiceNo` sin 'C' AND `UnitPrice > 0` | ✅ Incluir en tabla principal |
| **RETURN** | `InvoiceNo` LIKE 'C%' AND `UnitPrice > 0` | ✅ Incluir en tabla principal |
| **INVENTORY_ADJUSTMENT** | `UnitPrice = 0` AND `CustomerID IS NULL` AND `Quantity < 0` | ⚠️ Tabla separada (opcional) |
| **SPECIAL_CODE** | `StockCode` IN ('M', 'D', 'POST', 'DOT', 'BANK CHARGES', etc.) | ❌ Excluir |
| **OTHER** | Casos no clasificados | ⚠️ Revisar manualmente |

**Impacto:** Resuelve Problema 2 y 3 (separación de ventas, devoluciones, mermas y ajustes contables)

---

### Fase 2: Transformaciones Principales

#### 2.1 Silver Cleaned Transactions (`silver_cleaned_transactions.sql`)

**Objetivo:** Tabla principal de transacciones limpias para análisis de ventas.

**Filtros aplicados:**

```sql
WHERE 
    -- Excluir códigos especiales
    stock_code NOT IN ('M', 'D', 'POST', 'DOT', 'BANK CHARGES', 'C2', 'PADS', 'S', 'B')
    AND LENGTH(stock_code) > 1
    
    -- Solo ventas y devoluciones
    AND transaction_type IN ('SALE', 'RETURN')
    
    -- Excluir ajustes de inventario
    AND NOT (unit_price = 0 AND customer_id IS NULL AND quantity < 0)
    
    -- Validaciones básicas
    AND stock_code IS NOT NULL
    AND invoice_no IS NOT NULL
    AND invoice_date IS NOT NULL
```

**Transformaciones:**

1. **JOIN con Product Master** para descripción canónica
2. **Conversión de tipos:**
   - `invoice_date`: VARCHAR → TIMESTAMP
   - `quantity`: VARCHAR → INTEGER
   - `unit_price`: VARCHAR → DECIMAL(10,2)
3. **Campos calculados:**
   - `total_sale = quantity * unit_price`
   - `transaction_type` (clasificación)
   - `year`, `month`, `week` (para análisis temporal)
4. **Normalización:**
   - `country`: TRIM y estandarización
   - `customer_id`: Conversión a INTEGER o NULL

**Estructura de salida:**

```sql
CREATE TABLE silver.silver_cleaned_transactions AS
SELECT 
    -- Identificadores
    invoice_no,
    stock_code,
    pm.canonical_description as description,  -- JOIN con product_master
    customer_id,
    country,
    
    -- Fechas (convertidas a TIMESTAMP)
    STRPTIME(invoice_date, '%m/%d/%Y %H:%M') as invoice_date,
    EXTRACT(YEAR FROM STRPTIME(invoice_date, '%m/%d/%Y %H:%M')) as invoice_year,
    EXTRACT(MONTH FROM STRPTIME(invoice_date, '%m/%d/%Y %H:%M')) as invoice_month,
    EXTRACT(WEEK FROM STRPTIME(invoice_date, '%m/%d/%Y %H:%M')) as invoice_week,
    
    -- Métricas
    CAST(quantity AS INTEGER) as quantity,
    CAST(unit_price AS DECIMAL(10,2)) as unit_price,
    CAST(quantity AS INTEGER) * CAST(unit_price AS DECIMAL(10,2)) as total_sale,
    
    -- Clasificación
    CASE 
        WHEN invoice_no LIKE 'C%' THEN 'RETURN'
        WHEN quantity > 0 THEN 'SALE'
        ELSE 'OTHER'
    END as transaction_type,
    
    -- Metadatos
    CURRENT_TIMESTAMP as processed_at
FROM bronze.raw_data
LEFT JOIN silver.product_master pm ON bronze.raw_data."StockCode" = pm.stock_code
WHERE [FILTROS ARRIBA];
```

---

#### 2.2 Inventory Adjustments (`silver_inventory_adjustments.sql`) - OPCIONAL

**Objetivo:** Tabla separada para análisis de mermas y control operacional.

**Incluye:**
- Ajustes de inventario (UnitPrice = 0)
- **Imputación de precio** usando precio promedio del producto
- Cálculo de pérdida real

**Estructura:**

```sql
CREATE TABLE silver.inventory_adjustments AS
WITH product_avg_price AS (
    SELECT 
        stock_code,
        AVG(unit_price) as avg_price,
        COUNT(*) as num_sales
    FROM silver.silver_cleaned_transactions
    WHERE unit_price > 0 AND quantity > 0
    GROUP BY stock_code
)
SELECT 
    ia.invoice_no,
    ia.invoice_date,
    ia.stock_code,
    ia.description,
    ia.quantity,
    ia.unit_price as recorded_price,
    
    -- Imputación de precio
    COALESCE(p.avg_price, 0) as imputed_price,
    ia.quantity * COALESCE(p.avg_price, 0) as estimated_loss,
    
    -- Clasificación de pérdida
    CASE 
        WHEN ia.description LIKE '%damage%' THEN 'DAMAGED'
        WHEN ia.description LIKE '%lost%' THEN 'LOST'
        WHEN ia.description LIKE '%Unsaleable%' THEN 'UNSALEABLE'
        WHEN ia.description LIKE '%thrown away%' THEN 'DISCARDED'
        ELSE 'OTHER'
    END as loss_category,
    
    -- Temporal
    EXTRACT(YEAR FROM ia.invoice_date) as year,
    EXTRACT(WEEK FROM ia.invoice_date) as week_number,
    
    CURRENT_TIMESTAMP as processed_at
FROM bronze.raw_data ia
LEFT JOIN product_avg_price p ON ia."StockCode" = p.stock_code
WHERE ia."UnitPrice" = 0 
  AND ia."CustomerID" IS NULL 
  AND ia."Quantity" < 0;
```

**Uso:** Análisis operacional, control de mermas, detección de anomalías (Six Sigma)

**Impacto:** Resuelve Problema 2 (imputación de costos reales a pérdidas)

---

#### 2.3 Accounting Adjustments (`silver_accounting_adjustments.sql`) - OPCIONAL

**Objetivo:** Tabla separada para ajustes contables (descuentos, envíos, ajustes manuales).

**Incluye:**
- Códigos especiales: M, D, POST, DOT, BANK CHARGES
- Análisis de descuentos por cliente
- Análisis de costos de envío por país

**Estructura:**

```sql
CREATE TABLE silver.accounting_adjustments AS
SELECT 
    invoice_no,
    STRPTIME(invoice_date, '%m/%d/%Y %H:%M') as invoice_date,
    stock_code,
    description,
    customer_id,
    country,
    CAST(quantity AS INTEGER) as quantity,
    CAST(unit_price AS DECIMAL(10,2)) as unit_price,
    CAST(quantity AS INTEGER) * CAST(unit_price AS DECIMAL(10,2)) as total_amount,
    
    -- Clasificación de ajuste
    CASE 
        WHEN stock_code = 'M' THEN 'MANUAL_ADJUSTMENT'
        WHEN stock_code = 'D' THEN 'DISCOUNT'
        WHEN stock_code = 'POST' THEN 'POSTAGE'
        WHEN stock_code = 'DOT' THEN 'DOTCOM_ADJUSTMENT'
        WHEN stock_code = 'BANK CHARGES' THEN 'BANK_CHARGES'
        ELSE 'OTHER'
    END as adjustment_type,
    
    CURRENT_TIMESTAMP as processed_at
FROM bronze.raw_data
WHERE stock_code IN ('M', 'D', 'POST', 'DOT', 'BANK CHARGES', 'C2', 'PADS', 'S', 'B')
   OR LENGTH(stock_code) = 1;
```

**Uso:** Análisis financiero, auditoría, reconciliación contable

**Impacto:** Resuelve Problema 3 (separación de códigos especiales)

---

### Fase 3: Validaciones y Data Quality

#### 3.1 Data Quality Checks

**Validaciones a implementar en dbt tests:**

```yaml
# models/silver/schema.yml
version: 2

models:
  - name: silver_cleaned_transactions
    description: "Transacciones limpias (ventas y devoluciones)"
    tests:
      - dbt_utils.row_count:
          compare_model: ref('bronze_raw_data')
          # Debe ser menor que Bronze (se excluyen registros)
    
    columns:
      - name: invoice_no
        tests:
          - not_null
          
      - name: stock_code
        tests:
          - not_null
          - relationships:
              to: ref('product_master')
              field: stock_code
      
      - name: transaction_type
        tests:
          - accepted_values:
              values: ['SALE', 'RETURN']
      
      - name: quantity
        tests:
          - not_null
          # Ventas: quantity > 0, Devoluciones: quantity < 0
      
      - name: unit_price
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "> 0"
      
      - name: total_sale
        tests:
          - not_null

  - name: product_master
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - stock_code
    
    columns:
      - name: stock_code
        tests:
          - unique
          - not_null
      
      - name: canonical_description
        tests:
          - not_null
```

---

#### 3.2 Métricas de Calidad

**Documentar en cada ejecución:**

```sql
-- Métricas de transformación Bronze → Silver
SELECT 
    'Bronze Total' as metric,
    COUNT(*) as value
FROM bronze.raw_data

UNION ALL

SELECT 
    'Silver Cleaned Transactions' as metric,
    COUNT(*) as value
FROM silver.silver_cleaned_transactions

UNION ALL

SELECT 
    'Inventory Adjustments' as metric,
    COUNT(*) as value
FROM silver.inventory_adjustments

UNION ALL

SELECT 
    'Accounting Adjustments' as metric,
    COUNT(*) as value
FROM silver.accounting_adjustments

UNION ALL

SELECT 
    'Records Excluded' as metric,
    (SELECT COUNT(*) FROM bronze.raw_data) - 
    (SELECT COUNT(*) FROM silver.silver_cleaned_transactions) -
    (SELECT COUNT(*) FROM silver.inventory_adjustments) -
    (SELECT COUNT(*) FROM silver.accounting_adjustments) as value;
```

---

## 📋 Checklist de Implementación

### Fase 1: Foundation
- [ ] Crear `silver_product_master.sql`
- [ ] Validar descripciones canónicas (sample de 100 productos)
- [ ] Documentar productos sin descripción válida

### Fase 2: Main Transformations
- [ ] Crear `silver_cleaned_transactions.sql`
- [ ] Crear `silver_inventory_adjustments.sql` (opcional)
- [ ] Crear `silver_accounting_adjustments.sql` (opcional)
- [ ] Implementar conversión de tipos de datos
- [ ] Implementar campos calculados

### Fase 3: Quality & Validation
- [ ] Implementar dbt tests en `schema.yml`
- [ ] Crear métricas de calidad
- [ ] Validar conteo de registros (Bronze vs Silver)
- [ ] Validar integridad referencial (product_master)
- [ ] Documentar registros excluidos

### Fase 4: Documentation
- [ ] Actualizar README con estructura Silver
- [ ] Documentar reglas de transformación
- [ ] Crear guía de uso de tablas Silver
- [ ] Documentar casos edge y decisiones de diseño

---

## 🎯 Decisiones de Diseño Pendientes

### 1. CustomerID NULL
**Pregunta:** ¿Qué hacer con transacciones sin CustomerID (24.93%)?

**Opciones:**
- **A)** Excluir completamente (solo análisis con clientes identificados)
- **B)** Incluir con `customer_id = 'UNKNOWN'` (análisis de ventas totales)
- **C)** Tabla separada `silver_anonymous_transactions`

**Recomendación:** Opción B - Incluir con NULL, permitir filtrado en Gold

---

### 2. Devoluciones (Returns)
**Pregunta:** ¿Cómo tratar las devoluciones en análisis de ventas?

**Opciones:**
- **A)** Incluir en tabla principal con `transaction_type = 'RETURN'`
- **B)** Tabla separada `silver_returns`
- **C)** Netear con ventas (ventas - devoluciones)

**Recomendación:** Opción A - Incluir en tabla principal, permitir análisis separado

---

### 3. Precios por País
**Pregunta:** ¿Normalizar precios a una moneda base?

**Opciones:**
- **A)** Mantener precios originales (£)
- **B)** Convertir a USD usando tipo de cambio histórico
- **C)** Agregar campo `price_usd` adicional

**Recomendación:** Opción A - Mantener original (todos son £), agregar conversión en Gold si necesario

---

## 📊 Impacto Esperado

### Reducción de Registros
```
Bronze Total:              541,909 (100%)
Silver Cleaned:           ~537,000 (99.1%)
Inventory Adjustments:      1,336 (0.25%)
Accounting Adjustments:     2,866 (0.53%)
Excluidos/Inválidos:         ~707 (0.13%)
```

### Mejoras de Calidad
- ✅ **100%** de productos con descripción normalizada
- ✅ **0%** de códigos especiales en tabla principal
- ✅ **0%** de ajustes de inventario en análisis de ventas
- ✅ **100%** de tipos de datos correctos
- ✅ **Imputación de costos** a ~38,000 unidades perdidas

---

## 🚀 Próximos Pasos

1. **Revisar y aprobar** esta estrategia
2. **Implementar** modelos dbt en orden:
   - `silver_product_master.sql`
   - `silver_cleaned_transactions.sql`
   - `silver_inventory_adjustments.sql` (opcional)
   - `silver_accounting_adjustments.sql` (opcional)
3. **Ejecutar** `dbt run --models silver.*`
4. **Validar** con `dbt test --models silver.*`
5. **Documentar** resultados y proceder a Gold

---

**Última actualización:** 2025-12-14  
**Estado:** 🟡 Pendiente de aprobación e implementación
