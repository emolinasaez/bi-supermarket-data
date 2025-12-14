# 📊 Dashboard de BI - Retail Analytics RFM

## Información del Dashboard

**Proyecto:** Análisis RFM de Ventas de Retail  
**Autor:** Eduardo Molina Sáez  
**Última Actualización:** 2024

---

## 🎯 Objetivo del Dashboard

Proporcionar una vista ejecutiva de la segmentación de clientes basada en el modelo RFM (Recency, Frequency, Monetary), permitiendo a los equipos de marketing y ventas:

- Identificar clientes de alto valor
- Detectar clientes en riesgo de abandono
- Optimizar estrategias de retención y adquisición
- Medir el impacto de campañas de marketing

---

## 📈 Visualizaciones Principales

### 1. **Vista Ejecutiva**
- KPIs principales:
  - Total de clientes activos
  - Valor total de ventas
  - Ticket promedio
  - Tasa de retención
- Distribución de clientes por segmento (gráfico de barras)
- Evolución temporal de ventas (línea de tiempo)

### 2. **Análisis RFM**
- Matriz RFM (heatmap 5x5)
- Distribución de scores R, F, M (histogramas)
- Scatter plot: Frequency vs Monetary (coloreado por Recency)

### 3. **Segmentación de Clientes**
- Tabla de segmentos con métricas clave
- Gráfico de burbujas: Tamaño de segmento vs Valor
- Prioridades de acción (semáforo)

### 4. **Análisis de Comportamiento**
- Top 10 productos más vendidos
- Análisis geográfico (mapa de calor por país)
- Estacionalidad de ventas (por mes/día de semana)

### 5. **Análisis de Cancelaciones**
- Tasa de devolución por producto
- Clientes con más cancelaciones
- Impacto financiero de devoluciones

---

## 🔗 Acceso al Dashboard

### Tableau Public
**URL:** [Pendiente de publicación]

### Power BI
**URL:** [Pendiente de publicación]

---

## 📊 Fuentes de Datos

Los dashboards se conectan directamente a las tablas Gold de DuckDB:

```
dwh/retail_analytics.duckdb
├── gold.customer_rfm
└── gold.rfm_segments
```

### Configuración de Conexión

#### Para Tableau:
1. Usar conector "DuckDB" o "Other Databases (ODBC)"
2. Ruta del archivo: `D:\github_projects\bi-supermarket-data\dwh\retail_analytics.duckdb`
3. Esquema: `gold`

#### Para Power BI:
1. Obtener datos > Más > DuckDB
2. Ruta: `D:\github_projects\bi-supermarket-data\dwh\retail_analytics.duckdb`
3. Importar tablas: `gold_customer_rfm`, `gold_rfm_segments`

---

## 🎨 Paleta de Colores Recomendada

### Segmentos de Clientes
- **Champions:** `#2E7D32` (Verde oscuro)
- **Loyal Customers:** `#43A047` (Verde)
- **Potential Loyalists:** `#66BB6A` (Verde claro)
- **New Customers:** `#81C784` (Verde muy claro)
- **At Risk:** `#F57C00` (Naranja)
- **Cannot Lose Them:** `#D32F2F` (Rojo)
- **Hibernating:** `#757575` (Gris)
- **Lost:** `#424242` (Gris oscuro)

### Scores RFM
- **Score 5:** `#1B5E20` (Verde oscuro)
- **Score 4:** `#388E3C` (Verde)
- **Score 3:** `#FBC02D` (Amarillo)
- **Score 2:** `#F57C00` (Naranja)
- **Score 1:** `#C62828` (Rojo)

---

## 📋 Filtros Interactivos Sugeridos

- **Rango de fechas:** Selector de período
- **Segmento de cliente:** Dropdown multi-selección
- **País:** Dropdown
- **Score RFM:** Sliders (R, F, M)
- **Valor mínimo de compra:** Slider numérico

---

## 🔄 Actualización de Datos

### Frecuencia Recomendada
- **Producción:** Diaria (automatizada con Airflow/cron)
- **Desarrollo:** Manual según necesidad

### Proceso de Actualización
```bash
# 1. Ejecutar ingesta
python ingestion_polars.py

# 2. Ejecutar transformaciones dbt
cd dwh
dbt run

# 3. Refrescar dashboard en Tableau/Power BI
```

---

## 📝 Notas Técnicas

### Rendimiento
- Las tablas Gold están pre-agregadas para máximo rendimiento
- Se recomienda usar extractos (extracts) en lugar de conexión en vivo
- Considerar materialización incremental para datasets grandes

### Limitaciones
- Fecha de análisis fija: 2011-12-09 (configurable en dbt)
- Dataset histórico (no datos en tiempo real)
- Segmentación basada en quintiles (puede ajustarse)

---

## 📧 Contacto

Para preguntas sobre el dashboard o acceso a los archivos:

**Eduardo Molina Sáez**  
GitHub: [@emolinasaez](https://github.com/emolinasaez)

---

## 🚀 Próximos Pasos

- [ ] Publicar dashboard en Tableau Public
- [ ] Crear versión interactiva en Power BI Service
- [ ] Implementar alertas automáticas para segmentos críticos
- [ ] Agregar análisis predictivo (churn prediction)
- [ ] Integrar con herramientas de CRM

---

**Última actualización:** Diciembre 2024
