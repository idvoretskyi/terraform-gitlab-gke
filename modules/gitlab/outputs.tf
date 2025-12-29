output "gitlab_namespace" {
  description = "Kubernetes namespace where GitLab is deployed"
  value       = kubernetes_namespace.gitlab.metadata[0].name
}

output "gitlab_url" {
  description = "GitLab URL"
  value       = var.gitlab_domain != "" ? "https://${var.gitlab_domain}" : "https://${kubernetes_service.gitlab_webservice_default.status.0.load_balancer.0.ingress.0.ip}.nip.io"
}

output "gitlab_initial_root_password" {
  description = "Initial root password for GitLab (sensitive)"
  value       = random_password.gitlab_initial_root_password.result
  sensitive   = true
}

output "loadbalancer_ip" {
  description = "LoadBalancer IP address"
  value       = try(kubernetes_service.gitlab_webservice_default.status.0.load_balancer.0.ingress.0.ip, "pending")
}