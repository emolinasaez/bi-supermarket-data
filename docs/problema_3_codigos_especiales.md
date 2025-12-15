## 🔴 Problema 3: Códigos Especiales (No son Productos)

### Descripción del Problema

El dataset contiene **StockCodes especiales** que NO representan productos reales, sino **ajustes contables**:

- **`M`** = Manual adjustments (Ajustes manuales)
- **`D`** = Discounts (Descuentos)
- **`POST`** = Postage (Envío/Porte)
- **`DOT`** = Dotcom adjustments
- **`BANK CHARGES`** = Cargos bancarios
- **Otros códigos de 1 letra:** `C2`, `PADS`, `S`

### Impacto
- **2,866 registros (0.53%)** son códigos especiales
- **539,043 registros (99.47%)** son productos reales

### Ejemplo Real Descubierto

**Caso: CustomerID 17940**

```
Factura C549452 (Cancelación con descuento):
- StockCode: D
- Description: "Discount"
- Quantity: -1
- UnitPrice: £1,867.86
- Total: -£1,867.86

Factura 549468 (Ajuste manual compensatorio):
- StockCode: M
- Description: "Manual"
- Quantity: 1
- UnitPrice: £1,867.86
- Total: +£1,867.86
```

**Patrón:** Se usa `D` para aplicar descuentos y `M` para ajustes manuales que compensan transacciones.

### Características de Códigos Especiales

| StockCode | Description | Uso | Precio Típico | Acción |
|-----------|-------------|-----|---------------|--------|
| **M** | Manual | Ajustes manuales | Variable (£0.22 - £842,900) | Excluir de análisis de productos |
| **D** | Discount | Descuentos | Variable | Excluir de análisis de productos |
| **POST** | Postage | Costos de envío | £15.00 - £550.94 | Excluir o analizar por separado |
| **DOT** | Dotcom | Ajustes ecommerce | Variable | Excluir |
| **BANK CHARGES** | Bank charges | Cargos bancarios | Variable | Excluir |

### 💡 Impacto en el Negocio

#### Si NO se excluyen:
1. ❌ **Análisis de productos contaminado** - Descuentos aparecen como "productos"
2. ❌ **Top productos incorrectos** - `M` con £842,900 aparecería como top producto
3. ❌ **Métricas de inventario erróneas** - No son productos físicos
4. ❌ **Análisis de categorías imposible** - No tienen categoría real

#### Si se excluyen correctamente:
1. ✅ **Análisis de productos limpio** - Solo productos reales
2. ✅ **Métricas confiables** - Revenue, quantity, etc.
3. ✅ **Posibilidad de análisis separado** - Descuentos, envíos, ajustes
4. ✅ **Dashboards profesionales** - Sin datos contaminados

### ✅ Solución Propuesta

#### 1. Identificar códigos especiales

```sql
-- Lista de códigos especiales conocidos
WHERE "StockCode" NOT IN ('M', 'D', 'POST', 'DOT', 'BANK CHARGES', 'C2', 'PADS', 'S')
  AND LENGTH("StockCode") > 1  -- Excluir códigos de 1 letra
```

#### 2. Crear tablas separadas en Silver

```sql
-- Tabla principal: Solo productos reales
CREATE TABLE silver.silver_cleaned_transactions AS
SELECT * FROM bronze.raw_data
WHERE "StockCode" NOT IN ('M', 'D', 'POST', 'DOT', 'BANK CHARGES', 'C2', 'PADS', 'S')
  AND LENGTH("StockCode") > 1
  AND transaction_type IN ('SALE', 'RETURN');

-- Tabla opcional: Ajustes contables
CREATE TABLE silver.accounting_adjustments AS
SELECT * FROM bronze.raw_data
WHERE "StockCode" IN ('M', 'D', 'POST', 'DOT', 'BANK CHARGES')
   OR LENGTH("StockCode") = 1;
```

#### 3. Análisis separado de descuentos y envíos (Opcional)

```sql
-- Análisis de descuentos por cliente
SELECT 
    "CustomerID",
    COUNT(*) as num_discounts,
    SUM("Quantity" * "UnitPrice") as total_discount_amount
FROM bronze.raw_data
WHERE "StockCode" = 'D'
GROUP BY "CustomerID";

-- Análisis de costos de envío
SELECT 
    "Country",
    COUNT(*) as num_shipments,
    AVG("UnitPrice") as avg_postage_cost
FROM bronze.raw_data
WHERE "StockCode" = 'POST'
GROUP BY "Country";
```

---

**NOTA:** Este contenido debe ser agregado a `data_quality_findings.md` como Problema 3, antes de la sección "Próximos Pasos".
