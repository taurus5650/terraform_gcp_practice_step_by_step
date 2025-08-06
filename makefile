DEPLOYMENT = deployment/
DOCKER_DEV = docker-compose-dev-local.yml
DOCKER_FILE = Dockerfile

GCP_PROJECT_ID = terraform-practice-250806
TF_DIR = $(DEPLOYMENT)/terraform
TF_REPO = terraform-practice-repo
ASIA_PKG = asia-east1-docker.pkg.dev

IMAGE_NAME = terraform-practice-image
IMAGE_TAG = latest
IMAGE_URI = $(ASIA_PKG)/$(GCP_PROJECT_ID)/$(TF_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

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

run-terraform-init:
	cd $(TF_DIR) && terraform init

run-terraform-validate:
	cd $(TF_DIR) && terraform validate

run-terraform-fmt:
	cd $(TF_DIR) && terraform fmt -recursive

run-terraform-plan:
	cd $(TF_DIR) && terraform plan

run-terraform-apply:
	cd $(TF_DIR) && terraform apply -auto-approve -var-file=prod.tfvars

run-terraform-destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve
