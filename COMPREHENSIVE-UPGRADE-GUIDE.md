# EKS Cluster Component Upgrade Guide - Kubernetes 1.25 → 1.32

## Current Cluster Analysis

### Current Versions:
```
Cluster Version: v1.25.15-eks-4f4795d
Node Version: v1.25.12-eks-8ccc7ba
kubectl Client: v1.25.12
```

### Components Requiring Updates:

| Component | Current Version | Target Version | Status |
|-----------|----------------|----------------|---------|
| VPC CNI | v1.14.0-eksbuild.3 | v1.19.0-eksbuild.1 | ❌ Update Required |
| AWS Load Balancer Controller | v2.4.7 | v2.8.1 | ❌ Update Required |
| CoreDNS | v1.9.3-eksbuild.6 | v1.11.3-eksbuild.1 | ❌ Update Required |
| kube-proxy | v1.25.11-minimal-eksbuild.2 | v1.32.0-eksbuild.2 | ❌ Update Required |
| Cluster Autoscaler | v1.25.0 | v1.32.0 | ❌ Update Required |
| kubectl | v1.25.12 | v1.32.0 | ❌ Update Required |

## Step-by-Step Upgrade Process

### Step 1: Update kubectl Client

```bash
# Download kubectl v1.32.0
curl -LO https://dl.k8s.io/release/v1.32.0/bin/linux/amd64/kubectl

# Make executable and install
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bash_profile

# Verify installation
kubectl version --client
```

### Step 2: Upgrade EKS Control Plane (AWS Console)

1. **Navigate to EKS Console**
   - Go to: https://console.aws.amazon.com/eks/
   - Select your cluster

2. **Upgrade Path** (Must be done incrementally):
   ```
   1.25 → 1.26 → 1.27 → 1.28 → 1.29 → 1.30 → 1.31 → 1.32
   ```

3. **For each version upgrade:**
   - Click "Update cluster version"
   - Select next version
   - Wait for completion (10-15 minutes each)

### Step 3: Upgrade Node Groups

After each control plane upgrade:
```bash
# Check node group
aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name>

# Upgrade node group
aws eks update-nodegroup-version --cluster-name <cluster-name> --nodegroup-name <nodegroup-name>
```

### Step 4: Update VPC CNI

```bash
# Check current version
kubectl describe ds aws-node -n kube-system | grep Image:

# Update via AWS CLI
aws eks update-addon \
  --cluster-name <cluster-name> \
  --addon-name vpc-cni \
  --addon-version v1.19.0-eksbuild.1 \
  --resolve-conflicts OVERWRITE

# Or via kubectl
kubectl set image daemonset aws-node \
  -n kube-system \
  aws-node=602401143452.dkr.ecr.ap-south-1.amazonaws.com/amazon-k8s-cni:v1.19.0-eksbuild.1

kubectl set image daemonset aws-node \
  -n kube-system \
  aws-node-init=602401143452.dkr.ecr.ap-south-1.amazonaws.com/amazon-k8s-cni-init:v1.19.0-eksbuild.1
```

### Step 5: Update AWS Load Balancer Controller

```bash
# Check current version
kubectl describe pod -l app.kubernetes.io/name=aws-load-balancer-controller -n kube-system | grep Image:

# Update image
kubectl set image deployment/aws-load-balancer-controller \
  -n kube-system \
  controller=602401143452.dkr.ecr.ap-south-1.amazonaws.com/amazon/aws-load-balancer-controller:v2.8.1

# Verify rollout
kubectl rollout status deployment/aws-load-balancer-controller -n kube-system
```

### Step 6: Update CoreDNS

```bash
# Update via AWS CLI
aws eks update-addon \
  --cluster-name <cluster-name> \
  --addon-name coredns \
  --addon-version v1.11.3-eksbuild.1 \
  --resolve-conflicts OVERWRITE

# Or via kubectl
kubectl set image deployment/coredns \
  -n kube-system \
  coredns=602401143452.dkr.ecr.ap-south-1.amazonaws.com/eks/coredns:v1.11.3-eksbuild.1
```

### Step 7: Update kube-proxy

```bash
# Update via AWS CLI
aws eks update-addon \
  --cluster-name <cluster-name> \
  --addon-name kube-proxy \
  --addon-version v1.32.0-eksbuild.2 \
  --resolve-conflicts OVERWRITE

# Or via kubectl
kubectl set image daemonset/kube-proxy \
  -n kube-system \
  kube-proxy=602401143452.dkr.ecr.ap-south-1.amazonaws.com/eks/kube-proxy:v1.32.0-minimal-eksbuild.2
```

