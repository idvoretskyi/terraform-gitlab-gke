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

# Explicitly wire project and region from local gcloud config so the provider
# inherits them without relying on environment variables.
provider "google" {
  project = local.project_id
  region  = local.region
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

# helm provider v3: kubernetes block is now an object assignment (= { ... })
provider "helm" {
  kubernetes = {
    host                   = "https://${module.gke.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  }
}
