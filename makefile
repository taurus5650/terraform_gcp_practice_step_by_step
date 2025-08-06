dev:
	docker-compose -f deployment/docker-compose-dev-local.yml --env-file .env up --build

tf-init:
	cd deployment/terraform && terraform init

tf-apply:
	cd deployment/terraform && terraform apply -auto-approve

# Dev
docker-compose -f deployment/docker-compose.dev.yml --env-file .env.dev up

# Prod Build
docker-compose -f deployment/docker-compose.prod.yml --env-file .env.prod build
