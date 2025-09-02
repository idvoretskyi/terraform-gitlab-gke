# GitLab on Google Kubernetes Engine (GKE)

This Terraform project deploys a complete GitLab instance on Google Kubernetes Engine (GKE) with cost-optimized configuration using preemptible nodes.

## Features

- **Cost-Optimized**: Uses preemptible nodes by default for significant cost savings
- **Dynamic Configuration**: Leverages `gcloud` configuration for project and region settings
- **Modular Design**: Separated into networking, GKE, and GitLab modules
- **Security**: Private cluster with Workload Identity and proper firewall rules
- **High Availability**: Regional persistent disks and auto-scaling
- **Production Ready**: Includes monitoring, logging, and proper resource limits

## Prerequisites

Before deploying, ensure you have:

1. **Google Cloud SDK** installed and configured:
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   gcloud config set compute/region YOUR_PREFERRED_REGION
   gcloud config set compute/zone YOUR_PREFERRED_ZONE
   ```

2. **Required APIs enabled**:
   ```bash
   gcloud services enable container.googleapis.com
   gcloud services enable compute.googleapis.com
   gcloud services enable servicenetworking.googleapis.com
   ```

3. **Terraform** installed (version >= 1.0)

4. **kubectl** installed for cluster management

5. **Helm** installed for GitLab deployment

## Quick Start

1. **Clone and configure**:
   ```bash
   git clone <this-repo>
   cd terraform-gitlab-gke
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars** with your preferred settings:
   ```hcl
   cluster_name = "my-gitlab-cluster"
   node_count = 2
   use_preemptible_nodes = true
   gitlab_storage_size = "50Gi"
   ```

3. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Configure kubectl**:
   ```bash
   # Command will be provided in Terraform output
   gcloud container clusters get-credentials <cluster-name> --region <region> --project <project-id>
   ```

5. **Access GitLab**:
   - URL will be provided in Terraform output
   - Initial root password: `terraform output -raw gitlab_initial_root_password`

## Architecture

### Infrastructure Components

- **VPC Network**: Custom VPC with private subnets
- **GKE Cluster**: Regional cluster with auto-scaling
- **Node Pool**: Preemptible nodes with auto-repair/upgrade
- **Load Balancer**: External load balancer for GitLab access
- **Persistent Storage**: Regional SSD storage for data persistence

### Cost Optimization Features

- **Preemptible Nodes**: Up to 80% cost savings (enabled by default)
- **Regional Persistent Disks**: Better availability at lower cost than zonal
- **Auto-scaling**: Scales down when not in use
- **Right-sized Resources**: Optimized resource requests and limits

## Configuration

### Core Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `cluster_name` | Name of the GKE cluster | `gitlab-gke-cluster` | No |
| `node_count` | Initial number of nodes | `2` | No |
| `node_machine_type` | Machine type for nodes | `e2-standard-2` | No |
| `use_preemptible_nodes` | Use preemptible nodes | `true` | No |
| `gitlab_domain` | Custom domain for GitLab | `""` (uses nip.io) | No |
| `gitlab_storage_size` | Storage size for GitLab | `50Gi` | No |

### Advanced Configuration

For production deployments, consider:

- Setting up a custom domain and SSL certificates
- Configuring backup strategies
- Setting up monitoring and alerting
- Implementing proper RBAC

## Module Structure

```
modules/
├── networking/     # VPC, subnets, firewall rules
├── gke/           # GKE cluster and node pools  
└── gitlab/        # GitLab Helm deployment
```

### Networking Module

Creates:
- Custom VPC with private IP ranges
- Regional subnet with secondary ranges for pods and services
- Cloud Router and NAT for outbound internet access
- Firewall rules for cluster communication

### GKE Module

Creates:
- Regional GKE cluster with private nodes
- Auto-scaling node pool with preemptible instances
- Workload Identity configuration
- Service account with minimal required permissions

### GitLab Module

Creates:
- Kubernetes namespace and storage classes
- GitLab Helm chart deployment with PostgreSQL and Redis
- Secure secret management
- LoadBalancer service for external access

## Operations

### Accessing GitLab

1. **Get the URL**:
   ```bash
   terraform output gitlab_url
   ```

2. **Get initial root password**:
   ```bash
   terraform output -raw gitlab_initial_root_password
   ```

3. **Access GitLab** using the URL and credentials above

### Monitoring

The cluster includes:
- Google Cloud Monitoring integration
- Managed Prometheus for metrics
- Workload monitoring enabled

### Scaling

The cluster auto-scales based on workload:
- Minimum 1 node, maximum 10 nodes
- Horizontal Pod Autoscaling enabled
- Cluster Autoscaling enabled

### Backup and Recovery

Consider implementing:
- Regular GitLab backups using GitLab's built-in backup tools
- Persistent volume snapshots
- Database backups

## Troubleshooting

### Common Issues

1. **Preemptible Node Interruptions**:
   - Nodes may be interrupted by Google Cloud
   - Workloads automatically reschedule to available nodes
   - Consider hybrid node pools for critical workloads

2. **Resource Constraints**:
   - Monitor cluster resources: `kubectl top nodes`
   - Adjust node count or machine type if needed
   - Check pod resource requests and limits

3. **Networking Issues**:
   - Verify firewall rules allow required traffic
   - Check if NAT gateway is functioning for outbound access
   - Ensure load balancer has external IP assigned

### Useful Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods -n gitlab

# Check GitLab pods
kubectl logs -n gitlab -l app=webservice

# Scale node pool manually
gcloud container clusters resize <cluster-name> --num-nodes=3 --region=<region>

# Get cluster credentials
gcloud container clusters get-credentials <cluster-name> --region=<region>
```

## Security Considerations

- Cluster uses private nodes (no external IPs)
- Workload Identity enabled for pod-level service account mapping
- Network policies enabled for pod-to-pod communication control
- Shielded GKE nodes with secure boot and integrity monitoring
- GitLab secrets are randomly generated and stored securely

## Cost Management

Expected monthly costs (us-central1 region):
- 2x e2-standard-2 preemptible nodes: ~$30-40/month
- Load balancer: ~$18/month  
- Persistent disks (100GB total): ~$10/month
- **Total estimated cost: ~$60-70/month**

To reduce costs further:
- Use smaller machine types (e2-micro, e2-small)
- Reduce storage allocation
- Use single-zone cluster (less HA)

## License

This project is open-source and available under the MIT License.