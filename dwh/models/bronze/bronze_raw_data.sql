{{
    config(
        materialized='view',
        schema='bronze',
        tags=['bronze', 'raw']
    )
}}

/*
    Capa Bronze - Vista de Datos Crudos
    ====================================
    Vista sobre la tabla raw_data cargada por el script de ingesta Polars.
    No se aplican transformaciones, solo se expone la data cruda.
    
    Columnas esperadas del dataset Online Retail:
    - InvoiceNo: Número de factura
    - StockCode: Código del producto
    - Description: Descripción del producto
    - Quantity: Cantidad comprada
    - InvoiceDate: Fecha y hora de la transacción
    - UnitPrice: Precio unitario
    - CustomerID: ID del cliente
    - Country: País del cliente
*/

SELECT
    "InvoiceNo",
    "StockCode",
    "Description",
    "Quantity",
    "InvoiceDate",
    "UnitPrice",
    "CustomerID",
    "Country"
FROM bronze.raw_data
