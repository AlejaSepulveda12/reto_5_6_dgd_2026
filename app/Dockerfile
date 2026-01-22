FROM python:3.9-slim-bullseye

# 1. Instalar dependencias del sistema y el driver ODBC
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    unixodbc-dev \
    # Descargar llave GPG y añadirla (Método compatible con Debian 11)
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    # Añadir repositorio oficial de Microsoft para Debian 11
    && curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    # Instalar driver ODBC 17
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 \
    && apt-get clean

# 2. Configurar directorio de trabajo
WORKDIR /code

# 3. Copiar requirements e instalarlos
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copiar el código
COPY . .

# 5. Comando por defecto
# CMD ["python", "main.py"]