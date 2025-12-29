# EKS Production Setup with Auto-Scaling

Complete production-ready EKS cluster with Horizontal Pod Autoscaler (HPA), Cluster Autoscaler, and Metrics Server.

## 🚀 Quick Start

```bash
# 1. Deploy infrastructure
cd terraform/
terraform init
terraform plan
terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --region ap-south-1 --name eks-terraform-cluster

# 3. Deploy sample application with HPA
kubectl apply -f hpa-demo.yaml

# 4. Test scaling (optional)
kubectl apply -f load-generator.yaml
```

## 🗑️ Cleanup / Delete EKS Setup

To completely remove the EKS cluster and all associated resources:

```bash
# 1. Delete Kubernetes resources first (optional - if you deployed any)
kubectl delete -f hpa-demo.yaml
kubectl delete -f load-generator.yaml

# 2. Delete all pods and services (to release load balancers)
kubectl delete all --all --all-namespaces

# 3. Delete the Terraform infrastructure
cd terraform/
terraform destroy

# 4. Verify cleanup (optional)
aws eks list-clusters --region ap-south-1
aws ec2 describe-instances --region ap-south-1 --filters "Name=tag:kubernetes.io/cluster/eks-terraform-cluster,Values=owned"
```

### ⚠️ Important Notes for Deletion:
- Always delete Kubernetes resources before running `terraform destroy`
- LoadBalancer services can create AWS resources outside Terraform's control
- Check for any remaining EBS volumes or security groups after deletion
- The process may take 10-15 minutes to complete

## 📋 Architecture

- **EKS Cluster**: Kubernetes 1.31 with 2-5 t3.small nodes
- **Cluster Autoscaler**: Auto-scales nodes based on pod demand
- **Metrics Server**: Provides resource metrics for HPA
- **HPA**: Auto-scales pods based on CPU/memory utilization

## 🔧 Components

### Infrastructure (Terraform)
- EKS cluster with managed node groups
- IAM roles with IRSA for secure service access
- Auto Scaling Groups with proper tags
- VPC and security group configuration

### Auto-Scaling Stack
- **Cluster Autoscaler**: Scales nodes 2-5 based on unschedulable pods
- **HPA**: Scales pods 2-10 based on 70% CPU / 80% memory
- **Metrics Server**: Real-time resource monitoring

## 📊 Scaling Conditions

### Node Scaling (Cluster Autoscaler)
**Scale UP when:**
- Pods cannot be scheduled due to insufficient resources
- Node capacity exceeded (CPU, memory, or pod limit)

**Scale DOWN when:**
- Node underutilized for 10+ minutes
- Pods can be rescheduled to other nodes

### Pod Scaling (HPA)
**Scale UP when:**
- CPU utilization > 70% OR memory > 80%
- Metrics averaged over 15 seconds

**Scale DOWN when:**
- Resource utilization below targets for 5 minutes

## 🎯 Resource Limits

### Per t3.small Node:
- **CPU**: 1930m allocatable
- **Memory**: 1.4GB allocatable  
- **Pods**: 11 maximum
- **Cost**: ~$15/month per node

### Current Configuration:
- **Min Nodes**: 2 (always running)
- **Max Nodes**: 5 (scales up under load)
- **Min Pods**: 2 (per application)
- **Max Pods**: 10 (per application)

## 🧪 Testing Scaling

```bash
# Monitor scaling
kubectl get hpa -w
kubectl get nodes -w

# Generate load
kubectl scale deployment load-generator --replicas=5

# Check resource usage
kubectl top nodes
kubectl top pods

# View autoscaler logs
kubectl logs -f deployment/cluster-autoscaler -n kube-system
```

## 📁 File Structure

```
eks-production-setup/
├── README.md                    # This file
├── terraform/                   # Infrastructure as Code
│   ├── main.tf                 # EKS cluster configuration
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── cluster-autoscaler.tf   # Cluster autoscaler setup
│   ├── metrics-server.tf       # Metrics server setup
│   └── terraform.tfvars        # Variable values
├── hpa-demo.yaml               # Sample app with HPA
└── load-generator.yaml         # Load testing tool
```

## ⚙️ Configuration

### Key Settings:
- **Region**: ap-south-1
- **Instance Type**: t3.small (cost-optimized)
- **Kubernetes Version**: 1.31
- **Node Scaling**: 2-5 nodes
- **Pod Scaling**: 2-10 replicas per app

### Resource Requests:
- **Sample App**: 100m CPU, 128Mi memory
- **Load Generator**: 50m CPU, 64Mi memory

## 🔍 Monitoring

```bash
# Cluster status
kubectl get nodes,pods,hpa

# Resource utilization
kubectl top nodes
kubectl top pods

# Autoscaler status
kubectl get deployment cluster-autoscaler -n kube-system
kubectl get deployment metrics-server -n kube-system

# Scaling events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 🛠️ Troubleshooting

### Common Issues:

**HPA shows `<unknown>` metrics:**
```bash
kubectl get apiservice v1beta1.metrics.k8s.io
kubectl logs deployment/metrics-server -n kube-system
```

**Cluster Autoscaler not scaling:**
```bash
kubectl logs deployment/cluster-autoscaler -n kube-system
kubectl describe nodes  # Check capacity
```

**Pods stuck in Pending:**
```bash
kubectl describe pod <pod-name>
kubectl get events
```

## 💰 Cost Optimization

- **Base Cost**: ~$30/month (2 x t3.small nodes)
- **Peak Cost**: ~$75/month (5 x t3.small nodes)
- **Auto-scaling**: Reduces costs during low usage
- **Right-sizing**: t3.small optimal for development/testing

## 🔐 Security Features

- **IRSA**: IAM roles for service accounts
- **Least Privilege**: Minimal required permissions
- **Network Security**: VPC and security groups
- **Resource Limits**: Prevents resource exhaustion

## 📈 Performance

- **Scaling Speed**: 
  - Pod scaling: 15-30 seconds
  - Node scaling: 2-3 minutes
- **Resource Efficiency**: ~15 pods per node
- **High Availability**: Multi-AZ deployment

---

**Status**: ✅ Production Ready | **Last Updated**: December 2025
