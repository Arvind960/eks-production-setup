# EKS Terraform Configuration with Cluster Autoscaler

This directory contains production-ready Terraform code to create an EKS cluster with cluster autoscaler and metrics server.

## Files

- `main.tf` - Main EKS cluster configuration
- `cluster-autoscaler.tf` - Cluster autoscaler with IRSA
- `metrics-server.tf` - Metrics server for HPA
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `terraform.tfvars.example` - Example configuration

## Features

- **EKS Cluster** with managed node groups
- **Cluster Autoscaler** with IRSA (IAM Roles for Service Accounts)
- **Metrics Server** for Horizontal Pod Autoscaler support
- **Production-ready** security and scaling configuration
- **Auto-discovery** of node groups for scaling

## Usage

1. **Initialize Terraform:**
   ```bash
   cd terraform
   terraform init
   ```

2. **Create configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Plan deployment:**
   ```bash
   terraform plan
   ```

4. **Apply configuration:**
   ```bash
   terraform apply
   ```

5. **Update kubeconfig:**
   ```bash
   aws eks update-kubeconfig --region ap-south-1 --name eks-terraform-cluster
   ```

6. **Verify cluster and autoscaler:**
   ```bash
   kubectl get nodes
   kubectl get deployment cluster-autoscaler -n kube-system
   kubectl get deployment metrics-server -n kube-system
   ```

## Production Configuration

Edit `terraform.tfvars`:

```hcl
aws_region     = "ap-south-1"
cluster_name   = "eks-prod-cluster"
k8s_version    = "1.31"
instance_type  = "t3.medium"
min_nodes      = 2
max_nodes      = 10
desired_nodes  = 3
```

## Autoscaling Components

### Cluster Autoscaler
- Automatically scales worker nodes based on pod demand
- Uses IRSA for secure AWS API access
- Configured with least-waste expander for cost optimization
- Auto-discovers node groups with proper tags

### Metrics Server
- Provides resource metrics for HPA
- Required for CPU/memory-based pod autoscaling
- Production-ready security configuration

## Testing Autoscaling

1. **Deploy a test application:**
   ```bash
   kubectl create deployment test-app --image=nginx
   kubectl expose deployment test-app --port=80
   ```

2. **Create HPA:**
   ```bash
   kubectl autoscale deployment test-app --cpu-percent=50 --min=1 --max=10
   ```

3. **Generate load:**
   ```bash
   kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
   # Inside the pod:
   while true; do wget -q -O- http://test-app; done
   ```

4. **Monitor scaling:**
   ```bash
   kubectl get hpa
   kubectl get nodes
   kubectl logs deployment/cluster-autoscaler -n kube-system
   ```

## Cleanup

```bash
terraform destroy
```

## Security Features

- **IRSA** for cluster autoscaler (no AWS keys in pods)
- **Least privilege** IAM policies
- **Security contexts** for all containers
- **Read-only root filesystems** where possible

## Cost Optimization

- **Least-waste expander** for efficient node selection
- **Configurable scaling** parameters
- **Proper tagging** for resource management
- **t3.medium instances** for balanced cost and performance
- **ap-south-1 region** for optimal latency in India
