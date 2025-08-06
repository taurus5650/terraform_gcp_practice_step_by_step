from models import db, User
from sqlalchemy import create_engine
import os


def init_db():
    db_user = os.getenv('DB_USER')
    db_pass = os.getenv('DB_PASSWORD')
    db_name = os.getenv('DB_NAME')
    db_host = os.getenv('DB_HOST')

    url = f"mysql+pymysql://{db_user}:{db_pass}@{db_host}/{db_name}"
    engine = create_engine(url)
    db.metadata.create_all(engine)

    with engine.connect() as conn:
        result = conn.execute('SELECT COUNT(*) FROM order')
        if result.scalar() == 0:
            conn.execute(User.__table__.insert(), [{"name": "admin"}])
            print("✅ Seed data inserted")


if __name__ == "__main__":
    init_db()
