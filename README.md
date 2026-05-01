# GitLab on Google Kubernetes Engine (GKE)

This Terraform project deploys a complete GitLab CE instance on Google Kubernetes Engine (GKE) with a cost-optimised, production-ready configuration.

## Features

- **Cost-Optimised**: Spot VMs by default (~60-91 % savings vs on-demand)
- **Auto-configuration**: Project, region, and zone are read from your local `gcloud` config automatically — no manual variable overrides needed
- **Modular Design**: Separated into networking, GKE, and GitLab modules
- **Security**: Workload Identity enabled; private nodes with Cloud NAT for outbound access
- **Auto-scaling**: Cluster Autoscaler (min 1 / max 3 nodes) + optional HPA and VPA for GitLab pods
- **Production Ready**: Monitoring, logging, and right-sized resource limits included

## Prerequisites

1. **Google Cloud SDK** installed and authenticated:
   ```bash
   gcloud auth application-default login
   gcloud config set project YOUR_PROJECT_ID
   gcloud config set compute/region YOUR_REGION   # e.g. us-east1
   gcloud config set compute/zone   YOUR_ZONE     # e.g. us-east1-c
   ```

2. **Required APIs enabled**:
   ```bash
   gcloud services enable container.googleapis.com compute.googleapis.com servicenetworking.googleapis.com
   ```

3. **Terraform** >= 1.5 ([install](https://developer.hashicorp.com/terraform/install))

4. **kubectl** for cluster management

5. **Helm** >= 3 for GitLab deployment

## Quick Start

```bash
git clone <this-repo>
cd terraform-gitlab-gke/infra
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if you want to override any defaults
terraform init
terraform plan
terraform apply
```

### Access GitLab

```bash
# Configure kubectl
$(terraform output -raw kubectl_config_command)

# Get the GitLab URL
terraform output gitlab_url

# Get the initial root password
terraform output -raw gitlab_initial_root_password
```

## How Local `gcloud` Config Is Used

`infra/providers.tf` reads the active gcloud configuration at plan time:

```hcl
data "google_client_config" "default" {}
data "google_project"       "current"  {}

locals {
  project_id = data.google_project.current.project_id
  region     = data.google_client_config.default.region != null ? data.google_client_config.default.region : var.region
  zone       = data.google_client_config.default.zone   != null ? data.google_client_config.default.zone   : var.zone
}

provider "google" {
  project = local.project_id
  region  = local.region
}
```

The `region` and `zone` variables in `variables.tf` serve as **fallbacks** only; if your gcloud config has them set, those values take precedence automatically.

## Architecture

### Module Structure

```
modules/
├── networking/   # VPC, subnets, Cloud Router + NAT, firewall rules
├── gke/          # Zonal GKE cluster, Spot node pool, service account
├── monitoring/   # Optional Prometheus/Grafana, HPA, VPA
└── gitlab/       # Kubernetes secrets, storage class, GitLab Helm release
```

### Infrastructure Components

| Component | Details |
|-----------|---------|
| VPC | Custom VPC with private subnets and secondary ranges for pods/services |
| GKE | Zonal cluster (cost-effective vs regional), Workload Identity, auto-repair/upgrade |
| Node Pool | Spot VMs (`e2-standard-2`, 30 GB SSD), autoscale 1–3 nodes |
| Storage | `pd-ssd` regional persistent disks via CSI driver |
| Load Balancer | External L4 LoadBalancer for GitLab access |

## Configuration

### Core Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `us-east1` | Fallback region if not in gcloud config |
| `zone` | `us-east1-c` | Fallback zone if not in gcloud config |
| `cluster_name` | `<user>-gitlab-gke-cluster` | GKE cluster name |
| `node_count` | `1` | Initial node count (autoscaler handles the rest) |
| `node_machine_type` | `e2-standard-2` | GKE node machine type |
| `disk_size_gb` | `30` | Node boot disk size in GB |
| `use_spot_nodes` | `true` | Enable Spot VMs for cost savings |
| `gitlab_domain` | `""` | Custom domain; uses `<ip>.nip.io` if empty |
| `gitlab_storage_size` | `50Gi` | PV size for Gitaly + PostgreSQL |

### Monitoring Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_prometheus` | `false` | Deploy kube-prometheus-stack |
| `enable_grafana` | `false` | Deploy Grafana (requires Prometheus) |
| `enable_hpa` | `false` | HPA for `gitlab-webservice-default` |
| `enable_vpa` | `false` | VPA for `gitlab-webservice-default` |
| `prometheus_storage_size` | `50Gi` | Prometheus data PV size |

## Component Versions

| Component | Version |
|-----------|---------|
| Terraform | >= 1.5 |
| `hashicorp/google` provider | ~> 7.0 (latest: 7.30) |
| `hashicorp/kubernetes` provider | ~> 3.0 (latest: 3.1) |
| `hashicorp/helm` provider | ~> 3.0 (latest: 3.1) |
| GitLab Helm chart | 9.11.2 |
| kube-prometheus-stack chart | 84.5.0 |
| Terraform in CI | 1.15.1 |
| TFLint in CI | v0.62.0 |

## Cost Optimisation

### Strategy

- **Spot VMs** (`use_spot_nodes = true`, default): ~60-91 % savings vs on-demand. GKE automatically reschedules workloads on interruption.
- **Zonal cluster**: avoids the ~$0.10/hr regional cluster management fee.
- **Initial node count = 1**: Cluster Autoscaler adds nodes only when workloads require them.
- **Smaller boot disks** (30 GB default): GitLab data lives on dedicated PVs, not the boot disk.

### Estimated Monthly Cost (us-east1)

| Item | Estimated Cost |
|------|---------------|
| 1–2× `e2-standard-2` Spot nodes | ~$10-25/month |
| Load balancer | ~$18/month |
| Persistent disks (50 GB PVs) | ~$8/month |
| **Total** | **~$36-50/month** |

> Costs vary with workload. Scale down `max_node_count` or use smaller machine types to reduce further.

## Operations

### Scaling

```bash
# View current autoscaler status
kubectl get nodes

# Manual resize if needed
gcloud container clusters resize <cluster-name> --num-nodes=2 --zone=<zone>
```

### Monitoring

```bash
# Node resource usage
kubectl top nodes

# GitLab pod status
kubectl get pods -n gitlab
kubectl logs -n gitlab -l app=webservice
```

### Backup

Consider:
- GitLab's built-in backup tool (`gitlab-backup create`)
- Persistent Volume snapshots via GCP Disk Snapshots
- PostgreSQL logical backups

## Troubleshooting

**Spot VM interruptions** — workloads reschedule automatically. For latency-sensitive workloads set `use_spot_nodes = false`.

**Resource pressure** — monitor with `kubectl top nodes/pods`. Increase `max_node_count` or switch to `e2-standard-4` if needed.

**LoadBalancer IP pending** — GCP provisioning can take 2-5 minutes. Check with `kubectl get svc -n gitlab`.

**`terraform init` required after clone** — the `.terraform.lock.hcl` is not committed; run `terraform init` before `plan`/`apply`.

## Security

- Workload Identity enabled (pod-level GCP identity, no static keys)
- Private node IPs; outbound via Cloud NAT only
- All GitLab secrets randomly generated and stored in Kubernetes Secrets
- Node boot disks use `pd-ssd` (encrypted at rest by default in GCP)

## License

MIT
