# Create Launch Template for EKS Node Group - GUI Steps

## 📋 Overview
Steps to create a launch template via AWS Console GUI and convert your managed node group to use it.

**Current Setup:**
- Cluster: eks-terraform-cluster
- Node Group: workers (currently managed)
- Instance Type: t3.small
- AMI Type: AL2023_x86_64_STANDARD

## 🎯 Step 1: Create Launch Template

### Navigate to EC2 Console
1. **AWS Console** → **Services** → **EC2**
2. **Left Panel** → **Instances** → **Launch Templates**
3. **Click** → **Create launch template**

### Basic Configuration
4. **Launch template name**: `eks-workers-launch-template`
5. **Template version description**: `EKS workers for eks-terraform-cluster`
6. **Auto Scaling guidance**: ✅ **Check this box**

### Application and OS Images (AMI)
7. **Quick Start** → **Amazon Linux**
8. **Amazon Machine Image (AMI)**: 
   - Click **Browse more AMIs**
   - **AWS Marketplace AMIs** → Search: `amazon-eks-node-1.33`
   - Select: **Amazon EKS optimized Amazon Linux 2023 AMI**
   - **AMI ID**: `ami-0ed2e566705caa38e` (or latest)
   - **Select**

### Instance Type
9. **Instance type**: `t3.small`
10. **Key pair**: Select existing or create new (optional for EKS)

### Network Settings
11. **Subnet**: **Don't include in launch template** (managed by node group)
12. **Security groups**: **Don't include in launch template** (managed by EKS)
13. **Auto-assign public IP**: **Don't include in launch template**

### Storage (EBS Volumes)
14. **Volume 1 (AMI Root)**:
    - **Size**: `20 GiB`
    - **Volume type**: `gp3`
    - **Delete on termination**: ✅ **Yes**
    - **Encrypted**: ✅ **Yes** (recommended)

### Resource Tags
15. **Add tag**:
    - **Key**: `Name`
    - **Value**: `eks-worker-node`
    - **Resource types**: ✅ **Instances**, ✅ **Volumes**

16. **Add tag**:
    - **Key**: `kubernetes.io/cluster/eks-terraform-cluster`
    - **Value**: `owned`
    - **Resource types**: ✅ **Instances**

### Advanced Details
17. **IAM instance profile**: 
    - Select: `eks-terraform-cluster-node-group-role` (if available)
    - Or leave blank (will be managed by node group)

18. **User data** (Important for EKS):
```bash
#!/bin/bash
/etc/eks/bootstrap.sh eks-terraform-cluster
```

19. **Create launch template**

## 🎯 Step 2: Create New Node Group with Launch Template

### Navigate to EKS Console
1. **AWS Console** → **Services** → **EKS**
2. **Clusters** → **eks-terraform-cluster**
3. **Compute** → **Node groups**
4. **Add node group**

### Node Group Configuration
5. **Name**: `workers-with-launch-template`
6. **Node IAM role**: `eks-terraform-cluster-node-group-role`
7. **Next**

### Compute and Scaling Configuration
8. **AMI type**: **Custom AMI**
9. **Launch template**: 
   - **Launch template**: `eks-workers-launch-template`
   - **Version**: `1 (Default)`
10. **Instance types**: `t3.small`
11. **Capacity type**: **On-Demand**
12. **Disk size**: `20 GiB`

### Scaling Configuration
13. **Desired size**: `2`
14. **Minimum size**: `2`
15. **Maximum size**: `5`
16. **Next**

### Networking
17. **Subnets**: Select all 3 subnets (same as current node group)
18. **Configure remote access**: **Disable** (recommended)
19. **Next**

### Review and Create
20. **Review** all settings
21. **Create**

## 🎯 Step 3: Migrate from Old Node Group (Optional)

### Gradual Migration
1. **Scale up new node group**: Increase desired capacity to 4
2. **Wait for nodes**: Let new nodes join and become Ready
3. **Drain old nodes**: 
   ```bash
   kubectl drain <old-node-name> --ignore-daemonsets --delete-emptydir-data
   ```
4. **Scale down old node group**: Reduce to 0
5. **Delete old node group**: After verification

