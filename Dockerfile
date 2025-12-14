# ============================================
# DOCKERFILE - Retail Analytics Project
# ============================================
# Multi-stage build para optimizar tamaño de imagen

FROM python:3.11-slim as builder

# Metadata
LABEL maintainer="Eduardo Molina Saez <emolinasaez@gmail.com>"
LABEL description="Retail Analytics - Medallion Architecture with RFM Analysis"

# Variables de entorno
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /app

# Copiar requirements y instalar dependencias Python
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# ============================================
# Imagen final
# ============================================
FROM python:3.11-slim

# Variables de entorno
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DBT_PROFILES_DIR=/app/dwh

# Instalar dependencias mínimas del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Crear usuario no-root para seguridad
RUN useradd -m -u 1000 analytics && \
    mkdir -p /app/logs /app/dwh && \
    chown -R analytics:analytics /app

# Copiar dependencias desde builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Establecer directorio de trabajo
WORKDIR /app

# Copiar código del proyecto
COPY --chown=analytics:analytics . .

# Cambiar a usuario no-root
USER analytics

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import duckdb; import polars; import dbt" || exit 1

# Comando por defecto
CMD ["bash"]
