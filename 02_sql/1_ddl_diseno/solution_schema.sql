/*
RETO PARTE A: DISEÑO DEL ESQUEMA RELACIONAL 3NF
Estudiante: [Tu Nombre]
Fecha: [Fecha]
*/

-- =======================================================
-- 0. CREAR BASE DE DATOS
-- =======================================================
PRINT '=== RETO SQL ARCHITECT & TUNER ===';
PRINT 'LegacyRetail S.A. - Migración CSV a SQL Server 3NF';
PRINT '';

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'LegacyRetailDB')
BEGIN
    CREATE DATABASE LegacyRetailDB;
    PRINT '✓ Base de datos LegacyRetailDB creada.';
END
ELSE
BEGIN
    PRINT 'ℹ Base de datos LegacyRetailDB ya existe.';
END
GO

USE LegacyRetailDB;
GO

-- =======================================================
-- 1. LIMPIAR ESQUEMA EXISTENTE
-- =======================================================
PRINT '=== LIMPIANDO ESQUEMA EXISTENTE ===';

IF OBJECT_ID('Venta', 'U') IS NOT NULL DROP TABLE Venta;
IF OBJECT_ID('Producto', 'U') IS NOT NULL DROP TABLE Producto;
IF OBJECT_ID('Categoria', 'U') IS NOT NULL DROP TABLE Categoria;
IF OBJECT_ID('Sucursal', 'U') IS NOT NULL DROP TABLE Sucursal;
IF OBJECT_ID('Cliente', 'U') IS NOT NULL DROP TABLE Cliente;
IF OBJECT_ID('raw_sales_dump', 'U') IS NOT NULL DROP TABLE raw_sales_dump;
IF OBJECT_ID('dbo.NormalizarNombre', 'FN') IS NOT NULL DROP FUNCTION dbo.NormalizarNombre;
GO

-- =======================================================
-- 2. TABLAS MAESTRAS NORMALIZADAS (3NF)
-- =======================================================
PRINT '';
PRINT '=== CREANDO ESQUEMA 3NF ===';
PRINT 'Regla: Cada entidad en su tabla, sin redundancia de texto';

-- 2.1 Tabla Clientes
CREATE TABLE Cliente (
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(150) NOT NULL,
    Email VARCHAR(150) NOT NULL,
    Direccion VARCHAR(250) NULL
);
PRINT '✓ Tabla Cliente creada (PK: ClienteID)';

-- 2.2 Tabla Categorías
CREATE TABLE Categoria (
    CategoriaID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL UNIQUE
);
PRINT '✓ Tabla Categoria creada (PK: CategoriaID)';

-- 2.3 Tabla Sucursales
CREATE TABLE Sucursal (
    SucursalID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Ciudad VARCHAR(100) NOT NULL
);
PRINT '✓ Tabla Sucursal creada (PK: SucursalID)';

-- 2.4 Tabla Productos
CREATE TABLE Producto (
    ProductoID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(200) NOT NULL,
    Precio DECIMAL(10,2) NOT NULL,
    CategoriaID INT NOT NULL,
    CONSTRAINT FK_Producto_Categoria FOREIGN KEY (CategoriaID) 
        REFERENCES Categoria(CategoriaID)
);
PRINT '✓ Tabla Producto creada (PK: ProductoID, FK: CategoriaID)';
GO

-- =======================================================
-- 3. TABLA DE HECHOS (VENTAS)
-- =======================================================
CREATE TABLE Venta (
    VentaID INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATETIME NOT NULL,
    ClienteID INT NOT NULL,
    ProductoID INT NOT NULL,
    SucursalID INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    Total DECIMAL(12,2) NOT NULL,
    
    CONSTRAINT FK_Venta_Cliente FOREIGN KEY (ClienteID) 
        REFERENCES Cliente(ClienteID),
    CONSTRAINT FK_Venta_Producto FOREIGN KEY (ProductoID) 
        REFERENCES Producto(ProductoID),
    CONSTRAINT FK_Venta_Sucursal FOREIGN KEY (SucursalID) 
        REFERENCES Sucursal(SucursalID)
);
PRINT '✓ Tabla Venta creada (PK: VentaID, 3 FKs)';
GO

-- =======================================================
-- 4. FUNCIÓN PARA NORMALIZAR NOMBRES
-- =======================================================
PRINT '';
PRINT '=== CREANDO FUNCIÓN DE NORMALIZACIÓN ===';
GO

