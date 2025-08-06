FROM python:3.12-slim

ENV TZ=Asia/Taipei
ENV PYTHONUNBUFFERED=1

WORKDIR /flask-app

COPY requirement.txt ./
RUN pip install --upgrade pip
RUN pip install -r requirement.txt

# COPY all source code
COPY . .

RUN ls -la /flask-app/src/backend

EXPOSE 5000

CMD ["python", "src/backend/run.py"]
