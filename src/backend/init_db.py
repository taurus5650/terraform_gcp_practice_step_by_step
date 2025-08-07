from models import db, Order
from sqlalchemy import create_engine, text
import os

def init_db():
    db_user = os.getenv('DB_USER')
    db_pass = os.getenv('DB_PASSWORD')
    db_name = os.getenv('DB_NAME')
    db_host = os.getenv('DB_HOST')

    url = f"mysql+pymysql://{db_user}:{db_pass}@{db_host}/{db_name}"
    engine = create_engine(url)

    db.Model.metadata.create_all(engine)

    with engine.connect() as conn:
        result = conn.execute(text('SELECT COUNT(*) FROM `order`'))
        count = result.scalar()

        if count == 0:
            conn.execute(Order.__table__.insert(), [{"name": "Order A"}, {"name": "Order B"}])
            print("✅ Seed data inserted")

if __name__ == "__main__":
    init_db()
