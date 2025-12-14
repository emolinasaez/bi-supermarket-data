# ============================================
# MAKEFILE - Retail Analytics Project
# ============================================
# Comandos simplificados para ejecutar el pipeline

.PHONY: help build up down shell clean ingestion dbt-deps dbt-run dbt-test dbt-docs pipeline

# Variables
DOCKER_COMPOSE = docker-compose
SERVICE = analytics

help: ## Mostrar ayuda
	@echo "Comandos disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Construir imagen Docker
	$(DOCKER_COMPOSE) build

up: ## Iniciar contenedor en background
	$(DOCKER_COMPOSE) up -d

down: ## Detener y remover contenedores
	$(DOCKER_COMPOSE) down

shell: ## Abrir shell interactivo en el contenedor
	$(DOCKER_COMPOSE) run --rm $(SERVICE) bash

clean: ## Limpiar volúmenes y contenedores
	$(DOCKER_COMPOSE) down -v
	docker system prune -f

# ============================================
# Pipeline de Datos
# ============================================

ingestion: ## Ejecutar ingesta de datos (Bronze)
	@echo "🥉 Ejecutando ingesta a capa Bronze..."
	$(DOCKER_COMPOSE) run --rm $(SERVICE) python ingestion_polars.py

dbt-deps: ## Instalar dependencias de dbt
	@echo "📦 Instalando dependencias de dbt..."
	$(DOCKER_COMPOSE) run --rm $(SERVICE) dbt deps --profiles-dir /app/dwh --project-dir /app/dwh

dbt-run: ## Ejecutar transformaciones dbt (Silver + Gold)
	@echo "🥈🥇 Ejecutando transformaciones dbt..."
	$(DOCKER_COMPOSE) run --rm $(SERVICE) dbt run --profiles-dir /app/dwh --project-dir /app/dwh

dbt-test: ## Ejecutar tests de calidad de datos
	@echo "🧪 Ejecutando tests de calidad..."
	$(DOCKER_COMPOSE) run --rm $(SERVICE) dbt test --profiles-dir /app/dwh --project-dir /app/dwh

dbt-docs: ## Generar y servir documentación dbt
	@echo "📚 Generando documentación..."
	$(DOCKER_COMPOSE) run --rm $(SERVICE) dbt docs generate --profiles-dir /app/dwh --project-dir /app/dwh
	@echo "🌐 Sirviendo documentación en http://localhost:8080"
	$(DOCKER_COMPOSE) run --rm -p 8080:8080 $(SERVICE) dbt docs serve --profiles-dir /app/dwh --project-dir /app/dwh --port 8080

pipeline: ingestion dbt-deps dbt-run dbt-test ## Ejecutar pipeline completo (ingesta + transformaciones + tests)
	@echo "✅ Pipeline completado exitosamente!"

# ============================================
# Desarrollo
# ============================================

logs: ## Ver logs del contenedor
	$(DOCKER_COMPOSE) logs -f $(SERVICE)

ps: ## Ver estado de contenedores
	$(DOCKER_COMPOSE) ps

restart: ## Reiniciar contenedores
	$(DOCKER_COMPOSE) restart

# ============================================
# Comandos rápidos
# ============================================

quick-start: build pipeline ## Build + Pipeline completo
	@echo "🚀 Proyecto iniciado y pipeline ejecutado!"

rebuild: clean build ## Limpiar y reconstruir desde cero
	@echo "🔄 Reconstrucción completa finalizada!"
