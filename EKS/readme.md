# EKS + Karpenter (x86 + Graviton)

This Terraform configuration deploys:
- A new VPC for the cluster
- An EKS cluster (version configurable, default 1.34)
- A small managed node group for system / Karpenter pods
- Karpenter controller via Helm
- Karpenter `EC2NodeClass` and two `NodePool`s:
  - `x86-general-purpose` (amd64)
  - `graviton-general-purpose` (arm64 / Graviton)

Karpenter is configured to use both Spot and On-Demand capacity and discovers
subnets and security groups via `karpenter.sh/discovery` tags.

## Prerequisites

- Terraform >= 1.0
- AWS CLI v2 installed and configured
- `kubectl` installed
- `helm` installed

## How to deploy

1. Adjust values in `terraform.tfvars` if needed.

2. Initialize and apply:

