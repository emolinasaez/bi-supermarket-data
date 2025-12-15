# 🔍 Data Quality Findings - Bronze Layer

> **Proyecto:** Retail Analytics - BI Supermarket Data  
> **Fecha de análisis:** 2025-12-14  
> **Capa analizada:** Bronze (raw_data)  
> **Analista:** EDA Notebook

---

## 📊 Resumen Ejecutivo

Durante el análisis exploratorio de la capa Bronze, se identificaron **3 problemas críticos de calidad de datos** que deben ser abordados en la transformación a Silver.

### Métricas Generales del Dataset
- **Total de registros:** 541,909
- **Período:** Diciembre 2010 - Septiembre 2011
- **Países:** 38 únicos (91.43% UK)
- **Clientes únicos:** 4,372
- **Productos únicos:** 4,070

### Problemas Críticos Identificados

#### 🔴 Problema 1: Descripciones Inconsistentes
- **Impacto:** 15.97% de productos (650 de 4,070)
- **Causa:** Notas operativas, NULL, comentarios humanos mezclados con nombres reales

#### 🔴 Problema 2: Ajustes de Inventario con Costo = 0
- **Impacto:** 1,336 registros (0.25%)
- **Crítico:** Pérdidas NO reportadas financieramente (£XX,XXX+ estimados)
- **Causa:** Mermas registradas con UnitPrice = 0

#### 🔴 Problema 3: Códigos Especiales (No Productos)
- **Impacto:** 2,866 registros (0.53%)
- **Códigos:** M, D, POST, DOT, BANK CHARGES
- **Causa:** Ajustes contables mezclados con productos reales

---

## 🔴 Problema 1: Descripciones Inconsistentes por StockCode

### Métricas del Problema Original
- **Total de StockCodes únicos:** 4,070
- **StockCodes con descripciones inconsistentes:** 650
- **Porcentaje afectado:** 15.97%
- **Máximo de variaciones por producto:** 8 descripciones diferentes

### Descripción del Problema
Un mismo `StockCode` puede tener múltiples valores diferentes en el campo `Description`, incluyendo:
- Valores NULL
- Notas operativas (`check`, `found`, `adjustment`)
- Notas de inventario (`damaged`, `wet/rusty`, `missing`)
- Comentarios humanos (`"alan hodge cant manage this section"`)
- Variaciones menores de formato (`"WRAP CAROUSEL"` vs `"WRAP, CAROUSEL"`)

### Ejemplos Concretos

#### Caso 1: StockCode `20713` (8 variaciones)
```
- "Found"
- "JUMBO BAG OWLS"
- "Marked as 23343"
- "found"
- ... (4 más)
```

#### Caso 2: StockCode `10080` (3 variaciones)
```
- "GROOVY CACTUS INFLATABLE" (22 transacciones) ✅ Descripción válida
- NULL (1 transacción)
- "check" (1 transacción)
```

#### Caso 3: StockCode `16162M` (3 variaciones)
```
- "THE KING GIFT BAG 25x24x12cm" (8 transacciones)
- "alan hodge cant mamage this section" (1 transacción) ⚠️ Nota humana
- NULL (1 transacción)
```

### Patrón Identificado
✅ **La descripción válida del producto suele tener la mayor frecuencia**  
❌ **Las notas operativas/inventario aparecen 1-2 veces (outliers)**

---

## 📋 Clasificación de Descripciones Problemáticas

| Tipo | Ejemplos | Frecuencia Típica | Acción |
|------|----------|-------------------|--------|
| **NULL** | `None` | 1-2 | Excluir |
| **Notas Operativas** | `check`, `found`, `adjustment`, `Amazon` | 1 | Excluir |
| **Notas de Inventario** | `damaged`, `wet/rusty`, `???missing` | 1 | Excluir |
| **Comentarios Humanos** | `"alan hodge cant manage..."` | 1 | Excluir |
| **Variaciones Menores** | Diferencias de puntuación/espacios | Variable | Normalizar |
| **Descripción Válida** | Nombre del producto en mayúsculas | Alta (>10) | **Conservar** |

---

## 💡 Impacto en el Negocio

### Riesgos si NO se corrige:
1. ❌ **Reportes inconsistentes:** El mismo producto aparece con nombres diferentes
2. ❌ **Análisis de productos erróneos:** Métricas fragmentadas por descripción
3. ❌ **Problemas en BI Dashboard:** Visualizaciones confusas para stakeholders
4. ❌ **Dificultad en análisis de ventas por producto**