CREATE FUNCTION dbo.NormalizarNombre (@nombre VARCHAR(200))
RETURNS VARCHAR(200)
AS
BEGIN
    DECLARE @resultado VARCHAR(200) = LOWER(LTRIM(RTRIM(@nombre)));
    DECLARE @i INT = 1;
    DECLARE @len INT = LEN(@resultado);
    
    -- Primera letra en mayúscula
    IF @len > 0
        SET @resultado = UPPER(LEFT(@resultado, 1)) + SUBSTRING(@resultado, 2, @len);
    
    -- Letras después de espacio en mayúscula
    WHILE @i <= @len
    BEGIN
        IF SUBSTRING(@resultado, @i, 1) = ' '
            SET @resultado = STUFF(@resultado, @i + 1, 1, 
                UPPER(SUBSTRING(@resultado, @i + 1, 1)));
        SET @i = @i + 1;
    END
    
    RETURN @resultado;
END
GO

PRINT '✓ Función NormalizarNombre creada';
GO

-- =======================================================
-- 5. CARGA DEL CSV REAL
-- =======================================================
PRINT '';
PRINT '=== CARGA DEL CSV raw_sales_dump.csv ===';
PRINT 'Usando método directo para Linux...';
PRINT '';

-- 5.1 Crear tabla temporal
CREATE TABLE raw_sales_dump (
    Transaccion_ID INT,
    Cliente_Nombre VARCHAR(200),
    Cliente_Email VARCHAR(200),
    Producto VARCHAR(200),
    Categoria VARCHAR(100),
    Sucursal VARCHAR(100),
    Ciudad_Sucursal VARCHAR(100),
    Fecha_Venta DATE,
    Cantidad INT,
    Precio_Unitario DECIMAL(10,2)
);
PRINT '✓ Tabla temporal creada';
GO

-- 5.2 Cargar datos con método compatible Linux
PRINT 'Cargando datos...';
BEGIN TRY
    -- Método 1: BULK INSERT simple
    BULK INSERT raw_sales_dump
    FROM '/var/opt/mssql/data/raw_sales_dump.csv'
    WITH (
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        FIRSTROW = 2,
        FORMAT = 'CSV'
    );
    
    PRINT '✓ CSV cargado con BULK INSERT';
END TRY
BEGIN CATCH
    PRINT '⚠ Error BULK INSERT: ' + ERROR_MESSAGE();
    PRINT 'Intentando método alternativo...';
    
    -- Método 2: Usar formato más simple
    BULK INSERT raw_sales_dump
    FROM '/var/opt/mssql/data/raw_sales_dump.csv'
    WITH (
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        FIRSTROW = 2,
        FIELDQUOTE = '"'
    );
    
    PRINT '✓ CSV cargado con método alternativo';
END CATCH
GO

-- Verificar carga
DECLARE @TotalReg INT;
SELECT @TotalReg = COUNT(*) FROM raw_sales_dump;
PRINT 'Registros cargados: ' + ISNULL(CAST(@TotalReg AS VARCHAR), '0');

IF @TotalReg = 0 OR @TotalReg IS NULL
BEGIN
    PRINT '❌ ERROR: CSV no se cargó. Verificando acceso al archivo...';
    PRINT 'Por favor ejecuta estos comandos en terminal:';
    PRINT '1. docker exec sqlserver_reto ls -la /var/opt/mssql/data/raw_sales_dump.csv';
    PRINT '2. docker exec sqlserver_reto head -3 /var/opt/mssql/data/raw_sales_dump.csv';
    PRINT '3. docker cp "01_data/raw/raw_sales_dump.csv" sqlserver_reto:/var/opt/mssql/data/';
    RETURN;
END

PRINT '✓ CSV verificado: ' + CAST(@TotalReg AS VARCHAR) + ' registros';
GO

-- =======================================================
-- 6. MIGRACIÓN A ESQUEMA 3NF
-- =======================================================
PRINT '';
PRINT '=== NORMALIZACIÓN 3NF ===';
PRINT 'Eliminando redundancias...';

-- 6.1 Insertar Categorías únicas
PRINT '1. Categorías únicas...';
INSERT INTO Categoria (Nombre)
SELECT DISTINCT LTRIM(RTRIM(Categoria))
FROM raw_sales_dump
WHERE LTRIM(RTRIM(Categoria)) != '';
PRINT '   Encontradas: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

-- 6.2 Insertar Sucursales únicas
PRINT '2. Sucursales únicas...';
INSERT INTO Sucursal (Nombre, Ciudad)
SELECT DISTINCT
    LTRIM(RTRIM(Sucursal)),
    LTRIM(RTRIM(Ciudad_Sucursal))
FROM raw_sales_dump
WHERE LTRIM(RTRIM(Sucursal)) != '';
PRINT '   Encontradas: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

-- 6.3 Insertar Clientes únicos
PRINT '3. Clientes únicos...';
INSERT INTO Cliente (Nombre, Email)
SELECT DISTINCT
    dbo.NormalizarNombre(LTRIM(RTRIM(Cliente_Nombre))) AS Nombre,
    LOWER(LTRIM(RTRIM(Cliente_Email))) AS Email