### Step 8: Update Cluster Autoscaler

```bash
# Update image
kubectl set image deployment/cluster-autoscaler \
  -n kube-system \
  cluster-autoscaler=registry.k8s.io/autoscaling/cluster-autoscaler:v1.32.0

# Restart deployment
kubectl rollout restart deployment/cluster-autoscaler -n kube-system

# Verify
kubectl rollout status deployment/cluster-autoscaler -n kube-system
```

## Component Version Reference Links

### Official Documentation:
- **VPC CNI**: https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html
- **CoreDNS**: https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
- **kube-proxy**: https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html
- **EKS Add-ons**: https://docs.aws.amazon.com/eks/latest/userguide/managing-add-ons.html

### GitHub Releases:
- **AWS Load Balancer Controller**: https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases
- **Cluster Autoscaler**: https://github.com/kubernetes/autoscaler/releases
- **kubectl**: https://github.com/kubernetes/kubernetes/releases

## Version Compatibility Matrix

### Kubernetes 1.32 Compatible Versions:
```
Component                    Version
─────────────────────────────────────────────
VPC CNI                     v1.19.0-eksbuild.1
AWS Load Balancer Controller v2.8.1
CoreDNS                     v1.11.3-eksbuild.1
kube-proxy                  v1.32.0-eksbuild.2
Cluster Autoscaler          v1.32.0
kubectl                     v1.32.0
```

## Verification Commands

### Check All Component Versions:
```bash
# Cluster version
kubectl version

# Node versions
kubectl get nodes -o wide

# VPC CNI
kubectl describe ds aws-node -n kube-system | grep Image:

# AWS Load Balancer Controller
kubectl describe deployment aws-load-balancer-controller -n kube-system | grep Image:

# CoreDNS
kubectl describe deployment coredns -n kube-system | grep Image:

# kube-proxy
kubectl describe ds kube-proxy -n kube-system | grep Image:

# Cluster Autoscaler
kubectl describe deployment cluster-autoscaler -n kube-system | grep Image:

# Check all pods
kubectl get pods -n kube-system -o wide
```

### Get Latest Versions via AWS CLI:
```bash
# VPC CNI latest version
aws eks describe-addon-versions --addon-name vpc-cni --kubernetes-version 1.32 --query 'addons[0].addonVersions[0].addonVersion' --output text

# CoreDNS latest version
aws eks describe-addon-versions --addon-name coredns --kubernetes-version 1.32 --query 'addons[0].addonVersions[0].addonVersion' --output text

# kube-proxy latest version
aws eks describe-addon-versions --addon-name kube-proxy --kubernetes-version 1.32 --query 'addons[0].addonVersions[0].addonVersion' --output text
```

## Troubleshooting

### Common Issues:

1. **Pod Disruption Budgets Blocking Updates**
   ```bash
   # Check PDBs
   kubectl get poddisruptionbudgets -A
   
   # Temporarily delete if blocking
   kubectl delete pdb <pdb-name> -n <namespace>
   ```

2. **Image Pull Errors**
   ```bash
   # Check node IAM permissions
   # Verify ECR access
   # Check image tags and availability
   ```

3. **Rolling Update Stuck**
   ```bash
   # Check node capacity
   # Verify resource requests
   # Check node taints and tolerations
   ```

### Rollback Commands:
```bash
# Rollback deployment
kubectl rollout undo deployment/<deployment-name> -n kube-system

# Check rollout history
kubectl rollout history deployment/<deployment-name> -n kube-system
```

## Post-Upgrade Checklist

- [ ] All pods running in kube-system namespace
- [ ] Nodes showing correct Kubernetes version
- [ ] Applications functioning normally
- [ ] Load balancer controller working
- [ ] Cluster autoscaler scaling properly
- [ ] DNS resolution working (CoreDNS)
- [ ] Network connectivity (VPC CNI)
- [ ] Monitoring and logging operational

## Important Notes

1. **Incremental Upgrades**: EKS requires incremental version upgrades (1.25→1.26→1.27...→1.32)
2. **Component Compatibility**: Always check component compatibility with target Kubernetes version
3. **Testing**: Test in non-production environment first
4. **Backup**: Backup critical workloads before upgrade
5. **Monitoring**: Monitor cluster health during and after upgrade