### Beneficios al corregir:
1. ✅ **Fuente única de verdad** para nombres de productos
2. ✅ **Análisis de productos confiable**
3. ✅ **Dashboards limpios y profesionales**
4. ✅ **Base sólida para análisis avanzados** (market basket, product affinity)

---

## ✅ Solución Propuesta para Silver

### Estrategia de Limpieza

#### 1. Crear tabla `product_master` (lookup table)
Seleccionar **una descripción canónica** por cada `StockCode` usando estas reglas:

```sql
-- Prioridad de selección:
1. Excluir NULL
2. Excluir notas operativas: 'check', 'test', 'manual', 'found', 'adjustment', 'Amazon'
3. Excluir notas de inventario: 'damaged', 'wet/rusty', 'missing', '???'
4. Excluir descripciones muy cortas (< 3 caracteres)
5. Excluir descripciones con palabras clave: 'wrongly', 'marked', 'cant manage'
6. Seleccionar la descripción con MAYOR FRECUENCIA
7. En caso de empate, seleccionar la MÁS LARGA (más descriptiva)
```

#### 2. Aplicar normalización
- Trim de espacios
- Estandarizar puntuación
- Considerar fuzzy matching para variaciones menores

#### 3. Crear modelo dbt en Silver
```
models/silver/
├── silver_product_master.sql  # Tabla de referencia de productos
└── silver_cleaned_transactions.sql  # JOIN con product_master
```

---

## � Problema 2: Clasificación de Transacciones y Costo de Pérdidas

### Descripción del Problema

El dataset contiene **tres tipos de transacciones** que NO están claramente diferenciadas:

1. **Ventas Normales** (98.04% - 531,285 registros)
2. **Devoluciones** (1.71% - 9,288 registros)  
3. **Ajustes de Inventario/Pérdidas** (0.25% - 1,336 registros) ⚠️

### Características de Cada Tipo

| Tipo | InvoiceNo | Quantity | UnitPrice | CustomerID | Ejemplos Description |
|------|-----------|----------|-----------|------------|---------------------|
| **Ventas** | Sin 'C' | Positiva | > 0 | Presente | Nombres de productos |
| **Devoluciones** | Con 'C' | Negativa | > 0 | Presente | Nombres de productos |
| **Ajustes Inventario** | Sin 'C' | Negativa | **= 0** ❌ | **NULL** | "damages", "lost", "Breakages", "Unsaleable, destroyed" |

### 🚨 Problema Contable Crítico

**Los ajustes de inventario tienen `UnitPrice = 0.00`**, lo que causa:

#### Impacto Financiero
- ❌ **No se registra el costo real** de la mercancía perdida/dañada
- ❌ **Las ganancias están infladas** (no reflejan pérdidas reales)
- ❌ **Imposible calcular el impacto de la merma** en el negocio
- ❌ **Métricas de rentabilidad incorrectas**

#### Ejemplo Real del Dataset

```
InvoiceNo: 556690
StockCode: 23005
Description: "printing smudges/thrown away"
Quantity: -9,600 unidades
UnitPrice: £0.00  ❌
CustomerID: NULL

Problema: Si este producto se vende a £2.55, la pérdida real es:
9,600 × £2.55 = £24,480 NO REGISTRADOS
```

### Ejemplos de Ajustes de Inventario

```sql
InvoiceNo  | StockCode | Description                    | Quantity | UnitPrice
-----------|-----------|--------------------------------|----------|----------
556690     | 23005     | printing smudges/thrown away   | -9,600   | 0.00
556691     | 23005     | printing smudges/thrown away   | -9,600   | 0.00
556687     | 23003     | Printing smudges/thrown away   | -9,058   | 0.00
546152     | 72140F    | throw away                     | -5,368   | 0.00
573596     | 79323W    | Unsaleable, destroyed.         | -4,830   | 0.00
```

**Palabras clave identificadas:** `damages`, `lost`, `Breakages`, `Unsaleable`, `destroyed`, `thrown away`, `smudges`

### 🚨 Cuantificación del Impacto Financiero

**Análisis realizado:** Se calculó el costo real de las pérdidas usando el precio promedio de venta de cada producto.

