terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.31.0, < 7.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.31.0, < 7.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

module "network" {
  # 1. Build safer VPC（network module）
  source       = "terraform-google-modules/network/google"
  version      = "~> 11.0"
  project_id   = var.project_id
  network_name = "${var.network_name}-safer"
  subnets      = []
}

module "private_service_access" {
  # 2. Build Private Service Access（for Cloud SQL private IP）
  source  = "terraform-google-modules/sql-db/google//modules/private_service_access"
  version = "~> 26.0"

  project_id      = var.project_id
  vpc_network     = module.network.network_name
  deletion_policy = "ABANDON"

  depends_on = [module.network] # ✅ 加這行
}

module "mysql" {
  #3. Build Cloud SQL Instance
  source                    = "terraform-google-modules/sql-db/google//modules/safer_mysql"
  version                   = "~> 26.0"
  name                      = var.db_instance_name
  random_instance_name      = false
  project_id                = var.project_id
  region                    = var.region
  zone                      = var.zone
  tier                      = "db-f1-micro"
  database_version          = "MYSQL_8_0"
  deletion_protection       = false
  vpc_network               = module.network.network_self_link
  allocated_ip_range        = module.private_service_access.google_compute_global_address_name
  module_depends_on         = [module.private_service_access.peering_completed]

  additional_users = [
    {
      name            = var.db_user
      password        = var.db_password
      host            = "%"
      type            = "BUILT_IN"
      random_password = false
    }
  ]
}

data "google_service_account" "cloud_run_sa" {
  # Data: service account email
  account_id = "cloud-run-service-account"
}

resource "google_artifact_registry_repository" "repo" {
  # This repo will be used to push Docker images for Cloud Run deployment
  location = var.region
  repository_id = "terraform-practice-repo"
  format = "DOCKER"
}

resource "google_compute_global_address" "google-managed-services-range" {
  # Keep Private IP
  name          = "google-managed-services-${var.network_name}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = "projects/${var.project_id}/global/networks/${var.network_name}"
}

resource "google_service_networking_connection" "private_vpc_connection" {
  # Build VPC Peering
  network                 = "projects/${var.project_id}/global/networks/${var.network_name}"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.google-managed-services-range.name]
}

# resource "google_project_iam_member" "sa_cloudsql_access" {
#   project = var.project_id
#   role    = "roles/cloudsql.admin"
#   member  = "serviceAccount:${data.google_service_account.cloud_run_sa.email}"
# }

resource "google_project_iam_member" "cloudsql_client_binding" {
  # Cloud SQL client permission
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${data.google_service_account.cloud_run_sa.email}"
}

resource "google_sql_database" "terraform_project_database" {
  # Create a database inside the Cloud SQL
  name     = var.db_name
  instance = module.mysql.instance_name
}

resource "google_cloud_run_service" "terraform_project_service" {
  # Do Cloud Run
  name     = "terraform-project-api"
  location = var.region

  template {
    metadata {
      annotations = {
        "run.googleapis.com/cloudsql-instances" = module.mysql.instance_connection_name
        # "run.googleapis.com/cloudsql-instances" = "${var.project_id}:${var.region}:${module.mysql.instance_name}"
        "force-redeploy"                        = timestamp()
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
        # env {
        #   name  = "DB_HOST"
        #   value = "/cloudsql/${module.mysql.instance_connection_name}"
        #   # value = "/cloudsql/${var.project_id}:${var.region}:${module.mysql.instance_name}"
        # }
        # env {
        #   name  = "SQLALCHEMY_DATABASE_URI"
        #   value = "mysql+pymysql://${var.db_user}:${var.db_password}@/${var.db_name}?unix_socket=/cloudsql/${module.mysql.instance_connection_name}"
        # }
        env {
          name  = "USE_CONNECTOR"
          value = "true"
        }
        env {
          name  = "INSTANCE_CONNECTION_NAME"
          value = module.mysql.instance_connection_name
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
  service  = google_cloud_run_service.terraform_project_service.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
