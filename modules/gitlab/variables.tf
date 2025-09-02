variable "cluster_endpoint" {
  description = "Endpoint for GKE master"
  type        = string
  sensitive   = true
}

variable "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64 encoded)"
  type        = string
  sensitive   = true
}

variable "gitlab_domain" {
  description = "Domain for GitLab instance (optional, will use LoadBalancer IP if not provided)"
  type        = string
}

variable "gitlab_storage_size" {
  description = "Storage size for GitLab persistent volumes"
  type        = string
}