# Quick Reference: EKS 1.32 Component Versions

## Get Latest Versions Commands

### Cluster Autoscaler
```bash
# Get latest release
curl -s https://api.github.com/repos/kubernetes/autoscaler/releases/latest | grep tag_name

# For K8s 1.32, use: v1.32.0
```

### EKS Add-ons (AWS CLI)
```bash
# CoreDNS
aws eks describe-addon-versions --addon-name coredns --kubernetes-version 1.32 --query 'addons[0].addonVersions[0].addonVersion' --output text

# VPC CNI
aws eks describe-addon-versions --addon-name vpc-cni --kubernetes-version 1.32 --query 'addons[0].addonVersions[0].addonVersion' --output text

# kube-proxy
aws eks describe-addon-versions --addon-name kube-proxy --kubernetes-version 1.32 --query 'addons[0].addonVersions[0].addonVersion' --output text
```

### Metrics Server
```bash
# Get latest release
curl -s https://api.github.com/repos/kubernetes-sigs/metrics-server/releases/latest | grep tag_name

# Current stable: v0.7.2
```

## AWS Console URLs

### EKS Console (ap-south-1)
https://ap-south-1.console.aws.amazon.com/eks/home?region=ap-south-1#/clusters

### EC2 Auto Scaling Groups
https://ap-south-1.console.aws.amazon.com/ec2/home?region=ap-south-1#AutoScalingGroups:

### CloudWatch Logs
https://ap-south-1.console.aws.amazon.com/cloudwatch/home?region=ap-south-1#logsV2:log-groups

## Version Matrix (Updated: Dec 2024)
```
Kubernetes 1.32 Compatible Versions:
├── Cluster Autoscaler: v1.32.0
├── CoreDNS: v1.11.3-eksbuild.1
├── VPC CNI: v1.19.0-eksbuild.1
├── kube-proxy: v1.32.0-eksbuild.2
└── Metrics Server: v0.7.2
```
