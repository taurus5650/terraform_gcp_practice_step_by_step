provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "flask-repo"
  format        = "DOCKER"
}

resource "google_sql_database_instance" "instance" {
  name             = "flask-db-instance"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_network
    }
  }
}

resource "google_sql_database" "flaskdb" {
  name     = var.db_name
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "user" {
  name     = var.db_user
  instance = google_sql_database_instance.instance.name
  password = var.db_password
}

resource "google_cloud_run_service" "flask_service" {
  name     = "flask-api"
  location = var.region

  template {
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
          value = google_sql_database_instance.instance.connection_name
        }
      }
    }
  }

  traffics {
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
