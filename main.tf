terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

data "google_client_config" "default" {}

data "google_project" "current" {}

data "external" "whoami" {
  program = ["sh", "-c", "echo '{\"username\":\"'$(whoami)'\"}'"]
}

locals {
  project_id   = data.google_project.current.project_id
  region       = data.google_client_config.default.region != null ? data.google_client_config.default.region : var.region
  zone         = data.google_client_config.default.zone != null ? data.google_client_config.default.zone : var.zone
  cluster_name = var.cluster_name != "" ? var.cluster_name : "${data.external.whoami.result.username}-gitlab-gke-cluster"
}

provider "google" {
  # Project, region, and zone will be read from gcloud config or use defaults
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  }
}

module "networking" {
  source = "./modules/networking"
  
  project_id   = local.project_id
  region       = local.region
  cluster_name = local.cluster_name
}

module "gke" {
  source = "./modules/gke"
  
  project_id               = local.project_id
  region                   = local.region
  zone                     = local.zone
  cluster_name             = local.cluster_name
  node_count               = var.node_count
  node_machine_type        = var.node_machine_type
  disk_size_gb             = var.disk_size_gb
  use_preemptible_nodes    = var.use_preemptible_nodes
  network_name             = module.networking.network_name
  subnet_name              = module.networking.subnet_name
  
  depends_on = [module.networking]
}

module "monitoring" {
  source = "./modules/monitoring"
  
  enable_prometheus      = var.enable_prometheus
  enable_grafana         = var.enable_grafana
  enable_hpa             = var.enable_hpa
  enable_vpa             = var.enable_vpa
  prometheus_storage_size = var.prometheus_storage_size
  
  depends_on = [module.gke]
}

module "gitlab" {
  source = "./modules/gitlab"
  
  cluster_endpoint       = module.gke.endpoint
  cluster_ca_certificate = module.gke.ca_certificate
  gitlab_domain          = var.gitlab_domain
  gitlab_storage_size    = var.gitlab_storage_size
  
  depends_on = [module.gke, module.monitoring]
}