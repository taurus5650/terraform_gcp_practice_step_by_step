project_id    = "terraform-practice-250806"
region        = "asia-east1"
vpc_network = google_compute_network.vpc_network.id

db_user       = "flask"
db_password   = "supersecretpassword"
db_name       = "flask_db"

image_url     = "asia-east1-docker.pkg.dev/terraform-practice-250806/terraform-practice-repo/terraform-practice-image:latest"
