import os

IS_CLOUD_RUN = os.getenv("K_SERVICE") is not None  # Cloud Run

if IS_CLOUD_RUN:
    DB_HOST = os.getenv('DB_HOST', f"/cloudsql/{os.getenv('INSTANCE_CONNECTION_NAME')}")
else:
    DB_HOST = os.getenv('DB_HOST', 'cloudsql-proxy')  # Local Dev

DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_NAME = os.getenv('DB_NAME')

SQLALCHEMY_DATABASE_URI = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"
