# How to Find EKS AMI in AWS Console GUI - Step by Step

## 📋 Overview
Complete GUI steps to find the correct EKS-optimized AMI for your launch template.

**For your setup (t3.small, K8s 1.33):**
- **Architecture**: x86_64 (not arm64)
- **Kubernetes Version**: 1.33
- **Instance Type**: t3.small

## 🎯 Method 1: EC2 Console AMI Search

### Step 1: Navigate to EC2 Console
1. **AWS Console** → **Services** → **EC2**
2. **Left Panel** → **Images** → **AMIs**

### Step 2: Set Search Filters
3. **Owner**: Select **Amazon images** (not "My AMIs")
4. **Search bar**: Type `amazon-eks-node-al2023-x86_64-standard-1.33`
5. **Architecture**: Select **x86_64** (important for t3.small)

### Step 3: Find the Latest AMI
6. **Sort by**: **Creation date** (newest first)
7. **Look for**: `amazon-eks-node-al2023-x86_64-standard-1.33-v20251120`
8. **AMI ID**: `ami-00a0aaccfeeec68e2` (latest as of Dec 2025)

## 🎯 Method 2: Launch Template Creation (Recommended)

### Step 1: Start Launch Template Creation
1. **EC2 Console** → **Launch Templates** → **Create launch template**
2. **Name**: `eks-workers-launch-template-fixed`

### Step 2: AMI Selection Process
3. **Application and OS Images** → **Browse more AMIs**
4. **Search**: Type `amazon-eks-node-1.33`
5. **Filter by Owner**: **Amazon**
6. **Filter by Architecture**: **x86_64**

### Step 3: Select Correct AMI
7. **Look for**: `amazon-eks-node-al2023-x86_64-standard-1.33-v20251120`
8. **Verify Details**:
   - **Owner**: Amazon (602401143452)
   - **Architecture**: x86_64
   - **Kubernetes**: 1.33.5
   - **Container Runtime**: containerd 2.1.*
9. **Select** this AMI

## 🎯 Method 3: AWS Systems Manager Parameter Store

### Step 1: Navigate to Systems Manager
1. **AWS Console** → **Services** → **Systems Manager**
2. **Left Panel** → **Parameter Store**

### Step 2: Find EKS Parameter
3. **Search**: `/aws/service/eks/optimized-ami/1.33`
4. **Look for**: `/aws/service/eks/optimized-ami/1.33/amazon-linux-2/recommended/image_id`
5. **Click** on the parameter
6. **Copy** the AMI ID from the **Value** field

## 📋 Available EKS 1.33 AMIs for x86_64

### **Standard AMIs (Recommended for t3.small):**

1. **Latest Standard AMI** ⭐ **RECOMMENDED**
   - **AMI ID**: `ami-00a0aaccfeeec68e2`
   - **Name**: `amazon-eks-node-al2023-x86_64-standard-1.33-v20251120`
   - **K8s Version**: 1.33.5
   - **Date**: Nov 20, 2025

2. **Alternative Standard AMIs:**
   - **AMI ID**: `ami-029d77045a5834039`
   - **Name**: `amazon-eks-node-al2023-x86_64-standard-1.33-v20250920`
   - **K8s Version**: 1.33.5

### **Specialized AMIs (Only if needed):**

3. **NVIDIA GPU Support:**
   - **AMI ID**: `ami-00b9ccf4e2be258ef`
   - **Name**: `amazon-eks-node-al2023-x86_64-nvidia-1.33-v20251029`

4. **Neuron (AI/ML):**
   - **AMI ID**: `ami-02f2b9fd25ea7dff0`
   - **Name**: `amazon-eks-node-al2023-x86_64-neuron-1.33-v20251023`

## 🔍 How to Verify AMI Details in GUI

### In AMI Details Page:
1. **Click** on the AMI ID
2. **Verify**:
   - **Architecture**: x86_64 ✅
   - **Virtualization**: hvm ✅
   - **Root device type**: ebs ✅
   - **Owner**: 602401143452 (Amazon) ✅
   - **Description**: Contains "k8s: 1.33" ✅

### Key Details to Check:
- ✅ **Owner**: Amazon (602401143452)
- ✅ **Architecture**: x86_64 (not arm64)
- ✅ **Name contains**: `1.33` and `standard`
- ✅ **Description**: "EKS-optimized Kubernetes node"
- ✅ **State**: available

## 🚨 Common Mistakes to Avoid

### ❌ **Wrong Architecture:**
- Don't select **arm64** AMIs (for Graviton processors)
- t3.small requires **x86_64**

### ❌ **Wrong AMI Type:**
- Don't use **ECS** AMIs (like you did before)
- Don't use **nvidia** AMIs unless you need GPU
- Don't use **neuron** AMIs unless you need AI/ML

### ❌ **Wrong Kubernetes Version:**
- Don't use 1.32 or 1.34 AMIs
- Must match your cluster version (1.33)

### ❌ **Wrong Owner:**
- Don't use community AMIs
- Only use Amazon-owned AMIs

## 🎯 Quick Search Strings for GUI

### In EC2 AMI Search:
```
amazon-eks-node-al2023-x86_64-standard-1.33
```

### In Launch Template AMI Browser:
```
amazon-eks-node-1.33
```

### Filter Settings:
- **Owner**: Amazon
- **Architecture**: x86_64
- **State**: available

## ✅ Final Verification Steps

### Before Using AMI:
1. **Double-check AMI ID**: `ami-00a0aaccfeeec68e2`
2. **Verify Architecture**: x86_64
3. **Confirm K8s Version**: 1.33.5
4. **Check Owner**: Amazon (602401143452)
5. **Ensure State**: available

### After Selecting AMI:
1. **Remove Security Groups** from launch template
2. **Enable EBS Encryption**
3. **Add proper User Data**:
   ```bash
   #!/bin/bash
   /etc/eks/bootstrap.sh eks-terraform-cluster
   ```
4. **Add required tags**

## 🔧 Fix Your Current Launch Template

### Create New Version:
1. **EC2 Console** → **Launch Templates** → `eks-workers-launch-template`
2. **Actions** → **Create template version**
3. **Source version**: 1
4. **AMI**: Change to `ami-00a0aaccfeeec68e2`
5. **Security groups**: **Remove** (leave blank)
6. **Storage**: Enable **encryption**
7. **Create template version**

## 📱 Mobile/Tablet GUI Tips

### If using mobile AWS Console:
1. **Use landscape mode** for better visibility
2. **AMI search** may be in **hamburger menu**
3. **Filters** might be in **collapsed menu**
4. **Consider using desktop** for complex configurations

---

## 🎯 **RECOMMENDED AMI FOR YOUR SETUP:**

**AMI ID**: `ami-00a0aaccfeeec68e2`  
**Name**: `amazon-eks-node-al2023-x86_64-standard-1.33-v20251120`  
**Perfect for**: t3.small instances with EKS 1.33

This AMI is the **latest standard EKS-optimized AMI** for Kubernetes 1.33 on x86_64 architecture.
