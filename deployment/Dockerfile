FROM python:3.12-slim

ENV TZ=Asia/Taipei
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirement.txt ./
RUN pip install --upgrade pip
RUN pip install -r requirement.txt

# COPY all source code
COPY . .

RUN ls -la /app/src/backend

CMD ["python", "run.py"]
