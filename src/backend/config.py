import os

USE_CONNECTOR = os.getenv('USE_CONNECTOR', 'false').lower() == 'true'

if USE_CONNECTOR:
    from google.cloud.sql.connector import Connector
    import sqlalchemy

    def getconn():
        connector = Connector()
        conn = connector.connect(
            'terraform-practice-250806:asia-east1:flask-db-instance',
            'pymysql',
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            db=os.getenv('DB_NAME'),
        )
        return conn

    SQLALCHEMY_DATABASE_URI = sqlalchemy.engine.url.URL.create(
        drivername='mysql+pymysql',
        query={"unix_socket": "/cloudsql/terraform-practice-250806:asia-east1:flask-db-instance"},
    )

else:
    DB_HOST = os.getenv('DB_HOST', '127.0.0.1')
    DB_USER = os.getenv('DB_USER')
    DB_PASSWORD = os.getenv('DB_PASSWORD')
    DB_NAME = os.getenv('DB_NAME')
    SQLALCHEMY_DATABASE_URI = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:3306/{DB_NAME}"
