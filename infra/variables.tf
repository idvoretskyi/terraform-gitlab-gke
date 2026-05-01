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
  description = "Initial number of nodes in the node pool; autoscaler adjusts from there"
  type        = number
  default     = 1
}

variable "node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "Disk size in GB for each node's boot disk"
  type        = number
  default     = 30
}

variable "use_spot_nodes" {
  description = "Use Spot VMs for cost optimization (~60-91% savings vs on-demand). Spot replaces the deprecated preemptible option."
  type        = bool
  default     = true
}

variable "gitlab_domain" {
  description = "Domain for GitLab instance (optional, will use LoadBalancer IP with nip.io if not provided)"
  type        = string
  default     = ""
}

variable "gitlab_storage_size" {
  description = "Storage size for GitLab persistent volumes (Gitaly + PostgreSQL)"
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
  description = "Enable Grafana dashboards (requires enable_prometheus = true)"
  type        = bool
  default     = false
}

variable "enable_hpa" {
  description = "Enable Horizontal Pod Autoscaler for GitLab components"
  type        = bool
  default     = false
}

variable "enable_vpa" {
  description = "Enable Vertical Pod Autoscaling (experimental)"
  type        = bool
  default     = false
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus data"
  type        = string
  default     = "50Gi"
}
