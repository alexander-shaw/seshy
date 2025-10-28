variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
  default     = "staging"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "terraform_state_bucket" {
  description = "GCS bucket for Terraform state"
  type        = string
}

variable "artifact_registry_repository_id" {
  description = "The Artifact Registry repository ID"
  type        = string
  default     = "seshy"
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "seshy-api"
}

variable "service_account_email" {
  description = "Email of the service account to run the Cloud Run service"
  type        = string
  default     = null
}

variable "min_instances" {
  description = "Minimum number of Cloud Run instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 10
}

variable "cpu" {
  description = "CPU allocation for Cloud Run instances"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory allocation for Cloud Run instances"
  type        = string
  default     = "512Mi"
}

variable "timeout_seconds" {
  description = "Request timeout in seconds"
  type        = number
  default     = 300
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated invocations"
  type        = bool
  default     = true
}

variable "deployment_sa_members" {
  description = "List of members to grant Cloud Run admin permissions"
  type        = list(string)
  default     = []
}

variable "invoker_members" {
  description = "List of members to grant Cloud Run invoker permissions"
  type        = list(string)
  default     = []
}

variable "artifact_registry_admins" {
  description = "List of members to grant Artifact Registry admin permissions"
  type        = list(string)
  default     = []
}
