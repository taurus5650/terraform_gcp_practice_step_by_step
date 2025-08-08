DEPLOYMENT := deployment/
DOCKER_DEV := docker-compose-dev-local.yml
DOCKER_FILE := Dockerfile

GCP_PROJECT_ID := terraform-practice-250806
TF_DIR := $(DEPLOYMENT)/terraform
TF_REPO := terraform-practice-repo
ASIA_PKG := asia-east1-docker.pkg.dev

SQL_INSTANCE_NAME := terraformprojectinstancedb
DB_NAME := terraformprojectdatabase
DB_USER := terraform_project

IMAGE_NAME := terraform-practice-image
IMAGE_TAG := latest
IMAGE_URI := $(ASIA_PKG)/$(GCP_PROJECT_ID)/$(TF_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

NETWORK_NAME := main-vpc-safer
PRIVATE_IP_RANGE_NAME = google-managed-services-$(NETWORK_NAME)

GCP_CREDENTIALS := $(realpath terraform-ci.json)
export-google-cred-json:
	export GOOGLE_APPLICATION_CREDENTIALS=$(GCP_CREDENTIALS)

run-dev-docker:
	docker compose -f $(DEPLOYMENT)$(DOCKER_DEV) down
	docker image prune -f
	docker compose -f $(DEPLOYMENT)$(DOCKER_DEV) up --build
	docker ps

run-terraform-first-time-enable-tf:
	cd $(TF_DIR) && terraform init && terraform apply -auto-approve \
	-target=google_project_service.artifact_registry \
	-target=google_project_service.cloud_run \
	-target=google_project_service.sqladmin \
	-target=google_project_service.compute \
	-target=google_project_service.servicenetworking \
	-target=google_project_service.enable_sql

print-image-uri:
	@echo "Image URI: $(IMAGE_URI)"

run-terraform-init:
	cd $(TF_DIR) && terraform init

run-terraform-validate:
	cd $(TF_DIR) && terraform validate

run-terraform-fmt:
	cd $(TF_DIR) && terraform fmt -recursive

run-terraform-plan:
	cd $(TF_DIR) && terraform plan -out=tfplan

run-docker-push-to-artifact-registry:
	gcloud auth configure-docker $(ASIA_PKG)
	docker build --platform=linux/amd64 -f $(DEPLOYMENT)$(DOCKER_FILE) -t $(IMAGE_URI) .
	docker push $(IMAGE_URI)

run-terraform-import-all: # Telling GCP that Terraform will handle these GCP resources ; Accept error and keep running github action
	# Artifact Registry
	cd $(TF_DIR) && terraform import \
		google_artifact_registry_repository.repo \
		projects/$(GCP_PROJECT_ID)/locations/asia-east1/repositories/$(TF_REPO) || true

	# VPC Network
	cd $(TF_DIR) && terraform import \
		'module.network.module.vpc.google_compute_network.network' \
		'projects/$(GCP_PROJECT_ID)/global/networks/$(NETWORK_NAME)' || true


	# Compute (PSA Global Address)
	cd $(TF_DIR) && terraform import \
	  'module.private_service_access.google_compute_global_address.google-managed-services-range' \
	  'projects/$(GCP_PROJECT_ID)/global/addresses/google-managed-services-$(NETWORK_NAME)' || true

	# Private Service Access
	cd $(TF_DIR) && terraform import \
		'module.private_service_access.google_compute_global_address.private_ip_address' \
		'projects/$(GCP_PROJECT_ID)/global/addresses/$(PRIVATE_IP_RANGE_NAME)' || true

	# Private VPC Connection
	cd $(TF_DIR) && terraform import \
	  'module.private_service_access.google_service_networking_connection.private_vpc_connection' \
	  'servicenetworking.googleapis.com:projects/$(GCP_PROJECT_ID)/global/networks/$(NETWORK_NAME)' || true

	# Cloud SQL Instance
	cd $(TF_DIR) && terraform import \
		'module.mysql.module.safer_mysql.google_sql_database_instance.default' \
		'projects/$(GCP_PROJECT_ID)/instances/$(SQL_INSTANCE_NAME)' || true
	cd $(TF_DIR) && terraform import \
	  'module.mysql.module.safer_mysql.google_sql_database.default[0]' \
	  projects/$(GCP_PROJECT_ID)/instances/$(SQL_INSTANCE_NAME)/databases/default

	# Cloud SQL Database (handwritten)
	cd $(TF_DIR) && terraform import \
	  google_sql_database.terraform_project_database \
	  projects/$(GCP_PROJECT_ID)/instances/$(SQL_INSTANCE_NAME)/databases/$(DB_NAME) || true

  	# Cloud SQL Database from module (default)
	cd $(TF_DIR) && terraform import \
	  'module.mysql.module.safer_mysql.google_sql_database.default[0]' \
	  projects/$(GCP_PROJECT_ID)/instances/$(SQL_INSTANCE_NAME)/databases/default || true

	# Cloud SQL User
	cd $(TF_DIR) && terraform import \
		google_sql_user.user \
		$(GCP_PROJECT_ID)/$(SQL_INSTANCE_NAME)/%/$(DB_USER) || true

	# Cloud Run Service
	cd $(TF_DIR) && terraform import \
		google_cloud_run_service.terraform_project_service \
		asia-east1/terraform-project-api || true

	# Cloud Run IAM Public Access
	cd $(TF_DIR) && terraform import \
		google_cloud_run_service_iam_member.public \
		"projects/$(GCP_PROJECT_ID)/locations/asia-east1/services/terraform-project-api roles/run.invoker allUsers" || true

run-terraform-apply:
	cd $(TF_DIR) && terraform apply -auto-approve -var="image_url=$(IMAGE_URI)" -var-file=terraform.tfvars\
	$(if $(LOCK),-lock=$(LOCK))

run-terraform-destroy:
	@echo "⚠️ Are you sure you want to destroy everything ? "
	@echo "⚠️ Press Ctrl+C to cancel."
	sleep 10
	cd $(TF_DIR) && terraform destroy -auto-approve

run-local-db-to-public:
	 gcloud sql instances describe terraformprojectinstancedb --format='value(connectionName)'
	 gcloud sql instances patch terraformprojectinstancedb --assign-ip
	 gcloud sql instances list
	gcloud run services describe terraform-project-api \
	  --region=asia-east1 \
	  --format='yaml(spec.template.metadata.annotations,spec.template.spec.containers[0].env,spec.template.spec.serviceAccount)'

check-gcp-log:
	 gcloud logging read \
	  'resource.type="cloud_run_revision" \
	   AND resource.labels.service_name="$(TF_SERVICE_NAME)" \
	   AND resource.labels.location="asia-east1"' \
	  --project=$(GCP_PROJECT_ID) \
	  --limit=1000 \
	  --format="value(textPayload)"