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

provider "google" {}

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
