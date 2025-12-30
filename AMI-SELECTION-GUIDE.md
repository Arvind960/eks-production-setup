# EKS AMI Selection Guide

## When Manual AMI Selection is Required vs Automatic

### ✅ **AUTOMATIC AMI Selection (Your Case):**
**EKS Managed Node Groups** - AWS handles everything

```yaml
# In your Terraform - NO AMI specified
resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "workers"
  # NO ami_id specified - AWS selects automatically
  instance_types  = ["t3.small"]
  version         = "1.32"  # AWS picks compatible AMI
}
```

### ❌ **MANUAL AMI Selection Required:**
**Self-Managed Node Groups** or **Custom Launch Templates**

```yaml
# Self-managed nodes - YOU must specify AMI
resource "aws_launch_template" "custom" {
  name_prefix   = "eks-custom-"
  image_id      = "ami-0f81ee05296e6093d"  # Manual selection needed
  instance_type = "t3.small"
}
```

## How to Find EKS-Optimized AMIs (If Needed)

### Method 1: AWS CLI
```bash
# Get latest EKS-optimized AMI for K8s 1.32
aws ssm get-parameter \
  --name /aws/service/eks/optimized-ami/1.32/amazon-linux-2/recommended/image_id \
  --region ap-south-1 \
  --query 'Parameter.Value' \
  --output text
```

### Method 2: AWS Console
1. Go to EC2 → AMIs
2. Filter: `Public images`
3. Search: `amazon-eks-node-1.32`
4. Owner: `amazon`

### Method 3: Terraform Data Source
```hcl
data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-1.32-v*"]
  }
  most_recent = true
  owners      = ["602401143452"] # Amazon
}
```

## Your Current Setup Analysis

### ✅ **What You Have:**
```
Node Group Type: EKS Managed Node Group
AMI Selection: Automatic by AWS
Current AMI: ami-0f81ee05296e6093d (K8s 1.32)
Status: ✅ Working correctly
```

### 🎯 **Recommendation:**
**Keep using EKS Managed Node Groups** - No manual AMI management needed!

## When to Consider Manual AMI Selection

### Use Cases for Custom AMIs:
1. **Custom software** pre-installed
2. **Specific security requirements**
3. **Custom kernel configurations**
4. **Compliance requirements**

### Stick with Managed if:
- ✅ Standard EKS workloads
- ✅ Want automatic updates
- ✅ Simplified management
- ✅ AWS handles security patches
