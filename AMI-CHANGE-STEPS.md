# EKS Cluster AMI Change Steps

## 📋 Overview
Steps to change the AMI for worker nodes in the EKS cluster `eks-terraform-cluster`.

**Current Setup:**
- Cluster: eks-terraform-cluster
- Region: ap-south-1
- Current AMI: ami-0ed2e566705caa38e
- Node Type: t3.small
- Kubernetes: 1.33

## 🎯 AMI Change Methods

**IMPORTANT**: Your node group is a **MANAGED** node group, not using launch templates.

### Method 1: AWS Console (Simplest for Managed Node Groups)

#### Step 1: Update via Console
```
1. AWS Console → EKS → eks-terraform-cluster
2. Compute → Node groups → workers  
3. Actions → Update now
4. Update strategy: Rolling update
5. AMI release version: Select latest available
6. Review and update
```

### Method 2: AWS CLI Update (Managed Node Group)
```bash
# Update to latest AMI for current Kubernetes version
aws eks update-nodegroup-version \
  --cluster-name eks-terraform-cluster \
  --nodegroup-name workers \
  --region ap-south-1
```

### Method 3: Terraform Update (Advanced)

#### Step 1: Find New AMI
```bash
# Get latest EKS optimized AMI for 1.33
aws ssm get-parameter \
  --name /aws/service/eks/optimized-ami/1.33/amazon-linux-2/recommended/image_id \
  --region ap-south-1 \
  --query 'Parameter.Value' \
  --output text

# Or list available AMIs
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amazon-eks-node-1.33-*" \
  --region ap-south-1 \
  --query 'Images[*].[ImageId,Name,CreationDate]' \
  --output table
```

#### Step 2: Update Terraform Configuration
```bash
cd /home/ubuntu/eks-production-setup/terraform

# Edit main.tf or variables.tf
# Update the AMI ID in node group configuration
```

**Edit terraform/main.tf:**
```hcl
resource "aws_eks_node_group" "workers" {
  # ... existing configuration ...
  
  launch_template {
    id      = aws_launch_template.worker_nodes.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "worker_nodes" {
  name_prefix   = "eks-worker-nodes-"
  image_id      = "ami-NEW_AMI_ID_HERE"  # Update this
  instance_type = var.instance_type
  
  # ... rest of configuration ...
}
```

#### Step 3: Plan and Apply Changes
```bash
cd terraform/

# Initialize and plan
terraform init
terraform plan

# Apply changes (this will trigger rolling update)
terraform apply
```

### Method 2: AWS CLI Update

#### Step 1: Get Current Node Group Info
```bash
aws eks describe-nodegroup \
  --cluster-name eks-terraform-cluster \
  --nodegroup-name workers \
  --region ap-south-1
```

#### Step 2: Update Launch Template
```bash
# Get current launch template
aws ec2 describe-launch-templates \
  --region ap-south-1 \
  --filters "Name=tag:Name,Values=eks-worker-nodes-*"

# Create new version with new AMI
aws ec2 create-launch-template-version \
  --launch-template-id lt-xxxxxxxxx \
  --source-version 1 \
  --launch-template-data '{"ImageId":"ami-NEW_AMI_ID"}' \
  --region ap-south-1
```

#### Step 3: Update Node Group
```bash
aws eks update-nodegroup-version \
  --cluster-name eks-terraform-cluster \
  --nodegroup-name workers \
  --launch-template id=lt-xxxxxxxxx,version=2 \
  --region ap-south-1
```

### Method 3: Console Update (For Managed Node Groups)

**Your node group is a MANAGED node group (not using launch template)**

1. **AWS Console** → **EKS** → **eks-terraform-cluster**
2. **Compute** → **Node groups** → **workers**
3. **Actions** → **Update now**
4. **Update strategy**: Rolling update
5. **AMI type**: Select new AMI version
6. **Review and update**

**Note**: Managed node groups automatically use the latest EKS-optimized AMI for the Kubernetes version. You cannot specify a custom AMI directly.

## 🔍 Pre-Change Verification

### Check Current AMI
```bash
# Get current node AMI
kubectl get nodes -o wide

# Describe nodes for AMI info
aws ec2 describe-instances \
  --filters "Name=tag:kubernetes.io/cluster/eks-terraform-cluster,Values=owned" \
  --region ap-south-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,ImageId,State.Name]' \
  --output table
```

### Backup Current State
```bash
# Export current node group config
aws eks describe-nodegroup \
  --cluster-name eks-terraform-cluster \
  --nodegroup-name workers \
  --region ap-south-1 > current-nodegroup-backup.json

# Export current pods
kubectl get pods --all-namespaces -o yaml > current-pods-backup.yaml
```

