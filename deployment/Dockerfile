FROM python:3.11-slim

WORKDIR /app

COPY src/backend /app

RUN pip install flask flask_sqlalchemy pymysql

CMD ["python", "run.py"]
