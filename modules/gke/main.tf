resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone # Use zone instead of region for cost efficiency
  project  = var.project_id

  # Disable deletion protection to allow recreation
  deletion_protection = false

  # Remove default node pool and create separately
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_name
  subnetwork = var.subnet_name

  # Basic monitoring and logging
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Enable basic addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  # Use existing secondary ranges from subnet
  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.cluster_name}-pods"
    services_secondary_range_name = "${var.cluster_name}-services"
  }

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Basic maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
}

resource "google_service_account" "gke_nodes" {
  account_id   = "${var.cluster_name}-nodes"
  display_name = "GKE Node Service Account for ${var.cluster_name}"
  project      = var.project_id
}

resource "google_project_iam_member" "gke_nodes" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.zone # Use zone for cost efficiency
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  project    = var.project_id

  # Enable autoscaling with minimal settings for cost
  autoscaling {
    min_node_count = 1
    max_node_count = 3 # Reduce max nodes for cost efficiency
  }

  # Node management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible     = var.use_preemptible_nodes
    machine_type    = var.node_machine_type
    disk_size_gb    = var.disk_size_gb
    disk_type       = "pd-ssd"
    service_account = google_service_account.gke_nodes.email

    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Resource labels
    labels = {
      cluster = var.cluster_name
      env     = "gitlab"
    }
  }
}