## 🚀 Rolling Update Process

### Monitor Update Progress
```bash
# Watch node group status
aws eks describe-nodegroup \
  --cluster-name eks-terraform-cluster \
  --nodegroup-name workers \
  --region ap-south-1 \
  --query 'nodegroup.status'

# Watch nodes
kubectl get nodes -w

# Watch pods during update
kubectl get pods --all-namespaces -w
```

### Update Timeline
- **Start**: Node group status changes to "UPDATING"
- **Phase 1**: New nodes launched with new AMI (2-3 minutes)
- **Phase 2**: Pods drained from old nodes (1-2 minutes)
- **Phase 3**: Old nodes terminated (1-2 minutes)
- **Complete**: Status returns to "ACTIVE"

## ✅ Post-Change Verification

### Verify New AMI
```bash
# Check new node AMI
kubectl get nodes -o wide

# Verify AMI in EC2
aws ec2 describe-instances \
  --filters "Name=tag:kubernetes.io/cluster/eks-terraform-cluster,Values=owned" \
  --region ap-south-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,ImageId,LaunchTime]' \
  --output table
```

### Health Checks
```bash
# Node status
kubectl get nodes

# Pod status
kubectl get pods --all-namespaces

# Cluster autoscaler
kubectl logs deployment/cluster-autoscaler -n kube-system --tail=10

# Metrics server
kubectl top nodes
kubectl top pods

# HPA status
kubectl get hpa
```

## 🔧 Troubleshooting

### If Update Fails
```bash
# Check node group events
aws eks describe-nodegroup \
  --cluster-name eks-terraform-cluster \
  --nodegroup-name workers \
  --region ap-south-1

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --region ap-south-1 \
  --query 'AutoScalingGroups[?contains(Tags[?Key==`kubernetes.io/cluster/eks-terraform-cluster`].Value, `owned`)]'
```

### If Pods Don't Schedule
```bash
# Check node capacity
kubectl describe nodes

# Check pod events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check resource requests
kubectl top nodes
kubectl top pods
```

### Rollback Steps
```bash
# If using Terraform
cd terraform/
git checkout HEAD~1 -- main.tf  # Revert to previous AMI
terraform apply

# If using AWS CLI
aws eks update-nodegroup-version \
  --cluster-name eks-terraform-cluster \
  --nodegroup-name workers \
  --launch-template id=lt-xxxxxxxxx,version=1 \
  --region ap-south-1
```

## 📋 AMI Selection Guidelines

### EKS Optimized AMI Types
```bash
# Amazon Linux 2
/aws/service/eks/optimized-ami/1.33/amazon-linux-2/recommended/image_id

# Amazon Linux 2 with GPU
/aws/service/eks/optimized-ami/1.33/amazon-linux-2-gpu/recommended/image_id

# Bottlerocket
/aws/service/bottlerocket/aws-k8s-1.33/x86_64/latest/image_id
```

### Compatibility Check
- ✅ **Kubernetes Version**: Must match cluster version (1.33)
- ✅ **Architecture**: x86_64 for t3.small instances
- ✅ **Region**: Must be available in ap-south-1
- ✅ **EKS Optimized**: Use official EKS AMIs only

## ⚠️ Important Notes

### Before AMI Change:
- **Backup**: Export current configurations
- **Timing**: Plan during maintenance window
- **Resources**: Ensure sufficient capacity for rolling update
- **Applications**: Verify pod disruption budgets

### During Update:
- **Monitor**: Watch node and pod status continuously
- **Patience**: Allow 5-10 minutes for complete rollout
- **Don't Interrupt**: Let the rolling update complete

### After Update:
- **Verify**: Check all components are healthy
- **Test**: Run application tests
- **Document**: Update AMI ID in documentation
- **Cleanup**: Remove old launch template versions

## 🎯 Quick Commands Summary

```bash
# 1. Get new AMI
aws ssm get-parameter --name /aws/service/eks/optimized-ami/1.33/amazon-linux-2/recommended/image_id --region ap-south-1

# 2. Update Terraform (edit main.tf with new AMI)
cd terraform/ && terraform plan && terraform apply

# 3. Monitor update
kubectl get nodes -w

# 4. Verify completion
kubectl get nodes -o wide
aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/eks-terraform-cluster,Values=owned" --region ap-south-1
```

---

**⚡ Estimated Time**: 5-10 minutes for complete AMI change
**💰 Cost Impact**: Minimal (brief period with extra nodes during rolling update)
**🔄 Downtime**: Zero (rolling update maintains availability)