FROM raw_sales_dump
WHERE LTRIM(RTRIM(Cliente_Email)) != '';
PRINT '   Encontrados: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

-- 6.4 Insertar Productos únicos
PRINT '4. Productos únicos...';
INSERT INTO Producto (Nombre, Precio, CategoriaID)
SELECT DISTINCT
    LTRIM(RTRIM(r.Producto)),
    AVG(r.Precio_Unitario),
    c.CategoriaID
FROM raw_sales_dump r
INNER JOIN Categoria c ON LTRIM(RTRIM(r.Categoria)) = c.Nombre
WHERE LTRIM(RTRIM(r.Producto)) != ''
GROUP BY LTRIM(RTRIM(r.Producto)), c.CategoriaID;
PRINT '   Encontrados: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

-- 6.5 Insertar Ventas
PRINT '5. Ventas normalizadas...';
INSERT INTO Venta (Fecha, ClienteID, ProductoID, SucursalID, Cantidad, PrecioUnitario, Total)
SELECT
    r.Fecha_Venta,
    c.ClienteID,
    p.ProductoID,
    s.SucursalID,
    r.Cantidad,
    r.Precio_Unitario,
    r.Cantidad * r.Precio_Unitario
FROM raw_sales_dump r
INNER JOIN Cliente c ON LOWER(LTRIM(RTRIM(r.Cliente_Email))) = c.Email
INNER JOIN Producto p ON LTRIM(RTRIM(r.Producto)) = p.Nombre
INNER JOIN Sucursal s ON LTRIM(RTRIM(r.Sucursal)) = s.Nombre;
PRINT '   Migradas: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

-- =======================================================
-- 7. DEMOSTRACIÓN DE LA SOLUCIÓN
-- =======================================================
PRINT '';
PRINT '=== DEMOSTRACIÓN: PROBLEMA RESUELTO ===';
PRINT '';

PRINT 'PROBLEMA ORIGINAL (CSV):';
PRINT 'Cliente "luisa fernanda" aparece como:';
SELECT 
    Cliente_Nombre AS 'Forma en CSV',
    COUNT(*) AS 'Registros',
    MIN(Transaccion_ID) AS 'Primer ID',
    MAX(Transaccion_ID) AS 'Último ID'
FROM raw_sales_dump
WHERE LOWER(LTRIM(RTRIM(Cliente_Email))) = 'luisa@f.com'
GROUP BY Cliente_Nombre;
GO

PRINT '';
PRINT 'SOLUCIÓN 3NF:';
PRINT 'En tabla Cliente normalizada:';
SELECT 
    c.ClienteID,
    c.Nombre AS 'Nombre normalizado',
    c.Email,
    COUNT(v.VentaID) AS 'Compras totales',
    SUM(v.Total) AS 'Total gastado'
FROM Cliente c
LEFT JOIN Venta v ON c.ClienteID = v.ClienteID
WHERE c.Email = 'luisa@f.com'
GROUP BY c.ClienteID, c.Nombre, c.Email;
GO

-- =======================================================
-- 8. RESUMEN FINAL
-- =======================================================
PRINT '';
PRINT '=== RESUMEN ESQUEMA 3NF ===';
PRINT '';

-- Usar tabla temporal para evitar subquery
CREATE TABLE #Resumen (
    Tabla VARCHAR(50),
    Registros INT,
    ClavePrincipal VARCHAR(50),
    ClavesForaneas VARCHAR(100)
);

INSERT INTO #Resumen VALUES ('Clientes', (SELECT COUNT(*) FROM Cliente), 'ClienteID', '');
INSERT INTO #Resumen VALUES ('Productos', (SELECT COUNT(*) FROM Producto), 'ProductoID', 'CategoriaID → Categoria');
INSERT INTO #Resumen VALUES ('Categorías', (SELECT COUNT(*) FROM Categoria), 'CategoriaID', '');
INSERT INTO #Resumen VALUES ('Sucursales', (SELECT COUNT(*) FROM Sucursal), 'SucursalID', '');
INSERT INTO #Resumen VALUES ('Ventas', (SELECT COUNT(*) FROM Venta), 'VentaID', 'ClienteID, ProductoID, SucursalID');

SELECT 
    Tabla,
    Registros,
    'PK: ' + ClavePrincipal + 
    CASE WHEN ClavesForaneas != '' THEN ', FK: ' + ClavesForaneas ELSE '' END AS 'Claves'
FROM #Resumen;

DROP TABLE #Resumen;
GO

PRINT '';
PRINT '=== RETO PARTE A COMPLETADO ===';
PRINT '✓ Esquema 3NF: 5 tablas normalizadas';
PRINT '✓ CSV real cargado';
PRINT '✓ Redundancia eliminada';
PRINT '✓ Integridad: 4 FOREIGN KEYS';
PRINT '';
GO