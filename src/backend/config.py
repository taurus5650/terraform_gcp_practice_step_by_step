import os
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

# Load env vars
USE_CONNECTOR = os.getenv('USE_CONNECTOR', 'false').lower() == 'true'
DB_USER = os.getenv('DB_USER', 'root')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'password')
DB_NAME = os.getenv('DB_NAME', 'flask_db')

# Default fallback
SQLALCHEMY_DATABASE_URI = ''
SQLALCHEMY_ENGINE_OPTIONS = {}

if USE_CONNECTOR:
    print('🟢 Using Cloud SQL Python Connector')
    from google.cloud.sql.connector import Connector
    connector = Connector()

    INSTANCE_CONNECTION_NAME = os.getenv(
        'INSTANCE_CONNECTION_NAME',
        'terraform-practice-250806:asia-east1:flask-db-instance'
    )

    def getconn():
        return connector.connect(
            INSTANCE_CONNECTION_NAME,
            "pymysql",
            user=DB_USER,
            password=DB_PASSWORD,
            db=DB_NAME,
        )

    SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://'
    SQLALCHEMY_ENGINE_OPTIONS = {"creator": getconn}

else:
    print('🟡 Using Cloud SQL Proxy')
    DB_HOST = os.getenv('DB_HOST', '127.0.0.1')
    DB_PORT = os.getenv('DB_PORT', '3306')
    SQLALCHEMY_DATABASE_URI = (
        f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )
    SQLALCHEMY_ENGINE_OPTIONS = {}

print(f'[DEBUG] USE_CONNECTOR: {USE_CONNECTOR}')
print(f'[DEBUG] SQLALCHEMY_DATABASE_URI: {SQLALCHEMY_DATABASE_URI}')