```
Registros de merma: 1,336
Unidades perdidas: ~38,000+ unidades

IMPACTO FINANCIERO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pérdida registrada:    £0.00        ❌ (UnitPrice = 0)
Pérdida REAL estimada: £XX,XXX.XX   ⚠️ (usando precio promedio)
Pérdida NO reportada:  £XX,XXX.XX   🚨 CRÍTICO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Nota:** Ejecutar el análisis en el notebook `data_quality_checks.ipynb` para obtener los valores exactos.

**Metodología:**
```sql
-- Calcular precio promedio por producto
WITH product_avg_price AS (
    SELECT StockCode, AVG(UnitPrice) as avg_price
    FROM bronze.raw_data
    WHERE UnitPrice > 0 AND Quantity > 0
    GROUP BY StockCode
)
-- Aplicar a mermas
SELECT 
    SUM(Quantity * avg_price) as real_loss
FROM inventory_adjustments
JOIN product_avg_price USING (StockCode);
```

### 💡 Impacto en el Negocio

#### Si NO se corrige:
1. ❌ **Profit inflado** - No se descuenta el costo de pérdidas
2. ❌ **KPIs incorrectos** - Margen de ganancia, ROI, etc.
3. ❌ **Imposible analizar merma** - No hay datos de costo de pérdidas
4. ❌ **Decisiones de negocio erróneas** basadas en datos incorrectos

#### Si se corrige:
1. ✅ **Profit real** - Incluye costo de pérdidas
2. ✅ **Análisis de merma** - Identificar productos con más pérdidas
3. ✅ **KPIs confiables** - Métricas financieras correctas
4. ✅ **Decisiones informadas** - Reducir productos con alta merma

### ✅ Solución Propuesta

#### 1. Crear campo `transaction_type`

```sql
CASE 
    WHEN "InvoiceNo" LIKE 'C%' THEN 'RETURN'
    WHEN "UnitPrice" = 0 AND "CustomerID" IS NULL AND "Quantity" < 0 THEN 'INVENTORY_ADJUSTMENT'
    WHEN "Quantity" > 0 THEN 'SALE'
    ELSE 'OTHER'
END as transaction_type
```

#### 2. Filtrar transacciones para Silver

**Para análisis de ventas (tabla principal):**
```sql
WHERE transaction_type IN ('SALE', 'RETURN')  
-- Excluir ajustes de inventario
```

**Opcional - Tabla separada para análisis de merma:**
```sql
CREATE TABLE silver.inventory_adjustments AS
SELECT * FROM bronze.raw_data
WHERE transaction_type = 'INVENTORY_ADJUSTMENT';
```

#### 3. Imputar costo real a pérdidas (Opcional - Avanzado)

Si se desea calcular el impacto financiero real de las pérdidas:

```sql
-- Obtener precio promedio histórico del producto
WITH product_avg_price AS (
    SELECT 
        "StockCode",
        AVG("UnitPrice") as avg_price
    FROM bronze.raw_data
    WHERE "UnitPrice" > 0
    GROUP BY "StockCode"
)
-- Aplicar a ajustes de inventario
SELECT 
    a.*,
    COALESCE(a."UnitPrice", p.avg_price) as adjusted_unit_price,
    a."Quantity" * COALESCE(a."UnitPrice", p.avg_price) as adjusted_total_cost
FROM bronze.raw_data a
LEFT JOIN product_avg_price p ON a."StockCode" = p."StockCode"
WHERE transaction_type = 'INVENTORY_ADJUSTMENT';
```

---

## �📈 Próximos Pasos

- [ ] Continuar EDA en Bronze (otros campos: fechas, precios, países)
- [ ] Documentar otros hallazgos de calidad
- [ ] Diseñar e implementar `silver_product_master.sql`
- [ ] Actualizar `silver_cleaned_transactions.sql` para usar product_master
- [ ] Validar resultados en notebook de data quality checks

---

## 📎 Referencias

- **Notebook de análisis:** `notebooks/data_quality_checks.ipynb`
- **Tabla afectada:** `bronze.raw_data`
- **Campos involucrados:** `StockCode`, `Description`
- **Query de diagnóstico:** Ver sección "Identificar StockCodes con múltiples descripciones"

---

**Última actualización:** 2025-12-14  
**Estado:** 🟡 Identificado - Pendiente de implementación en Silver
