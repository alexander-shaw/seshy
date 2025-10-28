terraform {
  backend "gcs" {
    bucket = "seshy-terraform-state"
    prefix = "infra"
  }
}

# Create GCS bucket for Terraform state if it doesn't exist
resource "google_storage_bucket" "terraform_state" {
  name     = "seshy-terraform-state"
  location = var.region

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}

