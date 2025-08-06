DEPLOYMENT := deployment/
DOCKER_DEV := docker-compose-dev-local.yml
DOCKER_FILE := Dockerfile

GCP_PROJECT_ID := terraform-practice-250806
TF_DIR := $(DEPLOYMENT)/terraform
TF_REPO := terraform-practice-repo
ASIA_PKG := asia-east1-docker.pkg.dev
SQL_INSTANCE_NAME := flask-db-instance

IMAGE_NAME := terraform-practice-image
IMAGE_TAG := latest
IMAGE_URI := $(ASIA_PKG)/$(GCP_PROJECT_ID)/$(TF_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

run-dev-docker:
	docker compose -f $(DEPLOYMENT)$(DOCKER_DEV) down
	docker image prune -f
	docker compose -f $(DEPLOYMENT)$(DOCKER_DEV) up --build
	docker ps

run-docker-push-to-artifact-registry:
	gcloud auth configure-docker $(ASIA_PKG)
	docker build -f $(DEPLOYMENT)$(DOCKER_FILE) -t $(IMAGE_URI) .
	docker push $(IMAGE_URI)

print-image-uri:
	@echo "Image URI: $(IMAGE_URI)"

run-terraform-first-time-enable-tf:
	cd $(TF_DIR) && terraform init && terraform apply -auto-approve \
	-target=google_project_service.artifact_registry \
	-target=google_project_service.cloud_run \
	-target=google_project_service.sqladmin \
	-target=google_project_service.compute \
	-target=google_project_service.servicenetworking

run-terraform-init:
	cd $(TF_DIR) && terraform init

run-terraform-validate:
	cd $(TF_DIR) && terraform validate

run-terraform-fmt:
	cd $(TF_DIR) && terraform fmt -recursive

run-terraform-plan:
	cd $(TF_DIR) && terraform plan

run-terraform-import-all: # Telling GCP that Terraform will handle these GCP resources ; Accept error and keep running github action
	# Artifact Registry
	cd $(TF_DIR) && terraform import \
		google_artifact_registry_repository.repo \
		projects/$(GCP_PROJECT_ID)/locations/asia-east1/repositories/$(TF_REPO) || true

	# Private IP Allocation
	cd $(TF_DIR) && terraform import \
		google_compute_global_address.private_ip_alloc \
		projects/$(GCP_PROJECT_ID)/global/addresses/private-ip-allocation || true

	# Cloud SQL Instance
	cd $(TF_DIR) && terraform import \
		google_sql_database_instance.instance \
		projects/$(GCP_PROJECT_ID)/instances/$(SQL_INSTANCE_NAME) || true

	# Cloud SQL Database
	cd $(TF_DIR) && terraform import \
		google_sql_database.flask_db \
		projects/$(GCP_PROJECT_ID)/instances/$(SQL_INSTANCE_NAME)/databases/$(DB_NAME) || true

	# Cloud SQL User
	cd $(TF_DIR) && terraform import \
		google_sql_user.user \
		projects/$(GCP_PROJECT_ID)/instances/$(SQL_INSTANCE_NAME)/users/$(DB_USER) || true

	# Cloud Run Service
	cd $(TF_DIR) && terraform import \
		google_cloud_run_service.flask_service \
		projects/$(GCP_PROJECT_ID)/locations/asia-east1/services/flask-api || true

	# Cloud Run IAM Public Access
	cd $(TF_DIR) && terraform import \
		google_cloud_run_service_iam_member.public \
		projects/$(GCP_PROJECT_ID)/locations/asia-east1/services/flask-api/roles/run.invoker/allUsers || true

	# VPC Network
	cd $(TF_DIR) && terraform import \
		google_compute_network.vpc_network \
		projects/$(GCP_PROJECT_ID)/global/networks/main-vpc || true


run-terraform-apply:
	cd $(TF_DIR) && terraform apply -auto-approve -var="image_url=$(IMAGE_URI)" -var-file=terraform.tfvars

run-terraform-destroy:
	@echo "⚠️ Are you sure you want to destroy everything? Press Ctrl+C to cancel."
	sleep 10
	cd $(TF_DIR) && terraform destroy -auto-approve
