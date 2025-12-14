"""
Script de Ingesta de Datos - Capa Bronze
==========================================
Descarga y carga datos desde URL externa directamente a DuckDB
utilizando Polars para procesamiento eficiente.

Autor: Eduardo Molina Sáez
Fecha: 2024
"""

import os
import polars as pl
import duckdb
from dotenv import load_dotenv
from loguru import logger
import sys

# Configurar logging
logger.remove()
logger.add(sys.stderr, level="INFO")
logger.add("logs/ingestion.log", rotation="10 MB", retention="30 days", level="DEBUG")


class BronzeIngestion:
    """Clase para manejar la ingesta de datos a la capa Bronze."""
    
    def __init__(self):
        """Inicializar configuración desde variables de entorno."""
        load_dotenv()
        self.dataset_url = os.getenv("DATASET_URL")
        self.duckdb_path = os.getenv("DUCKDB_PATH", "dwh/retail_analytics.duckdb")
        
        logger.info("Configuración cargada exitosamente")
        logger.info(f"Dataset URL: {self.dataset_url}")
        logger.info(f"DuckDB Path: {self.duckdb_path}")
    
    def download_and_load_data(self):
        """
        Descarga datos desde URL y los carga directamente en DuckDB.
        No se almacena archivo local.
        """
        try:
            logger.info("Iniciando descarga de datos desde URL...")
            
            # Leer datos directamente desde URL usando Polars
            # Nota: Para Excel, Polars usa openpyxl internamente
            df = pl.read_excel(self.dataset_url)
            
            logger.info(f"Datos descargados exitosamente: {df.shape[0]} filas, {df.shape[1]} columnas")
            logger.info(f"Columnas: {df.columns}")
            
            # Mostrar primeras filas para validación
            logger.debug(f"Primeras 5 filas:\n{df.head()}")
            
            return df
            
        except Exception as e:
            logger.error(f"Error al descargar datos: {str(e)}")
            raise
    
    def load_to_duckdb(self, df: pl.DataFrame):
        """
        Carga el DataFrame de Polars a DuckDB en la tabla bronze_raw_data.
        
        Args:
            df: DataFrame de Polars con los datos crudos
        """
        try:
            logger.info("Conectando a DuckDB...")
            
            # Crear directorio si no existe
            os.makedirs(os.path.dirname(self.duckdb_path), exist_ok=True)
            
            # Conectar a DuckDB
            con = duckdb.connect(self.duckdb_path)
            
            # Crear esquema bronze si no existe
            con.execute("CREATE SCHEMA IF NOT EXISTS bronze")
            
            # Eliminar tabla si existe (para recargas completas)
            con.execute("DROP TABLE IF EXISTS bronze.raw_data")
            
            # Cargar datos desde Polars a DuckDB
            # DuckDB puede leer directamente desde Polars DataFrames
            con.execute("CREATE TABLE bronze.raw_data AS SELECT * FROM df")
            
            # Validar carga
            row_count = con.execute("SELECT COUNT(*) FROM bronze.raw_data").fetchone()[0]
            logger.info(f"Datos cargados exitosamente a bronze.raw_data: {row_count} filas")
            
            # Mostrar estadísticas básicas
            stats = con.execute("""
                SELECT 
                    COUNT(*) as total_rows,
                    COUNT(DISTINCT "CustomerID") as unique_customers,
                    COUNT(DISTINCT "InvoiceNo") as unique_invoices,
                    MIN("InvoiceDate") as min_date,
                    MAX("InvoiceDate") as max_date
                FROM bronze.raw_data
            """).fetchone()
            
            logger.info(f"Estadísticas de carga:")
            logger.info(f"  - Total de filas: {stats[0]}")
            logger.info(f"  - Clientes únicos: {stats[1]}")
            logger.info(f"  - Facturas únicas: {stats[2]}")
            logger.info(f"  - Rango de fechas: {stats[3]} a {stats[4]}")
            
            con.close()
            logger.info("Conexión a DuckDB cerrada")
            
        except Exception as e:
            logger.error(f"Error al cargar datos a DuckDB: {str(e)}")
            raise
    
    def run(self):
        """Ejecutar el pipeline completo de ingesta."""
        logger.info("=" * 60)
        logger.info("INICIANDO PIPELINE DE INGESTA - CAPA BRONZE")
        logger.info("=" * 60)
        
        try:
            # Paso 1: Descargar datos
            df = self.download_and_load_data()
            
            # Paso 2: Cargar a DuckDB
            self.load_to_duckdb(df)
            
            logger.info("=" * 60)
            logger.info("PIPELINE DE INGESTA COMPLETADO EXITOSAMENTE")
            logger.info("=" * 60)
            
        except Exception as e:
            logger.error("=" * 60)
            logger.error(f"PIPELINE DE INGESTA FALLÓ: {str(e)}")
            logger.error("=" * 60)
            raise


if __name__ == "__main__":
    # Crear directorio de logs si no existe
    os.makedirs("logs", exist_ok=True)
    
    # Ejecutar ingesta
    ingestion = BronzeIngestion()
    ingestion.run()
