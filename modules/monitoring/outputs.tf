output "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring components"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "metrics_server_installed" {
  description = "Whether metrics server is installed"
  value       = true
}

output "prometheus_enabled" {
  description = "Whether Prometheus is enabled"
  value       = var.enable_prometheus
}

output "grafana_enabled" {
  description = "Whether Grafana is enabled"
  value       = var.enable_grafana && var.enable_prometheus
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.enable_prometheus && var.enable_grafana ? random_password.grafana_admin_password[0].result : "N/A - Grafana not enabled"
  sensitive   = true
}

output "hpa_enabled" {
  description = "Whether Horizontal Pod Autoscaler is enabled"
  value       = var.enable_hpa
}

output "vpa_enabled" {
  description = "Whether Vertical Pod Autoscaler is enabled"
  value       = var.enable_vpa
}