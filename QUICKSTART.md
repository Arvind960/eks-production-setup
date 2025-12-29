# Quick Start Guide

## Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform installed
- kubectl installed

## Deployment Steps

### 1. Deploy Infrastructure
```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

### 2. Configure kubectl
```bash
aws eks update-kubeconfig --region ap-south-1 --name eks-terraform-cluster
```

### 3. Verify Setup
```bash
kubectl get nodes
kubectl get pods -n kube-system
kubectl top nodes
```

### 4. Deploy Sample Application
```bash
kubectl apply -f hpa-demo.yaml
kubectl get hpa
```

### 5. Test Auto-Scaling (Optional)
```bash
kubectl apply -f load-generator.yaml
kubectl get hpa -w
```

## Cleanup
```bash
kubectl delete -f load-generator.yaml
kubectl delete -f hpa-demo.yaml
cd terraform/
terraform destroy
```
