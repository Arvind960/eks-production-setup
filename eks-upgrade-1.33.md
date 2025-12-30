# EKS Upgrade to Kubernetes 1.33 Documentation

## 📋 Overview

This document outlines the successful upgrade of our EKS cluster from Kubernetes 1.32 to 1.33, including all components and verification steps.

**Cluster**: `eks-terraform-cluster`  
**Region**: `ap-south-1`  
**Upgrade Date**: December 30, 2025  
**Status**: ✅ **Successfully Completed**

## 🎯 Upgrade Summary

### What Was Upgraded:
- **EKS Control Plane**: 1.32 → 1.33
- **Worker Nodes**: 1.32.x → 1.33.5-eks-ecaa3a6
- **Cluster Autoscaler**: v1.32.5 → v1.33.3
- **Platform Version**: Updated to eks.24

### Components Verified:
- ✅ EKS Control Plane
- ✅ Worker Nodes (2 nodes)
- ✅ Cluster Autoscaler
- ✅ Metrics Server
- ✅ Horizontal Pod Autoscaler (HPA)
- ✅ Sample Applications

## 🔧 Pre-Upgrade Configuration

### Cluster Details:
```yaml
Cluster Name: eks-terraform-cluster
Region: ap-south-1
Node Type: t3.small
Min Nodes: 2
Max Nodes: 5
Kubernetes Version: 1.32
```

### Key Components:
- **Cluster Autoscaler**: v1.32.5
- **Metrics Server**: v0.8.0
- **HPA Configuration**: CPU 70%, Memory 80%
- **Sample App**: 2-10 replicas

## 📝 Upgrade Steps Performed

### 1. Control Plane Upgrade
```bash
# Upgrade was performed via Terraform/AWS Console
# Control plane automatically updated to 1.33
aws eks describe-cluster --name eks-terraform-cluster --region ap-south-1
```

### 2. Node Group Upgrade
```bash
# Worker nodes upgraded to 1.33.5-eks-ecaa3a6
# New AMI: ami-0ed2e566705caa38e
kubectl get nodes
```

### 3. Cluster Autoscaler Update
```bash
# Updated cluster autoscaler image
kubectl set image deployment/cluster-autoscaler \
  cluster-autoscaler=registry.k8s.io/autoscaling/cluster-autoscaler:v1.33.3 \
  -n kube-system
```

## ✅ Post-Upgrade Verification

### Cluster Status:
```bash
# Control Plane
aws eks describe-cluster --name eks-terraform-cluster --region ap-south-1
# Output: "version": "1.33"

# Worker Nodes
kubectl get nodes
# Output: v1.33.5-eks-ecaa3a6 (2 nodes Ready)
```

### Component Health Check:
```bash
# Cluster Autoscaler
kubectl get deployment cluster-autoscaler -n kube-system
# Status: 1/1 Ready, Image: v1.33.3

# Metrics Server
kubectl get deployment metrics-server -n kube-system
# Status: 1/1 Ready, Image: v0.8.0

# HPA Status
kubectl get hpa
# sample-app-hpa: cpu: 0%/70%, memory: 2%/80%
```

### Resource Utilization:
```bash
# Node Resources
kubectl top nodes
# CPU: 2-3%, Memory: 51-55% (Healthy)

# Pod Resources
kubectl top pods
# All system pods running normally
```

## 🔍 Verification Commands

### Quick Health Check:
```bash
# Cluster version
kubectl version --short

# Node status
kubectl get nodes -o wide

# System pods
kubectl get pods -n kube-system

# HPA status
kubectl get hpa

# Resource usage
kubectl top nodes
kubectl top pods
```

