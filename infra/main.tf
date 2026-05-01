module "networking" {
  source = "../modules/networking"

  project_id   = local.project_id
  region       = local.region
  cluster_name = local.cluster_name
}

module "gke" {
  source = "../modules/gke"

  project_id        = local.project_id
  region            = local.region
  zone              = local.zone
  cluster_name      = local.cluster_name
  node_count        = var.node_count
  node_machine_type = var.node_machine_type
  disk_size_gb      = var.disk_size_gb
  use_spot_nodes    = var.use_spot_nodes
  network_name      = module.networking.network_name
  subnet_name       = module.networking.subnet_name

  depends_on = [module.networking]
}

module "monitoring" {
  source = "../modules/monitoring"

  enable_prometheus       = var.enable_prometheus
  enable_grafana          = var.enable_grafana
  enable_hpa              = var.enable_hpa
  enable_vpa              = var.enable_vpa
  prometheus_storage_size = var.prometheus_storage_size

  depends_on = [module.gke]
}

module "gitlab" {
  source = "../modules/gitlab"

  cluster_endpoint       = module.gke.endpoint
  cluster_ca_certificate = module.gke.ca_certificate
  gitlab_domain          = var.gitlab_domain
  gitlab_storage_size    = var.gitlab_storage_size

  depends_on = [module.gke, module.monitoring]
}
