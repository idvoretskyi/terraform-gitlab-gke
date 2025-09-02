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
  default     = true
}

variable "enable_vpa" {
  description = "Enable Vertical Pod Autoscaler for GitLab components"
  type        = bool
  default     = false
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus data"
  type        = string
  default     = "50Gi"
}