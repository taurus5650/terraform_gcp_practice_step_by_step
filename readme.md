# Terraform & Google Cloud practice step by step

Here's the practice of Terraform (IaC) & Google Cloud with Python Flask.

## Operation

### Google Cloud - Create new project

https://console.cloud.google.com/welcome/new?authuser=1&pli=1&inv=1&invt=Ab4uGA

![new-project.png](readme/new-project.png)
![project-name.png](readme/project-name.png)

### Local Terminal - Install GCP related

``` commandline
$ brew install --cask google-cloud-sdk
$ brew install cloud-sql-proxy
```
### Local Terminal - Install Terraform
```commandline
$ brew tap hashicorp/tap
$ brew install hashicorp/tap/terraform
```

### Local Terminal - Setup GCP account token

``` commandline
# Export the environment value
$ export PROJECT_ID=YOUR_PROJECT_ID (e.g. export PROJECT_ID=terraform-practice-250806
$ export ACCOUNT_NAME=terraform-ci-account

# GCP sign in
$ gcloud auth login
$ gcloud config set project $PROJECT_ID

# Create Google service account
$ gcloud iam service-accounts create $ACCOUNT_NAME \
  --display-name="terreform-github-ci"

# Grant permission
$ gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/admin"

# CloudSql grant permission - admin
gcloud projects add-iam-policy-binding terraform-practice-250806 \
  --member="serviceAccount:terraform-ci-account@terraform-practice-250806.iam.gserviceaccount.com" \
  --role="roles/cloudsql.admin"
  
# CloudSql grant permission - client
gcloud projects add-iam-policy-binding terraform-practice-250806 \
  --member="serviceAccount:terraform-ci-account@terraform-practice-250806.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"
 
# Genarate token
$ gcloud iam service-accounts keys create terraform-ci.json \
  --iam-account=$ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com
```

How to get PROJECT_ID <br>
https://console.cloud.google.com/home/dashboard?authuser=1&inv=1&invt=Ab4uJg&project=terraform-practice-250806
![gcp-project-id.png](readme/gcp-project-id.png)

After execute all command line will get `terraform-ci.json`
![terraform-ci-json.png](readme/terraform-ci-json.png)

Double check IAM role <br>
https://console.cloud.google.com/iam-admin/iam?authuser=2&inv=1&invt=Ab4whg&project=terraform-practice-250806
![iam-role.png](readme/iam-role.png)

### Github - Setup Repository secrets
Repo → Settings → Secret and variables → Action → Repository secrets → New repository secret
- Name = GCP_CREDENTIALS
- Secret = {terraform-ci.json}

![github-action-secret.png](readme/github-action-secret.png)

### Google Cloud - Enable Google API

https://console.cloud.google.com/apis/library?authuser=2&hl=en-GB&inv=1&invt=Ab4w3g&project=terraform-practice-250806

- Service Usage API
![service-usage-api-enable.png](readme/service-usage-api-enable.png)

- Cloud Resource Manager API
![cloud-resource-manage-api-enable.png](readme/cloud-resource-manage-api-enable.png)

### Local Terminal - Enable Google API
Prepare `deployment/terraform/enable.tf` <br>
Execute command
``` commandline
$ make run-terraform-first-time-enable-tf
```
![enable-google-api.png](readme/enable-google-api.png)

Check the service <br>
https://console.cloud.google.com/apis/library?authuser=2&hl=en-GB&inv=1&invt=Ab4w3g&project=terraform-practice-250806

### Google Cloud - Edit DB to public IP (If needed, for dev mode)
Which for develop in LOCAL <br>
https://console.cloud.google.com/sql/instances?authuser=2&inv=1&invt=Ab4xXw&project=terraform-practice-250806
![db-public-ip-first-time.png](readme/db-public-ip-first-time.png)
or command
```commandline
# Get name
$ gcloud sql instances describe terraformprojectinstancedb --format='value(connectionName)'
# To public
$ gcloud sql instances patch terraformprojectinstancedb --assign-ip
# Get public address
$ gcloud sql instances list
```

### Repo - github action & terraform & makefile
1. Follow the repo's documentation
2. Developingggg
3. Push to master, started deployment automatically

### Get Started
Get domain <br>
https://console.cloud.google.com/run/detail/asia-east1/flask-api/metrics?authuser=2&inv=1&invt=Ab4xkg&project=terraform-practice-250806
![domain.png](readme/domain.png)
``` 
curl --location 'https://terraform-project-api-590276137919.asia-east1.run.app/'
```
![web-result.png](readme/web-result.png)



