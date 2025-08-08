output "cloud_run_url" {
  value = google_cloud_run_service.terraform_project_service.status[0].url
}

output "cloud_sql_instance_name" {
  value = module.mysql.instance_name
}