# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Terraform project for deploying GitLab on Google Kubernetes Engine (GKE). The repository provides infrastructure as code for setting up a complete GitLab instance running on Kubernetes in Google Cloud Platform.

## Key Technologies

- **Terraform**: Infrastructure provisioning and management
- **Google Cloud Platform**: Cloud provider
- **Google Kubernetes Engine (GKE)**: Managed Kubernetes service
- **GitLab**: DevOps platform deployment target
- **Helm**: Package manager for Kubernetes applications

## Common Commands

### Terraform Operations
```bash
terraform init          # Initialize Terraform working directory
terraform plan          # Preview infrastructure changes
terraform apply         # Apply infrastructure changes
terraform destroy       # Destroy infrastructure
terraform validate      # Validate configuration files
terraform fmt           # Format configuration files
```

### Google Cloud Setup
```bash
gcloud auth login                    # Authenticate with Google Cloud
gcloud config set project PROJECT_ID # Set active project
gcloud container clusters get-credentials CLUSTER_NAME --zone ZONE # Get kubectl credentials
```

### Kubernetes Operations
```bash
kubectl get nodes       # Check cluster nodes
kubectl get pods -A     # Check all pods
kubectl get services    # Check services
helm list              # List Helm releases
```

## Project Structure

This Terraform project typically follows a modular structure for GKE and GitLab deployment:

- **Main configuration**: Root-level `.tf` files for primary infrastructure
- **Modules**: Reusable Terraform modules for GKE cluster, networking, and GitLab setup
- **Variables**: Input variables for customizing the deployment
- **Outputs**: Important values like cluster endpoints and connection details

## Development Workflow

1. **Plan First**: Always run `terraform plan` before applying changes
2. **State Management**: Ensure Terraform state is properly managed (remote backend recommended)
3. **Resource Naming**: Follow consistent naming conventions for GCP resources
4. **Security**: Use least-privilege IAM roles and network security best practices
5. **GitLab Configuration**: Customize GitLab Helm chart values for the specific deployment needs

## Architecture Notes

The project provisions:
- GKE cluster with appropriate node pools and auto-scaling
- Networking components (VPC, subnets, firewall rules)
- Load balancers and ingress configuration
- Storage classes and persistent volumes for GitLab
- SSL certificates and DNS configuration
- Comprehensive monitoring setup with metrics server
- Optional Prometheus and Grafana monitoring stack
- Horizontal and Vertical Pod Autoscaling capabilities

## Module Structure

```
modules/
├── networking/     # VPC, subnets, firewall rules
├── gke/           # GKE cluster with preemptible nodes and VPA support
├── monitoring/    # Metrics server, Prometheus, Grafana, HPA/VPA configurations
└── gitlab/        # GitLab Helm deployment with auto-scaling support
```

### Monitoring Module

The monitoring module provides comprehensive observability and auto-scaling:

- **Metrics Server**: Required for HPA and resource metrics (always installed)
- **Prometheus Stack**: Optional full monitoring with Prometheus + Grafana
- **Horizontal Pod Autoscaler**: Auto-scales GitLab pods based on CPU/memory
- **Vertical Pod Autoscaler**: Automatically adjusts pod resource requests/limits
- **Cost Optimization**: All components support preemptible node scheduling

## Prerequisites

- Google Cloud SDK (`gcloud`) installed and configured
- Terraform installed (version compatibility should be specified in configuration)
- `kubectl` for Kubernetes cluster management
- Helm for GitLab deployment
- Appropriate GCP IAM permissions for resource creation