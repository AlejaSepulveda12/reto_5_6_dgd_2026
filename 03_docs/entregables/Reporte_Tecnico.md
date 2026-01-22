# 📊 REPORTE TÉCNICO
## Reto SQL Architect & Tuner Protocol
### Diplomado en Gestión de Datos 2026

**Estudiante:** Laura Alejandra Sepulveda 
**Fecha:** 23/01/2026 
**Empresa:** LegacyRetail S.A.  
**Rol:** Lead Data Engineer  

---

## 📋 RESUMEN EJECUTIVO

LegacyRetail S.A. enfrentaba colapso técnico por:
1. **Datos inconsistentes:** Clientes en múltiples formatos
2. **Caída de servidor:** `CROSS JOIN` mal implementado

**Soluciones implementadas:**
- **Normalización 3NF:** 5 tablas relacionales
- **Optimización performance:** `INNER JOIN` vs `CROSS JOIN`
- **Evidencias técnicas:** Logical Reads reducidos 85%

---

## 1. MISIÓN A: NORMALIZACIÓN 3NF

### 1.1 Problema Original
CSV `raw_sales_dump.csv` (200 registros) con:
- Redundancia extrema de texto
- "luisa fernanda" vs "LUISA FERNANDA"
- Dependencias transitivas

### 1.2 Diagrama Entidad-Relación

 Cliente          Producto          Sucursal
┌────────┐       ┌────────┐       ┌────────┐
│ClienteID│       │ProductoID│     │SucursalID│
│Nombre   │       │Nombre    │     │Nombre    │
│Email    │       │Precio    │     │Ciudad    │
└────┬────┘       │CategoriaID│    └────┬────┘
     │            └─────┬─────┘         │
     │                  │               │
     │            ┌─────┴───────────────┘
     └────────────┤       Venta
                  ├──────────────────┐
                  │VentaID           │
                  │Fecha             │
                  │ClienteID  (FK)   │
                  │ProductoID (FK)   │
                  │SucursalID (FK)   │
                  │Cantidad          │
                  │Total             │
                  └──────────────────┘
                          │
                          ▼
                  ┌─────────────┐
                  │  Categoria  │
                  ├─────────────┤
                  │CategoriaID  │
                  │Nombre       │
                  └─────────────┘


### 1.3 Resultados Normalización
**ANTES (CSV plano):**
- 200 registros redundantes
- Texto repetido miles de veces
- Inconsistencia en nombres

**DESPUÉS (Esquema 3NF):**


Tabla	Registros	PK	FK
Cliente	21	ClienteID	-
Producto	12	ProductoID	CategoriaID
Categoría	8	CategoriaID	-
Sucursal	5	SucursalID	-
Venta	213	VentaID	3 FKs


**Beneficios:**
- Texto no repetido
- "Luisa Fernanda" normalizada (1 forma)
- 4 FOREIGN KEYs para integridad
- Solo IDs en tabla de hechos

---

## 2. MISIÓN B: AUDITORÍA DE PERFORMANCE

### 2.1 El Error Crítico
```sql
-- CONSULTA QUE CAUSÓ LA CAÍDA (CROSS JOIN)
SELECT c.Nombre, p.Nombre
FROM Cliente c
CROSS JOIN Producto p;  -- Producto cartesiano
```

Fórmula del problema:

21 clientes × 12 productos = 252 combinaciones
VS
213 ventas reales = 213 combinaciones
→ 39 combinaciones INNECESARIAS

2.2 Métricas Técnicas - Logical Reads
CROSS JOIN (PELIGROSO)
```sql
Table 'Cliente'. Scan count 1, logical reads 25
Table 'Producto'. Scan count 1, logical reads 2
Total Logical Reads: 27
CPU time: 4 ms
Filas generadas: 252

INNER JOIN (OPTIMIZADO)

Table 'Venta'. Scan count 1, logical reads 4
Total Logical Reads: 4
CPU time: ~0 ms
Filas generadas: 213 (reales)
```

### 2.3 Comparativa Técnica
```sql
Métrica	CROSS JOIN	INNER JOIN	Mejora
Logical Reads	27	4	85% menos
Filas generadas	252	213	39 menos
Complejidad	O(n²)	O(n)	Lineal
CPU Time	4 ms	~0 ms	Optimizado
Escalabilidad	Pobre	Excelente	Preparado para crecimiento
```

### 2.4 Impacto en Producción

ESCENARIO REAL (estimado):
10,000 clientes × 5,000 productos = 50,000,000 combinaciones
VS
100,000 ventas reales

RESULTADO: 49,900,000 combinaciones INNECESARIAS
→ 100% CPU + Caída del servicio

## 3. EVIDENCIAS GRÁFICAS
### 3.1 Normalización Exitosa
(Incluir captura de pantalla: capturas/01_normalizacion.png)
Muestra: "luisa fernanda" normalizada a una sola forma

### 3.2 Logical Reads CROSS JOIN
(Incluir captura: capturas/02_cross_join_reads.png)
Muestra: logical reads 25 y logical reads 2

### 3.3 Logical Reads INNER JOIN
(Incluir captura: capturas/03_inner_join_reads.png)
Muestra: logical reads 4

### 3.4 Resumen Comparativo
(Incluir captura: capturas/04_resumen.png)
Muestra: Comparativa 27 vs 4 Logical Reads

## 4. CONCLUSIONES Y RECOMENDACIONES
*Logros Alcanzados*
Esquema 3NF implementado:

## 5 tablas normalizadas

Redundancia eliminada

Integridad con 4 FOREIGN KEYs

Performance optimizado:

85% reducción Logical Reads

CROSS JOIN vs INNER JOIN demostrado

Métricas cuantificadas

Problema resuelto:

"luisa fernanda" en una sola forma

Queries eficientes implementadas

Base para escalabilidad

📋 Recomendaciones para LegacyRetail
Capacitación obligatoria:

Normalización de bases de datos

Tipos de JOINs y su impacto

Interpretación de execution plans

Monitoreo proactivo:

Alertas automáticas para CROSS JOIN

Seguimiento de Logical Reads

Revisiones periódicas de performance

Mejoras técnicas:

Implementar índices estratégicos

Establecer políticas de code review

Crear entorno de pruebas de carga

## 6. ANEXOS TÉCNICOS
### 5.1 Scripts Entregados
solution_schema.sql: DDL completo del esquema 3NF
solution_tuning.sql: Comparativa performance JOINs

