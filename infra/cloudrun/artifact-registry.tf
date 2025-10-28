resource "google_artifact_registry_repository" "seshy" {
  location      = var.region
  repository_id = "${var.artifact_registry_repository_id}-${var.environment}"
  description   = "Docker repository for Seshy services (${var.environment})"
  format        = "DOCKER"
}
