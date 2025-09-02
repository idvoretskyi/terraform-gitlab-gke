variable "region" {
  description = "GCP region (fallback if not set in gcloud config)"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP zone (fallback if not set in gcloud config)"
  type        = string
  default     = "us-east1-c"
}

variable "cluster_name" {
  description = "Name of the GKE cluster (if empty, will use username-gitlab-gke-cluster)"
  type        = string
  default     = ""
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "Disk size in GB for each node"
  type        = number
  default     = 50
}

variable "use_preemptible_nodes" {
  description = "Use preemptible nodes for cost optimization"
  type        = bool
  default     = true
}

variable "gitlab_domain" {
  description = "Domain for GitLab instance (optional, will use LoadBalancer IP if not provided)"
  type        = string
  default     = ""
}

variable "gitlab_storage_size" {
  description = "Storage size for GitLab persistent volumes"
  type        = string
  default     = "50Gi"
}

# Monitoring Configuration
variable "enable_prometheus" {
  description = "Enable Prometheus monitoring stack"
  type        = bool
  default     = false
}

variable "enable_grafana" {
  description = "Enable Grafana dashboards (requires Prometheus)"
  type        = bool
  default     = false
}

variable "enable_hpa" {
  description = "Enable Horizontal Pod Autoscaler for GitLab components"
  type        = bool
  default     = false  # Disable temporarily to avoid namespace dependency issue
}

variable "enable_vpa" {
  description = "Enable Vertical Pod Autoscaling"
  type        = bool
  default     = false
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus data"
  type        = string
  default     = "50Gi"
}