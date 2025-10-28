terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    # Bucket name will be provided via backend config block
    # e.g., terraform init -backend-config="bucket=seshy-terraform-state"
    prefix = "cloudrun"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
