#!/bin/bash

# EKS Component Version Checker Script
# This script checks current versions of all EKS components

CLUSTER_NAME="your-cluster-name"  # Replace with your cluster name
REGION="ap-south-1"

echo "🔍 EKS Cluster Component Version Analysis"
echo "=========================================="

# Function to get image from deployment/daemonset
get_image() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    local container_name=$4
    
    kubectl get $resource_type $resource_name -n $namespace -o jsonpath="{.spec.template.spec.containers[?(@.name=='$container_name')].image}" 2>/dev/null
}

# Cluster Version
echo "📋 Cluster Information:"
echo "======================"
kubectl version --short 2>/dev/null || kubectl version
echo ""

echo "📋 Node Information:"
echo "==================="
kubectl get nodes -o wide
echo ""

# VPC CNI
echo "🔧 VPC CNI:"
echo "==========="
echo "Current Images:"
kubectl describe ds aws-node -n kube-system | grep "Image:" | head -2
echo ""
echo "Latest Available:"
aws eks describe-addon-versions --addon-name vpc-cni --kubernetes-version 1.32 --region $REGION --query 'addons[0].addonVersions[0].addonVersion' --output text 2>/dev/null || echo "Check manually"
echo ""

# AWS Load Balancer Controller
echo "⚖️  AWS Load Balancer Controller:"
echo "================================"
LBC_POD=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$LBC_POD" ]; then
    echo "Current Image:"
    kubectl describe pod $LBC_POD -n kube-system | grep "Image:" | head -1
    echo "Latest Release: Check https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases"
else
    echo "AWS Load Balancer Controller not found"
fi
echo ""

# CoreDNS
echo "🌐 CoreDNS:"
echo "==========="
echo "Current Image:"
kubectl describe deployment coredns -n kube-system | grep "Image:" | head -1
echo ""
echo "Latest Available:"
aws eks describe-addon-versions --addon-name coredns --kubernetes-version 1.32 --region $REGION --query 'addons[0].addonVersions[0].addonVersion' --output text 2>/dev/null || echo "Check manually"
echo ""

# kube-proxy
echo "🔄 kube-proxy:"
echo "=============="
echo "Current Image:"
kubectl describe ds kube-proxy -n kube-system | grep "Image:" | head -1
echo ""
echo "Latest Available:"
aws eks describe-addon-versions --addon-name kube-proxy --kubernetes-version 1.32 --region $REGION --query 'addons[0].addonVersions[0].addonVersion' --output text 2>/dev/null || echo "Check manually"
echo ""

# Cluster Autoscaler
echo "📈 Cluster Autoscaler:"
echo "====================="
CA_POD=$(kubectl get pods -n kube-system -l app=cluster-autoscaler -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$CA_POD" ]; then
    echo "Current Image:"
    kubectl describe pod $CA_POD -n kube-system | grep "Image:" | head -1
    echo "Latest Release: Check https://github.com/kubernetes/autoscaler/releases"
else
    echo "Cluster Autoscaler not found"
fi
echo ""

# Metrics Server
echo "📊 Metrics Server:"
echo "=================="
MS_POD=$(kubectl get pods -n kube-system -l k8s-app=metrics-server -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$MS_POD" ]; then
    echo "Current Image:"
    kubectl describe pod $MS_POD -n kube-system | grep "Image:" | head -1
else
    echo "Metrics Server not found"
fi
echo ""

# Pod Disruption Budgets
echo "🛡️  Pod Disruption Budgets:"
echo "==========================="
kubectl get poddisruptionbudgets -A
echo ""

# EKS Add-ons
echo "🔌 EKS Add-ons:"
echo "==============="
aws eks list-addons --cluster-name $CLUSTER_NAME --region $REGION 2>/dev/null || echo "Unable to list add-ons - check cluster name and AWS credentials"
echo ""

echo "✅ Analysis Complete!"
echo ""
echo "📝 Next Steps:"
echo "1. Update kubectl client to match target Kubernetes version"
echo "2. Upgrade EKS control plane incrementally"
echo "3. Upgrade node groups"
echo "4. Update components as identified above"
echo "5. Verify all components are working correctly"
