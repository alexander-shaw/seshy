# Infrastructure

Infrastructure as Code, managed with Terraform.

## What Was Built

### Cloud Run Infrastructure (`infra/cloudrun/`)
Terraform configuration for Google Cloud Run services.

**What:**
- Artifact Registry repository for Docker images
- Service accounts with IAM bindings
- Cloud Run services with environment isolation
- GCS backend for Terraform state

**Why:**
- Infrastructure as Code ensures reproducible deployments
- Separate staging/production environments prevent accidents
- Service accounts follow least-privilege security model
- Centralized Terraform state enables team collaboration

**Benefits:**
- Version-controlled infrastructure changes
- Safe manual deployments via Terraform
- Automatic environment isolation (different service accounts per env)
- State locking prevents concurrent modification conflicts

**Tradeoffs:**
- Requires Terraform knowledge
- GCS bucket for state adds some setup complexity
- Manual `terraform apply` needed for non-code changes
- State file needs to be protected (versioned in GCS)

### Key Decisions

**Multi-environment support:**
- `environment` variable creates separate resources per env
- Staging deployed from `develop` branch
- Production deployed from `main` branch

**Workload Identity Federation (WIF):**
- Replaces service account JSON keys (more secure)
- Requires GCP setup but eliminates secret rotation
- Better for CI/CD pipelines

**Docker image caching:**
- GitHub Actions caches buildx layers
- Faster builds on repeated runs
- Reduces network transfer

## Getting Started

### Initial Setup

```bash
cd infra/cloudrun

# Create GCS bucket for Terraform state
gsutil mb -p YOUR_PROJECT gs://YOUR_PROJECT-terraform-state

# Initialize Terraform
terraform init \
  -backend-config="bucket=YOUR_PROJECT-terraform-state" \
  -backend-config="prefix=cloudrun/staging"

# Apply infrastructure
terraform apply \
  -var="project_id=YOUR_PROJECT" \
  -var="region=us-central1" \
  -var="environment=staging"
```

### Deploying

Infrastructure deploys automatically via GitHub Actions when code is pushed.

See `.github/workflows/deploy-api.yml` for CI/CD pipeline.

Manual deployments via `infra/cloudrun/README.md`.
