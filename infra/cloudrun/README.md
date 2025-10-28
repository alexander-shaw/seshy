# Cloud Run Infrastructure

Terraform configuration for provisioning Google Cloud Run infrastructure.

## Resources Provisioned

- **Artifact Registry Repository** (`seshy`) - Docker registry for application images
- **Service Account** (`cloud-run-deployer`) - Service account with Cloud Run admin permissions
- **Cloud Run Service** (`seshy-api`) - Managed Cloud Run service for the API

## Prerequisites

1. Google Cloud SDK installed and configured
2. Terraform >= 1.5 installed
3. Appropriate GCP project permissions
4. Required APIs enabled:
   - Cloud Run API
   - Artifact Registry API
   - Service Usage API

## Usage

### Initialize Terraform

```bash
terraform init
```

### Plan Infrastructure Changes

```bash
terraform plan -var="project_id=YOUR_GCP_PROJECT"
```

### Apply Infrastructure

```bash
terraform apply -var="project_id=YOUR_GCP_PROJECT"
```

### Apply with Additional Variables

```bash
terraform apply \
  -var="project_id=YOUR_GCP_PROJECT" \
  -var="region=us-central1" \
  -var="min_instances=1" \
  -var="max_instances=10"
```

### Destroy Infrastructure

```bash
terraform destroy -var="project_id=YOUR_GCP_PROJECT"
```

## Variables

Key variables (see `variables.tf` for complete list):

- `project_id` (required) - GCP project ID
- `region` (default: `us-central1`) - GCP region
- `min_instances` (default: `0`) - Minimum Cloud Run instances
- `max_instances` (default: `10`) - Maximum Cloud Run instances
- `cpu` (default: `1`) - CPU allocation
- `memory` (default: `512Mi`) - Memory allocation

## Outputs

After applying, retrieve outputs with:

```bash
terraform output
```

Available outputs:
- `artifact_registry_repository_id` - Repository ID
- `cloud_run_service_url` - Service URL
- `deployer_service_account_email` - Deployment service account email
- `image_name` - Full Docker image name

## Deployment

Images can be pushed to Artifact Registry:

```bash
docker tag seshy-api:dev us-central1-docker.pkg.dev/YOUR_PROJECT/seshy/seshy-api:latest
docker push us-central1-docker.pkg.dev/YOUR_PROJECT/seshy/seshy-api:latest
```

Then update the Cloud Run service with:

```bash
gcloud run deploy seshy-api \
  --image=us-central1-docker.pkg.dev/YOUR_PROJECT/seshy/seshy-api:latest \
  --region=us-central1 \
  --platform=managed
```

## GitHub Actions

Infrastructure can also be managed via GitHub Actions workflow:
- Manual: `.github/workflows/terraform-apply.yml`
- Auto-deploy: `.github/workflows/deploy-api.yml`

## IAM Roles

The following roles are provisioned:
- `roles/run.admin` - Cloud Run admin (for deployer service account)
- `roles/artifactregistry.admin` - Artifact Registry admin (for deployer service account)
- `roles/run.invoker` - Cloud Run invoker (for specified members)

