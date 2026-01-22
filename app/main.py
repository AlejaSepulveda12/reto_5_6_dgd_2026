import pyodbc
import pandas as pd
import time
import os

# Credenciales
DB_HOST = os.getenv('DB_HOST', 'db')
DB_USER = os.getenv('DB_USER', 'sa')
DB_PASS = os.getenv('DB_PASS', 'TuPasswordFuerte123!')
DB_NAME = 'master'

def get_connection():
    conn_str = (
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={DB_HOST};"
        f"DATABASE={DB_NAME};"
        f"UID={DB_USER};"
        f"PWD={DB_PASS};"
        "TrustServerCertificate=yes;"
    )
    return pyodbc.connect(conn_str, autocommit=True)

def run_ingestion():
    print("--- 🚀 Iniciando Proceso ETL ---")
    
    # 1. Leer el CSV
    try:
        print("📂 Leyendo archivo CSV...")
        df = pd.read_csv('datos/train.csv')
        print(f"✅ CSV cargado. Filas encontradas: {len(df)}")
    except Exception as e:
        print(f"❌ Error leyendo el CSV: {e}")
        return

    # 2. Conectar a BD
    conn = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        print("✅ Conectado a SQL Server")
        
        # 3. Crear tabla (Borrarla si ya existe para evitar errores en pruebas)
        print("🛠  Creando tabla 'trips'...")
        cursor.execute("IF OBJECT_ID('trips', 'U') IS NOT NULL DROP TABLE trips")
        cursor.execute("""
            CREATE TABLE trips (
                id VARCHAR(50) PRIMARY KEY,
                vendor_id INT,
                pickup_datetime DATETIME,
                dropoff_datetime DATETIME,
                passenger_count INT,
                pickup_longitude FLOAT,
                pickup_latitude FLOAT,
                dropoff_longitude FLOAT,
                dropoff_latitude FLOAT,
                store_and_fwd_flag VARCHAR(5),
                trip_duration INT
            )
        """)
        
        # 4. Insertar datos
        print("📥 Insertando datos en SQL Server...")
        for index, row in df.iterrows():
            cursor.execute("""
                INSERT INTO trips (
                    id, vendor_id, pickup_datetime, dropoff_datetime, passenger_count,
                    pickup_longitude, pickup_latitude, dropoff_longitude, dropoff_latitude,
                    store_and_fwd_flag, trip_duration
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, 
            row.id, row.vendor_id, row.pickup_datetime, row.dropoff_datetime, row.passenger_count,
            row.pickup_longitude, row.pickup_latitude, row.dropoff_longitude, row.dropoff_latitude,
            row.store_and_fwd_flag, row.trip_duration
            )
        
        print(f"✨ ¡Éxito! Se insertaron {len(df)} registros.")

    except Exception as e:
        print(f"❌ Error en la base de datos: {e}")
    finally:
        if conn: conn.close()

if __name__ == "__main__":
    # Esperamos unos segundos extra para asegurar que SQL Server esté listo
    time.sleep(5)
    run_ingestion()