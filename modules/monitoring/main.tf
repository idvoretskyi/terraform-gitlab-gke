resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }
}

# Metrics Server is provided by GKE by default
# No need to install it separately

# Prometheus for advanced monitoring (optional, configurable)
resource "helm_release" "prometheus" {
  count = var.enable_prometheus ? 1 : 0

  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.5.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  timeout    = 1200

  values = [
    yamlencode({
      # Prometheus configuration
      prometheus = {
        prometheusSpec = {
          retention = "30d"
          resources = {
            requests = {
              cpu    = "500m"
              memory = "2Gi"
            }
            limits = {
              cpu    = "1000m"
              memory = "4Gi"
            }
          }
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "standard-rwo"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }
          tolerations = [
            {
              key      = "cloud.google.com/gke-preemptible"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
          ]
        }
      }

      # Grafana configuration
      grafana = {
        enabled = var.enable_grafana
        adminPassword = random_password.grafana_admin_password[0].result
        resources = {
          requests = {
            cpu    = "250m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "1Gi"
          }
        }
        persistence = {
          enabled = true
          size    = "10Gi"
          storageClassName = "standard-rwo"
        }
        tolerations = [
          {
            key      = "cloud.google.com/gke-preemptible"
            operator = "Equal"
            value    = "true"
            effect   = "NoSchedule"
          }
        ]
      }

      # AlertManager configuration
      alertmanager = {
        alertmanagerSpec = {
          resources = {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "512Mi"
            }
          }
          tolerations = [
            {
              key      = "cloud.google.com/gke-preemptible"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
          ]
        }
      }

      # Node Exporter
      nodeExporter = {
        enabled = true
      }

      # State Metrics
      kubeStateMetrics = {
        enabled = true
      }

      # Disable components we don't need for basic monitoring
      kubeApiServer = {
        enabled = true
      }
      kubelet = {
        enabled = true
      }
      kubeControllerManager = {
        enabled = false
      }
      coreDns = {
        enabled = true
      }
      kubeEtcd = {
        enabled = false
      }
      kubeScheduler = {
        enabled = false
      }
      kubeProxy = {
        enabled = true
      }
    })
  ]

}

# Random password for Grafana admin
resource "random_password" "grafana_admin_password" {
  count   = var.enable_prometheus && var.enable_grafana ? 1 : 0
  length  = 16
  special = true
}

resource "kubernetes_secret" "grafana_admin_password" {
  count = var.enable_prometheus && var.enable_grafana ? 1 : 0

  metadata {
    name      = "grafana-admin-password"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    admin-password = random_password.grafana_admin_password[0].result
  }

  type = "Opaque"
}

# Horizontal Pod Autoscaler example for GitLab components
# Wait for GitLab namespace to be created
data "kubernetes_namespace" "gitlab" {
  count = var.enable_hpa ? 1 : 0
  metadata {
    name = "gitlab"
  }
  depends_on = [kubernetes_namespace.monitoring]
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "gitlab_webservice_hpa" {
  count = var.enable_hpa ? 1 : 0

  metadata {
    name      = "gitlab-webservice-hpa" 
    namespace = data.kubernetes_namespace.gitlab[0].metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "gitlab-webservice-default"
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }

    behavior {
      scale_up {
        stabilization_window_seconds = 300
        select_policy               = "Max"
        policy {
          type          = "Percent"
          value         = 100
          period_seconds = 15
        }
      }
      scale_down {
        stabilization_window_seconds = 300
        select_policy               = "Max"
        policy {
          type          = "Percent"
          value         = 10
          period_seconds = 60
        }
      }
    }
  }

}

# Vertical Pod Autoscaler configuration for GitLab components
resource "kubernetes_manifest" "gitlab_webservice_vpa" {
  count = var.enable_vpa ? 1 : 0

  manifest = {
    apiVersion = "autoscaling.k8s.io/v1"
    kind       = "VerticalPodAutoscaler"
    metadata = {
      name      = "gitlab-webservice-vpa"
      namespace = "gitlab"
    }
    spec = {
      targetRef = {
        apiVersion = "apps/v1"
        kind       = "Deployment"
        name       = "gitlab-webservice-default"
      }
      updatePolicy = {
        updateMode = "Auto"
      }
      resourcePolicy = {
        containerPolicies = [
          {
            containerName = "webservice"
            maxAllowed = {
              cpu    = "2000m"
              memory = "4Gi"
            }
            minAllowed = {
              cpu    = "100m"
              memory = "512Mi"
            }
          }
        ]
      }
    }
  }

}