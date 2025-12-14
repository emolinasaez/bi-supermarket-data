# Diccionario de Datos - Retail Analytics

## Capa Bronze

### bronze.raw_data

Datos crudos del dataset Online Retail sin transformaciones.

| Columna | Tipo | Descripción | Ejemplo |
|---------|------|-------------|---------|
| `InvoiceNo` | VARCHAR | Número de factura (6 dígitos). Si inicia con 'C', es cancelación | `536365`, `C536379` |
| `StockCode` | VARCHAR | Código único del producto | `85123A` |
| `Description` | VARCHAR | Nombre/descripción del producto | `WHITE HANGING HEART T-LIGHT HOLDER` |
| `Quantity` | INTEGER | Cantidad de unidades compradas | `6` |
| `InvoiceDate` | TIMESTAMP | Fecha y hora de la transacción | `2010-12-01 08:26:00` |
| `UnitPrice` | DECIMAL(10,2) | Precio unitario en libras esterlinas (£) | `2.55` |
| `CustomerID` | INTEGER | ID único del cliente | `17850` |
| `Country` | VARCHAR | País del cliente | `United Kingdom` |

**Fuente:** [UCI Machine Learning Repository - Online Retail Dataset](https://archive.ics.uci.edu/ml/datasets/Online+Retail)

**Período:** 01/12/2010 - 09/12/2011

**Registros:** ~541,909 transacciones

---

## Capa Silver

### silver.cleaned_transactions

Transacciones válidas después de limpieza y enriquecimiento.

| Columna | Tipo | Descripción | Reglas de Negocio |
|---------|------|-------------|-------------------|
| `transaction_id` | VARCHAR | Clave subrogada única | Hash de (InvoiceNo, StockCode, InvoiceDate) |
| `invoice_no` | VARCHAR | Número de factura | Excluye facturas con 'C' |
| `stock_code` | VARCHAR | Código del producto | - |
| `description` | VARCHAR | Descripción del producto | - |
| `quantity` | INTEGER | Cantidad comprada | > 0 |
| `invoice_date` | TIMESTAMP | Fecha/hora de transacción | - |
| `unit_price` | DECIMAL(10,2) | Precio unitario | > 0 |
| `customer_id` | INTEGER | ID del cliente | NOT NULL |
| `country` | VARCHAR | País del cliente | - |
| `total_sale` | DECIMAL(10,2) | **Calculado:** Quantity × UnitPrice | > 0 |
| `invoice_date_only` | DATE | Fecha sin hora | Truncado a día |
| `invoice_year` | INTEGER | Año de la factura | Extraído de invoice_date |
| `invoice_month` | INTEGER | Mes de la factura | 1-12 |
| `invoice_day` | INTEGER | Día del mes | 1-31 |
| `day_of_week` | VARCHAR | Día de la semana | Monday, Tuesday, etc. |
| `loaded_at` | TIMESTAMP | Timestamp de carga a Silver | CURRENT_TIMESTAMP |

**Filtros Aplicados:**
- ❌ Transacciones canceladas (InvoiceNo con 'C')
- ❌ Registros sin CustomerID
- ❌ Quantity ≤ 0
- ❌ UnitPrice ≤ 0

---

### silver.cancellation_log

Log de transacciones canceladas/devoluciones.

| Columna | Tipo | Descripción | Notas |
|---------|------|-------------|-------|
| `cancellation_id` | VARCHAR | Clave subrogada única | - |
| `invoice_no` | VARCHAR | Número de factura de cancelación | Inicia con 'C' |
| `original_invoice_no` | VARCHAR | Factura original (sin 'C') | Para cruce con transacciones |
| `stock_code` | VARCHAR | Código del producto devuelto | - |
| `description` | VARCHAR | Descripción del producto | - |
| `quantity` | INTEGER | Cantidad devuelta | Puede ser negativo |
| `cancellation_date` | TIMESTAMP | Fecha de la cancelación | - |
| `unit_price` | DECIMAL(10,2) | Precio unitario | - |
| `customer_id` | INTEGER | ID del cliente | - |
| `country` | VARCHAR | País del cliente | - |
| `cancellation_amount` | DECIMAL(10,2) | Valor de la devolución | Quantity × UnitPrice |
| `loaded_at` | TIMESTAMP | Timestamp de carga | - |

**Uso:** Análisis de tasa de devolución, productos problemáticos, comportamiento de cancelación.

---

## Capa Gold

### gold.customer_rfm

Métricas RFM calculadas por cliente.

| Columna | Tipo | Descripción | Cálculo |
|---------|------|-------------|---------|
| `customer_id` | INTEGER | ID único del cliente | - |
| `recency_days` | INTEGER | Días desde última compra | `analysis_date - MAX(invoice_date)` |
| `frequency` | INTEGER | Número de facturas únicas | `COUNT(DISTINCT invoice_no)` |
| `monetary_value` | DECIMAL(10,2) | Valor total gastado (£) | `SUM(total_sale)` |
| `total_items_purchased` | INTEGER | Total de líneas de productos | `COUNT(*)` |
| `avg_transaction_value` | DECIMAL(10,2) | Valor promedio por factura | `monetary_value / frequency` |
| `first_purchase_date` | DATE | Fecha de primera compra | `MIN(invoice_date)` |
| `last_purchase_date` | DATE | Fecha de última compra | `MAX(invoice_date)` |
| `customer_lifetime_days` | INTEGER | Días como cliente activo | `last_purchase_date - first_purchase_date` |
| `calculated_at` | TIMESTAMP | Timestamp de cálculo | CURRENT_TIMESTAMP |

**Fecha de Análisis:** 2011-12-09 (configurable en `dbt_project.yml`)

---

### gold.rfm_segments

Segmentación de clientes con scores RFM.

| Columna | Tipo | Descripción | Valores |
|---------|------|-------------|---------|
| `customer_id` | INTEGER | ID único del cliente | - |
| `recency_days` | INTEGER | Días desde última compra | - |
| `frequency` | INTEGER | Número de transacciones | - |
| `monetary_value` | DECIMAL(10,2) | Valor total gastado | - |
| `r_score` | INTEGER | Score de Recency | 1-5 (5=mejor) |
| `f_score` | INTEGER | Score de Frequency | 1-5 (5=mejor) |
| `m_score` | INTEGER | Score de Monetary | 1-5 (5=mejor) |
| `rfm_score` | VARCHAR(3) | Score combinado | Ej: '555', '111' |
| `rfm_score_numeric` | INTEGER | Score numérico ponderado | R×100 + F×10 + M |
| `customer_segment` | VARCHAR | Segmento de negocio | Ver tabla abajo |
| `action_priority` | INTEGER | Prioridad de acción | 1=Alta, 5=Baja |
| `avg_transaction_value` | DECIMAL(10,2) | Valor promedio por compra | - |
| `total_items_purchased` | INTEGER | Total de ítems | - |
| `customer_lifetime_days` | INTEGER | Días como cliente | - |
| `first_purchase_date` | DATE | Primera compra | - |
| `last_purchase_date` | DATE | Última compra | - |
| `segmented_at` | TIMESTAMP | Timestamp de segmentación | - |

---

## Segmentos de Clientes

| Segmento | Definición | Criterios RFM | Acción Recomendada |
|----------|------------|---------------|-------------------|
| **Champions** | Mejores clientes | R≥4, F≥4, M≥4 | Programas VIP, early access |
| **Loyal Customers** | Compran frecuentemente | R≥3, F≥4 | Upselling, cross-selling |
| **Potential Loyalists** | Clientes prometedores | R≥4, F=2-3 | Programas de fidelización |
| **New Customers** | Clientes recientes | R≥4, F≤2 | Onboarding, educación |
| **Promising** | Nuevos con buen gasto | R≥3, F≤2, M≥3 | Ofertas personalizadas |
| **Need Attention** | Requieren atención | R=3, F=3 | Engagement campaigns |
| **About to Sleep** | En riesgo de inactividad | R≤2, F=2-3 | Reactivación temprana |
| **At Risk** | Clientes valiosos en riesgo | R≤2, F≥4 | Win-back campaigns |
| **Cannot Lose Them** | Alto valor, casi perdidos | R≤1, F≥4, M≥4 | Retención agresiva |
| **Hibernating** | Inactivos | R≤2, F≤2 | Ofertas especiales |
| **Lost** | Clientes perdidos | R≤1, F≤2 | Reconquista o descarte |

---

## Notas Técnicas

### Cálculo de Scores RFM

Los scores se calculan usando **quintiles (NTILE)** sobre la distribución de cada métrica:

```sql
-- Recency: INVERTIDO (menor días = mejor)
NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score

-- Frequency: mayor es mejor
NTILE(5) OVER (ORDER BY frequency ASC) AS f_score

-- Monetary: mayor es mejor
NTILE(5) OVER (ORDER BY monetary_value ASC) AS m_score
```

### Interpretación de Scores

- **Score 5:** Top 20% (mejor)
- **Score 4:** 20-40%
- **Score 3:** 40-60%
- **Score 2:** 60-80%
- **Score 1:** Bottom 20% (peor)

---

## Referencias

- Dataset Original: [UCI ML Repository](https://archive.ics.uci.edu/ml/datasets/Online+Retail)
- Metodología RFM: [RFM Analysis Guide](https://www.putler.com/rfm-analysis/)
