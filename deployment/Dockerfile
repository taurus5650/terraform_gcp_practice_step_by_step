FROM python:3.12-slim

ENV TZ=Asia/Taipei
ENV PYTHONUNBUFFERED=1

WORKDIR /terraform-gcp-practice-app

COPY requirement.txt ./
RUN pip install --upgrade pip
RUN pip install -r requirement.txt

# COPY all source code
COPY . .

RUN ls -la /terraform-gcp-practice-app/src/backend

EXPOSE 5000
# First time execute to build db table
CMD python src/backend/init_db.py && python src/backend/app.py
# CMD ["python", "src/backend/run.py"]
