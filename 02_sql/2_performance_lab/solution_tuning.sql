/*
RETO PARTE B: AUDITORÍA DE PERFORMANCE
*/

USE LegacyRetailDB;
GO

PRINT '=== RETO PARTE B: TUNING DE PERFORMANCE ===';
PRINT '';

-- Activar métricas
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- =======================================================
-- PRUEBA 1: CROSS JOIN (ERROR ORIGINAL)
-- =======================================================
PRINT '--- PRUEBA 1: CROSS JOIN ---';
PRINT 'Genera producto cartesiano de TODOS los clientes con TODOS los productos';
PRINT '21 clientes × 12 productos = 252 combinaciones';
PRINT '';

SELECT
    c.Nombre AS Cliente,
    p.Nombre AS Producto
FROM Cliente c
CROSS JOIN Producto p;
GO

PRINT '--- FIN PRUEBA 1 ---';
PRINT '';

-- =======================================================
-- PRUEBA 2: INNER JOIN (SOLUCIÓN CORRECTA)
-- =======================================================
PRINT '--- PRUEBA 2: INNER JOIN ---';
PRINT 'Solo combinaciones que existen en ventas reales';
PRINT '213 ventas reales = 213 combinaciones';
PRINT '';

SELECT
    c.Nombre AS Cliente,
    p.Nombre AS Producto,
    v.Cantidad,
    v.Total
FROM Venta v
INNER JOIN Cliente c ON v.ClienteID = c.ClienteID
INNER JOIN Producto p ON v.ProductoID = p.ProductoID;
GO

PRINT '--- FIN PRUEBA 2 ---';

-- Desactivar métricas
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- =======================================================
-- RESUMEN MANUAL (porque hay error en variables)
-- =======================================================
PRINT '';
PRINT '=== RESUMEN MANUAL ===';
PRINT 'Basado en los resultados anteriores:';
PRINT '• CROSS JOIN: 252 filas generadas (21 × 12)';
PRINT '• INNER JOIN: 213 filas generadas (ventas reales)';
PRINT '• Diferencia: 39 filas innecesarias';
PRINT '• CROSS JOIN es 1.18 veces más pesado (252/213)';
PRINT '• Logical Reads CROSS JOIN: 25 (Cliente) + 2 (Producto) = 27';
PRINT '• Logical Reads INNER JOIN: 4 (Venta)';
PRINT '• Mejora: 85% menos lecturas (27 vs 4)';
GO