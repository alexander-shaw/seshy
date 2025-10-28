resource "google_service_account" "cloud_run_deployer" {
  account_id   = "cloud-run-deployer-${var.environment}"
  display_name = "Cloud Run Deployer Service Account (${var.environment})"
  description  = "Service account for deploying Cloud Run services in ${var.environment}"
}

resource "google_project_iam_member" "cloud_run_deployer_admin" {
  for_each = toset([
    "roles/run.admin",
  ])
  
  project = var.project_id
  role    = each.value
  member  = format("serviceAccount:%s", google_service_account.cloud_run_deployer.email)
}

resource "google_project_iam_member" "cloud_run_deployer_artifact_registry_admin" {
  for_each = toset([
    "roles/artifactregistry.admin",
  ])
  
  project = var.project_id
  role    = each.value
  member  = format("serviceAccount:%s", google_service_account.cloud_run_deployer.email)
}

resource "google_project_iam_member" "deployment_admins" {
  for_each = toset(var.deployment_sa_members)
  
  project = var.project_id
  role    = "roles/run.admin"
  member  = each.value
}

resource "google_project_iam_member" "invokers" {
  for_each = toset(var.invoker_members)
  
  project = var.project_id
  role    = "roles/run.invoker"
  member  = each.value
}

resource "google_project_iam_member" "artifact_registry_admins" {
  for_each = toset(var.artifact_registry_admins)
  
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = each.value
}
