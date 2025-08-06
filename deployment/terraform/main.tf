terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.13.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.13.0"
    }
  }
}
provider "google" {
  project = var.project_id
  region = var.region
}

resource "google_artifact_registry_repository" "repo" {
  # This repo will be used to push Docker images for Cloud Run deployment
  location = var.region
  repository_id = "terraform-practice-repo"
  format = "DOCKER"
}

resource "google_sql_database_instance" "instance" {
  # Create a Cloud SQL instance running MySQL 8.0 in the specified region
  name = "flask-db-instance"
  database_version = "MYSQL_8_0"
  region = var.region

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = false
      private_network = var.vpc_network
    }
  }
}

resource "google_sql_database" "flask_db" {
  # Create a database inside the Cloud SQL
  name     = var.db_name
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "user" {
  # Create a database USER to connect to Cloud SQL
  name = var.db_user
  instance = google_sql_database_instance.instance.name
  password = var.db_password
}

resource "google_cloud_run_service" "flask_service" {
  # Deploy Docker image to Cloud Run.
  name     = "flask-api"
  location = var.region

  template {
    metadata {
      annotations = {
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.instance.connection_name
      }
    }

    spec {
      containers {
        image = var.image_url

        ports {
          container_port = 5000
        }

        env {
          name  = "DB_USER"
          value = var.db_user
        }
        env {
          name  = "DB_PASSWORD"
          value = var.db_password
        }
        env {
          name  = "DB_NAME"
          value = var.db_name
        }
        env {
          name  = "DB_HOST"
          # Cloud SQL use unix socket
          value = "/cloudsql/${google_sql_database_instance.instance.connection_name}"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}

resource "google_cloud_run_service_iam_member" "public" {
  service = google_cloud_run_service.flask_service.name
  location = var.region
  role    = "roles/run.invoker"
  member  = "allUsers"
}