### Or Direct Replacement
1. **Delete old node group**: `workers`
2. **Rename new node group**: To `workers` (if needed)

## 🔍 Verification Steps

### Check Launch Template
1. **EC2 Console** → **Launch Templates**
2. **Select** → `eks-workers-launch-template`
3. **Actions** → **View launch template**
4. **Verify** all configurations

### Check Node Group
1. **EKS Console** → **eks-terraform-cluster** → **Node groups**
2. **Select** → `workers-with-launch-template`
3. **Details tab** → Verify launch template is used
4. **Resources tab** → Check Auto Scaling Group

### Check Nodes
```bash
# Check nodes are using launch template
kubectl get nodes -o wide

# Verify node labels and taints
kubectl describe nodes
```

## 🎯 Step 4: Update Launch Template (Future AMI Changes)

### Create New Version
1. **EC2 Console** → **Launch Templates** → `eks-workers-launch-template`
2. **Actions** → **Create template version**
3. **Source template version**: `1`
4. **Application and OS Images**: Select new AMI
5. **Create template version**

### Update Node Group
1. **EKS Console** → **Node groups** → `workers-with-launch-template`
2. **Update** → **Launch template**
3. **Version**: Select new version
4. **Update strategy**: Rolling update
5. **Update**

## 📋 Launch Template Configuration Summary

### Required Settings:
- ✅ **AMI**: EKS optimized AMI for K8s 1.33
- ✅ **Instance Type**: t3.small
- ✅ **Storage**: 20GB gp3, encrypted
- ✅ **User Data**: EKS bootstrap script
- ✅ **Tags**: Cluster ownership tags

### Optional Settings:
- **Key Pair**: For SSH access (not recommended)
- **Security Groups**: Managed by EKS
- **IAM Role**: Managed by node group
- **Monitoring**: CloudWatch detailed monitoring

### Don't Include:
- ❌ **Subnet**: Managed by node group
- ❌ **Security Groups**: Managed by EKS
- ❌ **Public IP**: Managed by subnet settings

## ⚠️ Important Notes

### Before Creating Launch Template:
- **Backup**: Note current node group settings
- **Timing**: Plan during maintenance window
- **Permissions**: Ensure IAM permissions for launch templates

### Launch Template Benefits:
- **Custom AMI**: Specify exact AMI versions
- **Advanced Configuration**: More control over instance settings
- **Version Management**: Easy AMI updates via template versions
- **Consistency**: Standardized node configuration

### User Data Script:
```bash
#!/bin/bash
/etc/eks/bootstrap.sh eks-terraform-cluster

# Optional: Additional customizations
# yum update -y
# echo "Custom configuration here"
```

## 🚨 Troubleshooting

### If Nodes Don't Join Cluster:
1. **Check User Data**: Ensure bootstrap script is correct
2. **Check IAM Role**: Verify node group role permissions
3. **Check Security Groups**: Ensure EKS communication allowed
4. **Check Subnets**: Verify subnet routing and NAT gateway

### If Launch Template Creation Fails:
1. **Check AMI**: Ensure AMI exists in ap-south-1
2. **Check Permissions**: Verify EC2 launch template permissions
3. **Check Quotas**: Ensure service limits not exceeded

### Common Issues:
- **Wrong AMI**: Use EKS optimized AMI only
- **Missing Bootstrap**: User data must include EKS bootstrap
- **Wrong Region**: AMI must be in same region (ap-south-1)
- **Security Groups**: Don't specify in launch template for EKS

## 🎯 Quick Reference

### Key AMI for K8s 1.33:
```
AMI ID: ami-0ed2e566705caa38e
Name: amazon-eks-node-1.33-v20251217
```

### Required User Data:
```bash
#!/bin/bash
/etc/eks/bootstrap.sh eks-terraform-cluster
```

### Essential Tags:
```
kubernetes.io/cluster/eks-terraform-cluster = owned
k8s.io/cluster-autoscaler/enabled = true
k8s.io/cluster-autoscaler/eks-terraform-cluster = owned
```

---

**⏱️ Estimated Time**: 10-15 minutes to create launch template and new node group
**💡 Benefit**: Full control over AMI versions and instance configuration
**🔄 Migration**: Can be done gradually with zero downtime
