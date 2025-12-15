# 🐍 Activación del Entorno Virtual

## Windows (PowerShell)
```powershell
.\venv\Scripts\Activate.ps1
```

## Windows (CMD)
```cmd
.\venv\Scripts\activate.bat
```

## Linux/Mac
```bash
source venv/bin/activate
```

---

## 📓 Usar el Notebook con el Entorno Virtual

### Opción 1: Cambiar Kernel en Jupyter (Recomendado)

1. Abre el notebook:
   ```bash
   jupyter notebook notebooks/data_quality_checks.ipynb
   ```

2. En el menú superior del notebook:
   - **Kernel → Change Kernel → Python (bi-supermarket)**

3. ¡Listo! Ahora el notebook usa el entorno virtual con todas las dependencias instaladas.

### Opción 2: Iniciar Jupyter desde el Entorno Virtual

```bash
# Activar el entorno
.\venv\Scripts\Activate.ps1

# Iniciar Jupyter
jupyter notebook notebooks/data_quality_checks.ipynb
```

---

## ✅ Verificar Instalación

Ejecuta en una celda del notebook:

```python
import sys
print(f"Python: {sys.executable}")
print(f"Version: {sys.version}")

import duckdb
import pandas as pd
import numpy as np
print("✅ Todas las dependencias instaladas correctamente")
```

---

## 📦 Paquetes Instalados

- ✅ `duckdb` - Base de datos
- ✅ `pandas` - Análisis de datos
- ✅ `numpy` - Operaciones numéricas
- ✅ `jupyter` - Entorno de notebooks
- ✅ `notebook` - Interfaz de Jupyter
- ✅ `ipykernel` - Kernel de Python para Jupyter

---

## 🔧 Instalar Dependencias Adicionales

Si necesitas instalar más paquetes del `requirements.txt`:

```bash
# Activar entorno
.\venv\Scripts\Activate.ps1

# Instalar dependencias adicionales
pip install polars python-dotenv dbt-core dbt-duckdb
```
