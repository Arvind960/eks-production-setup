# EKS Cluster Upgrade Guide: 1.31 → 1.32

## Overview
This guide provides step-by-step instructions to upgrade your EKS cluster from Kubernetes 1.31 to 1.32.

## Current Status
- **Cluster Name**: eks-terraform-cluster
- **Current Version**: 1.31 (upgrading to 1.32)
- **Region**: ap-south-1
- **Status**: Control plane upgrade in progress

## Prerequisites
- AWS CLI configured with appropriate permissions
- kubectl installed and configured
- Terraform installed (for infrastructure updates)
- Backup of critical workloads (recommended)

## Upgrade Steps

### Step 1: Monitor Control Plane Upgrade
The control plane upgrade is already in progress. Monitor its status:

```bash
# Check upgrade status
aws eks describe-update --name eks-terraform-cluster --update-id 5f8ae337-5e29-3fd9-9376-2d959f52864b --region ap-south-1

# Or use the automated script
./eks-upgrade-script.sh
```

### Step 2: Update Terraform Configuration
Your Terraform configuration has been updated:
- `terraform.tfvars`: k8s_version = "1.32"
- `variables.tf`: default version = "1.32"
- `cluster-autoscaler.tf`: image version = "v1.32.0"

### Step 3: Upgrade Node Groups
After control plane upgrade completes, upgrade node groups:

```bash
# List node groups
aws eks list-nodegroups --cluster-name eks-terraform-cluster --region ap-south-1

# Upgrade each node group
aws eks update-nodegroup-version --cluster-name eks-terraform-cluster --nodegroup-name workers --region ap-south-1
```

### Step 4: Update EKS Add-ons
Update managed add-ons to compatible versions:

```bash
# Update kube-proxy
aws eks update-addon --cluster-name eks-terraform-cluster --addon-name kube-proxy --region ap-south-1 --resolve-conflicts OVERWRITE

# Update CoreDNS
aws eks update-addon --cluster-name eks-terraform-cluster --addon-name coredns --region ap-south-1 --resolve-conflicts OVERWRITE

# Update VPC CNI
aws eks update-addon --cluster-name eks-terraform-cluster --addon-name vpc-cni --region ap-south-1 --resolve-conflicts OVERWRITE
```

### Step 5: Update Cluster Autoscaler
Update the cluster autoscaler image:

```bash
kubectl set image deployment/cluster-autoscaler cluster-autoscaler=registry.k8s.io/autoscaling/cluster-autoscaler:v1.32.0 -n kube-system
kubectl rollout status deployment/cluster-autoscaler -n kube-system
```

### Step 6: Apply Terraform Changes
After the AWS upgrade is complete, apply Terraform changes:

```bash
cd /home/ubuntu/eks-production-setup/terraform
terraform plan
terraform apply
```

### Step 7: Verification
Verify the upgrade:

```bash
# Check cluster version
aws eks describe-cluster --name eks-terraform-cluster --region ap-south-1 --query 'cluster.version'

# Check node versions
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Test HPA functionality
kubectl get hpa --all-namespaces

# Test cluster autoscaler
kubectl logs -f deployment/cluster-autoscaler -n kube-system
```

## Automated Upgrade
Use the provided script for automated upgrade:

```bash
cd /home/ubuntu/eks-production-setup
./eks-upgrade-script.sh
```

## Post-Upgrade Tasks

### 1. Test Applications
- Verify all applications are running correctly
- Test HPA scaling functionality
- Test cluster autoscaler functionality

### 2. Update Documentation
- Update any documentation referencing the old version
- Update CI/CD pipelines if needed

### 3. Monitor Performance
- Monitor cluster performance for 24-48 hours
- Check logs for any issues
- Verify metrics collection is working

## Rollback Plan
If issues occur, you can:
1. Scale down problematic workloads
2. Investigate logs and events
3. Contact AWS support if needed

Note: EKS doesn't support downgrading cluster versions.

## Version Compatibility Matrix

| Component | 1.31 Version | 1.32 Version |
|-----------|--------------|--------------|
| Cluster Autoscaler | v1.31.0 | v1.32.0 |
| Metrics Server | v0.7.0 | v0.7.0+ |
| kube-proxy | 1.31.x | 1.32.x |
| CoreDNS | Compatible | Compatible |
| VPC CNI | Latest | Latest |

## Troubleshooting

### Common Issues
1. **Node group upgrade fails**: Check node capacity and ensure sufficient resources
2. **Pod scheduling issues**: Verify node selectors and taints
3. **HPA not working**: Check metrics server deployment
4. **Cluster autoscaler issues**: Verify IAM permissions and image version

### Useful Commands
```bash
# Check cluster events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check node conditions
kubectl describe nodes

# Check pod logs
kubectl logs -n kube-system deployment/cluster-autoscaler
kubectl logs -n kube-system deployment/metrics-server

# Check HPA status
kubectl describe hpa <hpa-name>
```

## Support
- AWS EKS Documentation: https://docs.aws.amazon.com/eks/
- Kubernetes 1.32 Release Notes: https://kubernetes.io/docs/setup/release/notes/
- Cluster Autoscaler: https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler
