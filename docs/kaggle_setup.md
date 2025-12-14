# 📋 Configuración de Kaggle

Para usar la ingesta desde Kaggle, necesitas configurar tus credenciales:

## 1. Crear API Key en Kaggle

1. Ve a [https://www.kaggle.com/settings](https://www.kaggle.com/settings)
2. En la sección "API", haz clic en "Create New API Token"
3. Se descargará un archivo `kaggle.json`

## 2. Instalar el archivo de credenciales

### Windows
```powershell
# Crear directorio si no existe
mkdir $env:USERPROFILE\.kaggle

# Copiar el archivo kaggle.json
copy kaggle.json $env:USERPROFILE\.kaggle\kaggle.json
```

### Linux/Mac
```bash
# Crear directorio si no existe
mkdir -p ~/.kaggle

# Copiar el archivo kaggle.json
cp kaggle.json ~/.kaggle/kaggle.json

# Establecer permisos correctos
chmod 600 ~/.kaggle/kaggle.json
```

## 3. Verificar configuración

```bash
# Instalar kagglehub
pip install kagglehub[polars-datasets]

# Probar conexión
python -c "import kagglehub; print('Kaggle configurado correctamente!')"
```

## 4. Ejecutar ingesta

```bash
python ingestion_polars.py
```

O con Docker:

```bash
make ingestion
```

---

## Notas

- El archivo `kaggle.json` contiene tu username y API key
- **NO** subas este archivo a Git (ya está en `.gitignore`)
- Las credenciales se leen automáticamente desde `~/.kaggle/kaggle.json`
- No es necesario configurar variables de entorno adicionales
