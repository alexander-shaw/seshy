locals {
  image_name = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repository_id}/${var.service_name}"
  service_name = "${var.service_name}-${var.environment}"
}

resource "google_cloud_run_v2_service" "api" {
  name     = local.service_name
  location = var.region

  template {
    service_account = var.service_account_email

    containers {
      image = local.image_name

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      ports {
        container_port = 8080
      }
    }

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    timeout        = "${var.timeout_seconds}s"
    execution_environment = "GEN_2"
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

resource "google_cloud_run_service_iam_binding" "public_access" {
  count    = var.allow_unauthenticated ? 1 : 0
  location = google_cloud_run_v2_service.api.location
  service  = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  members = [
    "allUsers",
  ]
}
