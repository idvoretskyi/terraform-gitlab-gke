resource "kubernetes_namespace" "gitlab" {
  metadata {
    name = "gitlab"
    labels = {
      name = "gitlab"
    }
  }
}

resource "kubernetes_storage_class" "gitlab_ssd" {
  metadata {
    name = "gitlab-ssd"
  }
  storage_provisioner    = "pd.csi.storage.gke.io"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  parameters = {
    type             = "pd-ssd"
    replication-type = "regional-pd"
  }
}

resource "helm_release" "gitlab" {
  name       = "gitlab"
  repository = "https://charts.gitlab.io/"
  chart      = "gitlab"
  version    = "7.5.0"
  namespace  = kubernetes_namespace.gitlab.metadata[0].name
  timeout    = 1200

  values = [
    yamlencode({
      global = {
        edition = "ce"
        hosts = {
          domain     = var.gitlab_domain != "" ? var.gitlab_domain : "${kubernetes_service.gitlab_webservice_default.status.0.load_balancer.0.ingress.0.ip}.nip.io"
          externalIP = var.gitlab_domain == "" ? kubernetes_service.gitlab_webservice_default.status.0.load_balancer.0.ingress.0.ip : null
        }

        ingress = {
          configureCertmanager = false
          class                = "gce"
          tls = {
            enabled = false
          }
        }

        initialRootPassword = {
          secret = kubernetes_secret.gitlab_initial_root_password.metadata[0].name
          key    = "password"
        }

        psql = {
          connectTimeout = 30
          password = {
            useSecret = true
            secret    = kubernetes_secret.gitlab_postgresql_password.metadata[0].name
            key       = "postgresql-password"
          }
        }

        redis = {
          password = {
            enabled = true
            secret  = kubernetes_secret.gitlab_redis_secret.metadata[0].name
            key     = "redis-password"
          }
        }

        gitaly = {
          authToken = {
            secret = kubernetes_secret.gitlab_gitaly_secret.metadata[0].name
            key    = "token"
          }
        }

        shell = {
          authToken = {
            secret = kubernetes_secret.gitlab_shell_secret.metadata[0].name
            key    = "secret"
          }
        }

        railsSecrets = {
          secret = kubernetes_secret.gitlab_rails_secret.metadata[0].name
        }
      }

      # PostgreSQL configuration
      postgresql = {
        install = true
        auth = {
          existingSecret = kubernetes_secret.gitlab_postgresql_password.metadata[0].name
          secretKeys = {
            adminPasswordKey = "postgresql-postgres-password"
            userPasswordKey  = "postgresql-password"
          }
        }
        primary = {
          persistence = {
            enabled      = true
            size         = var.gitlab_storage_size
            storageClass = kubernetes_storage_class.gitlab_ssd.metadata[0].name
          }
          resources = {
            requests = {
              memory = "1Gi"
              cpu    = "500m"
            }
            limits = {
              memory = "2Gi"
              cpu    = "1000m"
            }
          }
        }
      }

      # Redis configuration
      redis = {
        install = true
        auth = {
          enabled                   = true
          existingSecret            = kubernetes_secret.gitlab_redis_secret.metadata[0].name
          existingSecretPasswordKey = "redis-password"
        }
        master = {
          persistence = {
            enabled      = true
            size         = "8Gi"
            storageClass = kubernetes_storage_class.gitlab_ssd.metadata[0].name
          }
          resources = {
            requests = {
              memory = "512Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "1Gi"
              cpu    = "500m"
            }
          }
        }
      }

      # GitLab components
      gitlab = {
        webservice = {
          replicaCount = 1
          resources = {
            requests = {
              memory = "1.5Gi"
              cpu    = "500m"
            }
            limits = {
              memory = "3Gi"
              cpu    = "1500m"
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

        sidekiq = {
          replicaCount = 1
          resources = {
            requests = {
              memory = "1Gi"
              cpu    = "500m"
            }
            limits = {
              memory = "2Gi"
              cpu    = "1000m"
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

        gitaly = {
          persistence = {
            enabled      = true
            size         = var.gitlab_storage_size
            storageClass = kubernetes_storage_class.gitlab_ssd.metadata[0].name
          }
          resources = {
            requests = {
              memory = "512Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "1Gi"
              cpu    = "500m"
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

        gitlab-shell = {
          replicaCount = 1
          resources = {
            requests = {
              memory = "256Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "300m"
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

      # Disable components not needed for basic installation
      gitlab-runner = {
        install = false
      }

      nginx-ingress = {
        enabled = false
      }

      certmanager = {
        install = false
      }
    })
  ]

  depends_on = [
    kubernetes_secret.gitlab_initial_root_password,
    kubernetes_secret.gitlab_postgresql_password,
    kubernetes_secret.gitlab_redis_secret,
    kubernetes_secret.gitlab_gitaly_secret,
    kubernetes_secret.gitlab_shell_secret,
    kubernetes_secret.gitlab_rails_secret,
    kubernetes_storage_class.gitlab_ssd
  ]
}

# Create a temporary service to get the LoadBalancer IP for domain configuration
resource "kubernetes_service" "gitlab_webservice_default" {
  metadata {
    name      = "gitlab-webservice-default-temp"
    namespace = kubernetes_namespace.gitlab.metadata[0].name
  }

  spec {
    selector = {
      app = "webservice"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }

    port {
      name        = "https"
      port        = 443
      target_port = 8080
    }

    type                        = "LoadBalancer"
    load_balancer_source_ranges = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [
      spec[0].cluster_ip,
      spec[0].external_ips
    ]
  }
}