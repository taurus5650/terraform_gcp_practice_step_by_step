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

resource "google_project_service" "service_networking" {
  # Enable service networking api
  project = var.project_id
  service = "servicenetworking.googleapis.com"
}

resource "google_compute_network" "vpc_network" {
  name                    = "main-vpc"
  auto_create_subnetworks = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_global_address" "private_ip_alloc" {
  # Assign internal IP range to Cloud SQL
  name          = "private-ip-allocation"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_service_networking_connection" "private_vpc_connection" {
  # Create VPM peering connecting
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
  depends_on = [
    google_compute_global_address.private_ip_alloc,
    google_project_service.service_networking
  ]
}

resource "google_project_iam_member" "cloudsql_client_binding" {
  # Grant the SQL permmision to Cloud Run
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${data.google_service_account.cloud_run_sa.email}"
}

resource "google_sql_database_instance" "instance" {
  # Create a Cloud SQL instance running MySQL 8.0 in the specified region
  name              = "flask-db-instance"
  database_version  = "MYSQL_8_0"
  region            = var.region
  project           = var.project_id

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.vpc_network.id
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "flask_db" {
  # Create a database inside the Cloud SQL
  name     = var.db_name
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "user" {
  # Create a database USER to connect to Cloud SQL
  name = var.db_user
  password = var.db_password
  instance = google_sql_database_instance.instance.name
  project  = var.project_id
}


data "google_service_account" "cloud_run_sa" {
  # Create a service account for Cloud Run
  account_id   = "cloud-run-service-account"
}

resource "google_cloud_run_service" "flask_service" {
  # Deploy docker image to Cloud Run
  name     = "flask-api"
  location = var.region

  template {
    metadata {
      annotations = {
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.instance.connection_name
        "force-redeploy" = timestamp()
      }
    }

    spec {
      service_account_name = data.google_service_account.cloud_run_sa.email

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
          value = "/cloudsql/${google_sql_database_instance.instance.connection_name}"
        }

        env {
          name  = "INSTANCE_CONNECTION_NAME"
          value = google_sql_database_instance.instance.connection_name
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
