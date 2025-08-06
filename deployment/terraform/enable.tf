resource "google_project_service" "artifact_registry" {
  project              = var.project_id
  service              = "artifactregistry.googleapis.com"
  disable_on_destroy   = false
}

resource "google_project_service" "cloud_run" {
  project              = var.project_id
  service              = "run.googleapis.com"
  disable_on_destroy   = false
}

resource "google_project_service" "sqladmin" {
  project              = var.project_id
  service              = "sqladmin.googleapis.com"
  disable_on_destroy   = false
}

resource "google_project_service" "compute" {
  project              = var.project_id
  service              = "compute.googleapis.com"
  disable_on_destroy   = false
}

resource "google_project_service" "servicenetworking" {
  project              = var.project_id
  service              = "servicenetworking.googleapis.com"
  disable_on_destroy   = false
}
