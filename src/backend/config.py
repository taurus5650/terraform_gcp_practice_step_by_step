import os
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

# Common envs
DB_USER = os.getenv('DB_USER', 'terraform_project')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'supersecretpassword')
DB_NAME = os.getenv('DB_NAME', 'terraformprojectdatabase')

POOL_SIZE = int(os.getenv('DB_POOL_SIZE', '5'))
MAX_OVERFLOW = int(os.getenv('DB_MAX_OVERFLOW', '2'))
POOL_TIMEOUT = int(os.getenv('DB_POOL_TIMEOUT', '30'))  # seconds
POOL_RECYCLE = int(os.getenv('DB_POOL_RECYCLE', '1800'))  # seconds

# Fallbacks
SQLALCHEMY_DATABASE_URI = ''
SQLALCHEMY_ENGINE_OPTIONS = {
    "pool_size": POOL_SIZE,
    "max_overflow": MAX_OVERFLOW,
    "pool_timeout": POOL_TIMEOUT,
    "pool_recycle": POOL_RECYCLE,
    "pool_pre_ping": True,
}

# ----- explicit URI (best for Cloud Run) -----
explicit_uri = os.getenv('SQLALCHEMY_DATABASE_URI')
if explicit_uri:
    mode = "URI"
    SQLALCHEMY_DATABASE_URI = explicit_uri

else:
    # ----- Python Connector (opt-in) -----
    USE_CONNECTOR = os.getenv('USE_CONNECTOR', 'false').lower() == 'true'
    if USE_CONNECTOR:
        mode = 'CONNECTOR'
        print('🟢 Using Cloud SQL Python Connector')

        from google.cloud.sql.connector import Connector, IPTypes
        connector = Connector()

        INSTANCE_CONNECTION_NAME = os.getenv(
            'INSTANCE_CONNECTION_NAME',
            'terraform-practice-250806:asia-east1:terraformprojectinstancedb',
        )

        def getconn():
            return connector.connect(
                INSTANCE_CONNECTION_NAME,
                'pymysql',
                user=DB_USER,
                password=DB_PASSWORD,
                db=DB_NAME,
                ip_type=IPTypes.PUBLIC,
            )

        SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://'
        SQLALCHEMY_ENGINE_OPTIONS.update({"creator": getconn})

    else:
        # ----- Unix socket（Cloud Run） -----
        DB_HOST = os.getenv('DB_HOST', '')
        if DB_HOST.startswith('/cloudsql/'):
            mode = 'UNIX_SOCKET'
            print('🟢 Using Cloud SQL Unix socket')
            SQLALCHEMY_DATABASE_URI = (
                f'mysql+pymysql://{DB_USER}:{DB_PASSWORD}@/{DB_NAME}'
                f'?unix_socket={DB_HOST}'
            )
        else:
            # ----- TCP（dev/proxy） -----
            mode = 'TCP'
            print('🟡 Using TCP / Cloud SQL Proxy')
            DB_HOST = DB_HOST or os.getenv('DB_HOST', '127.0.0.1"')
            DB_PORT = os.getenv('DB_PORT', '3306')
            SQLALCHEMY_DATABASE_URI = (
                f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
            )

print(f'[DEBUG] DB Mode: {mode}')
print(f'[DEBUG] SQLALCHEMY_DATABASE_URI: {SQLALCHEMY_DATABASE_URI}')
