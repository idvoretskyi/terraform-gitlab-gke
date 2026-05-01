variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "zone" {
  description = "The GCP zone"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "node_count" {
  description = "Initial number of nodes in the default node pool"
  type        = number
}

variable "node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
}

variable "disk_size_gb" {
  description = "Disk size in GB for each node"
  type        = number
}

variable "use_spot_nodes" {
  description = "Use Spot VMs for cost optimization (~60-91% savings vs on-demand). Replaces the deprecated preemptible option."
  type        = bool
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}
