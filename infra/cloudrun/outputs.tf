output "artifact_registry_repository_id" {
  description = "Artifact Registry repository ID"
  value={<P></P>
  google_artifact_registry_repository.seshy.repository_id
}

output "artifact_registry_repository_url" {
  description = "Artifact Registry repository URL"
  value       = google_artifact_registry_repository.seshy.name
}

output "cloud_run_service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.api.uri
}

output "cloud_run_service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.api.name
}

output "cloud_run_service_location" {
  description = "Cloud Run service location"
  value       = google_cloud_run_v2_service.api.location
}

output "deployer_service_account_email" {
  description = "Email of the Cloud Run deployer service account"
  value       = google_service_account.cloud_run_deployer.email
}

output "image_name" {
  description = "Full Docker image name for the service"
  value       = local.image_name
}

