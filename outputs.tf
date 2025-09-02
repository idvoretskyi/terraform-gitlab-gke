output "project_id" {
  description = "The GCP project ID"
  value       = local.project_id
}

output "region" {
  description = "The GCP region"
  value       = local.region
}

output "zone" {
  description = "The GCP zone"
  value       = local.zone
}

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = local.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for GKE master"
  value       = module.gke.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64 encoded)"
  value       = module.gke.ca_certificate
  sensitive   = true
}

output "network_name" {
  description = "Name of the VPC network"
  value       = module.networking.network_name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = module.networking.subnet_name
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${local.cluster_name} --region ${local.region} --project ${local.project_id}"
}

output "gitlab_url" {
  description = "GitLab URL (available after deployment)"
  value       = module.gitlab.gitlab_url
}

# Monitoring Outputs
output "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring components"
  value       = module.monitoring.monitoring_namespace
}

output "metrics_server_installed" {
  description = "Whether metrics server is installed"
  value       = module.monitoring.metrics_server_installed
}

output "prometheus_enabled" {
  description = "Whether Prometheus is enabled"
  value       = module.monitoring.prometheus_enabled
}

output "grafana_enabled" {
  description = "Whether Grafana is enabled"
  value       = module.monitoring.grafana_enabled
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = module.monitoring.grafana_admin_password
  sensitive   = true
}

output "hpa_enabled" {
  description = "Whether Horizontal Pod Autoscaler is enabled"
  value       = module.monitoring.hpa_enabled
}

output "vpa_enabled" {
  description = "Whether Vertical Pod Autoscaler is enabled"
  value       = module.monitoring.vpa_enabled
}