### Detailed Component Check:
```bash
# Cluster Autoscaler logs
kubectl logs deployment/cluster-autoscaler -n kube-system --tail=20

# Metrics Server logs
kubectl logs deployment/metrics-server -n kube-system --tail=20

# Cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 📊 Current Configuration

### Cluster Specifications:
- **Kubernetes Version**: 1.33
- **Platform Version**: eks.24
- **Worker Nodes**: 2 x t3.small (Ready)
- **Container Runtime**: containerd://2.1.5
- **OS Image**: Amazon Linux 2023.9.20251208

### Auto-Scaling Configuration:
- **Node Scaling**: 2-5 nodes (Cluster Autoscaler v1.33.3)
- **Pod Scaling**: 2-10 replicas (HPA active)
- **Metrics**: CPU 70%, Memory 80% thresholds

### Network Configuration:
- **VPC**: vpc-077708cb82748a9e4
- **Subnets**: 3 subnets across AZs
- **Security Group**: sg-00ead2fb331c629aa
- **Service CIDR**: 10.100.0.0/16

## 🚨 Known Issues & Resolutions

### Issue 1: Cluster Autoscaler Compatibility
**Problem**: Initial cluster autoscaler v1.32.5 with K8s 1.33  
**Resolution**: Updated to v1.33.3 for full compatibility  
**Status**: ✅ Resolved

### Issue 2: Node Readiness
**Problem**: Brief node NotReady during upgrade  
**Resolution**: Automatic recovery after AMI update  
**Status**: ✅ Resolved

## 🔧 Troubleshooting Guide

### If HPA Shows Unknown Metrics:
```bash
kubectl get apiservice v1beta1.metrics.k8s.io
kubectl logs deployment/metrics-server -n kube-system
```

### If Cluster Autoscaler Not Scaling:
```bash
kubectl logs deployment/cluster-autoscaler -n kube-system
kubectl describe nodes
```

### If Pods Stuck in Pending:
```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 📈 Performance Metrics

### Before Upgrade (1.32):
- **Node Version**: v1.32.x-eks-xxx
- **Cluster Autoscaler**: v1.32.5
- **Performance**: Baseline established

### After Upgrade (1.33):
- **Node Version**: v1.33.5-eks-ecaa3a6
- **Cluster Autoscaler**: v1.33.3
- **Performance**: ✅ Maintained/Improved
- **Resource Usage**: CPU 2-3%, Memory 51-55%

## 🔐 Security Enhancements

### Kubernetes 1.33 Security Features:
- Enhanced RBAC capabilities
- Improved pod security standards
- Updated container runtime security
- Latest CVE patches included

### Current Security Configuration:
- **IRSA**: Enabled for service accounts
- **Network Policies**: VPC security groups
- **Resource Limits**: Enforced on all pods
- **Image Security**: Official registry images only

## 💰 Cost Impact

### Resource Costs (Unchanged):
- **Base Cost**: ~$30/month (2 x t3.small)
- **Peak Cost**: ~$75/month (5 x t3.small)
- **Optimization**: Auto-scaling maintains cost efficiency

### Upgrade Costs:
- **Downtime**: Minimal (rolling updates)
- **Additional Charges**: None
- **ROI**: Enhanced security and features

## 📅 Maintenance Schedule

### Regular Checks:
- **Weekly**: Resource utilization monitoring
- **Monthly**: Security patch review
- **Quarterly**: Performance optimization review

### Next Upgrade Planning:
- **Target**: Kubernetes 1.34 (when available)
- **Timeline**: Q2 2026 (estimated)
- **Preparation**: Monitor 1.34 release notes

## 📞 Support Information

### Escalation Path:
1. **Level 1**: Check logs and events
2. **Level 2**: AWS EKS support documentation
3. **Level 3**: AWS Premium Support (if available)

### Key Contacts:
- **Infrastructure Team**: [Team Contact]
- **AWS Account Manager**: [Contact Info]
- **Emergency Escalation**: [24/7 Contact]

## 📚 References

### Documentation:
- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Kubernetes 1.33 Release Notes](https://kubernetes.io/releases/notes/)
- [Cluster Autoscaler Documentation](https://github.com/kubernetes/autoscaler)

### Internal Resources:
- Terraform Configuration: `./terraform/`
- Application Manifests: `./hpa-demo.yaml`
- Load Testing: `./load-generator.yaml`

---

## ✅ Upgrade Completion Checklist

- [x] Control plane upgraded to 1.33
- [x] Worker nodes updated to 1.33.5-eks-ecaa3a6
- [x] Cluster autoscaler updated to v1.33.3
- [x] Metrics server verified working
- [x] HPA functionality confirmed
- [x] Sample applications running
- [x] Resource utilization normal
- [x] Auto-scaling tested and working
- [x] Security configurations maintained
- [x] Documentation updated

**Upgrade Status**: ✅ **SUCCESSFULLY COMPLETED**  
**Verification Date**: December 30, 2025  
**Next Review**: January 30, 2026

---

*This document serves as the official record of the EKS 1.33 upgrade for the eks-terraform-cluster.*
