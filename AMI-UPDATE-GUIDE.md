# AMI Update Verification Guide

## Current Status After Upgrade

### Launch Template Versions:
```
Version 1 (Old): ami-083a6ae798fedaee6 (K8s 1.31)
Version 2 (New): ami-0f81ee05296e6093d (K8s 1.32) ✅ ACTIVE
```

### Auto Scaling Group:
- Using Launch Template Version: **2** ✅
- All instances running new AMI: **ami-0f81ee05296e6093d** ✅

## Verification Commands

### Check Current AMI in Use:
```bash
# Get current instances AMI
aws ec2 describe-instances \
  --instance-ids i-0542e8e3cc65cc40e i-075af842fb1a1d94d \
  --region ap-south-1 \
  --query 'Reservations[].Instances[].{InstanceId:InstanceId,AMI:ImageId,State:State.Name}'

# Check launch template versions
aws ec2 describe-launch-template-versions \
  --launch-template-id lt-00f4eb1c8bb3028b4 \
  --region ap-south-1 \
  --query 'LaunchTemplateVersions[].{Version:VersionNumber,AMI:LaunchTemplateData.ImageId,CreateTime:CreateTime}'
```

### Check Node Kubernetes Version:
```bash
kubectl get nodes -o wide
```

## Key Points:

### ✅ **AWS Manages Everything:**
- AMI selection for Kubernetes version
- Launch template updates  
- Auto Scaling Group configuration
- Rolling node replacement

### ❌ **You Don't Need To:**
- Manually find compatible AMIs
- Update launch templates
- Modify Auto Scaling Groups
- Handle node replacement logic

### 🔍 **What to Monitor:**
- Node group upgrade status
- Pod rescheduling during rolling update
- Application availability during upgrade

## AMI Naming Convention:
```
EKS Optimized AMI Format:
amazon-eks-node-{k8s-version}-v{release-date}

Example:
- K8s 1.31: ami-083a6ae798fedaee6
- K8s 1.32: ami-0f81ee05296e6093d
```

## Troubleshooting:

### If Nodes Don't Update:
1. Check node group status: `aws eks describe-nodegroup`
2. Check Auto Scaling Group activity
3. Verify sufficient capacity for rolling update
4. Check for pod disruption budgets blocking drain

### Manual AMI Update (Only if needed):
```bash
# Only use if automatic update fails
aws eks update-nodegroup-config \
  --cluster-name eks-terraform-cluster \
  --nodegroup-name workers \
  --launch-template Id=lt-00f4eb1c8bb3028b4,Version=2
```
