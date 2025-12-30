#!/bin/bash

# EKS Cluster Upgrade Script: 1.31 → 1.32
# This script upgrades the EKS cluster and all components to Kubernetes 1.32

set -e

CLUSTER_NAME="eks-terraform-cluster"
REGION="ap-south-1"
NEW_VERSION="1.32"

echo "🚀 EKS Cluster Upgrade to Kubernetes ${NEW_VERSION}"
echo "=================================================="

# Function to check update status
check_update_status() {
    local update_id=$1
    local update_type=$2
    
    echo "⏳ Checking ${update_type} update status..."
    
    while true; do
        status=$(aws eks describe-update --name ${CLUSTER_NAME} --update-id ${update_id} --region ${REGION} --query 'update.status' --output text)
        
        case $status in
            "Successful")
                echo "✅ ${update_type} update completed successfully!"
                break
                ;;
            "Failed")
                echo "❌ ${update_type} update failed!"
                aws eks describe-update --name ${CLUSTER_NAME} --update-id ${update_id} --region ${REGION} --query 'update.errors'
                exit 1
                ;;
            "InProgress")
                echo "⏳ ${update_type} update in progress... ($(date))"
                sleep 30
                ;;
            *)
                echo "⚠️  Unknown status: $status"
                sleep 30
                ;;
        esac
    done
}

# Step 1: Check if control plane upgrade is in progress
echo "📋 Checking current cluster status..."
current_updates=$(aws eks list-updates --name ${CLUSTER_NAME} --region ${REGION} --query 'updateIds' --output text)

if [ ! -z "$current_updates" ]; then
    echo "🔄 Found existing update in progress: $current_updates"
    check_update_status $current_updates "Control Plane"
fi

# Step 2: Verify control plane version
echo "📋 Verifying control plane version..."
current_version=$(aws eks describe-cluster --name ${CLUSTER_NAME} --region ${REGION} --query 'cluster.version' --output text)
echo "Current version: $current_version"

if [ "$current_version" != "$NEW_VERSION" ]; then
    echo "❌ Control plane is not at version ${NEW_VERSION}. Please wait for the upgrade to complete."
    exit 1
fi

# Step 3: Update kubeconfig
echo "🔧 Updating kubeconfig..."
aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}

# Step 4: Upgrade node groups
echo "🔄 Upgrading node groups..."
node_groups=$(aws eks list-nodegroups --cluster-name ${CLUSTER_NAME} --region ${REGION} --query 'nodegroups' --output text)

for node_group in $node_groups; do
    echo "🔄 Checking node group: ${node_group}"
    
    current_ng_version=$(aws eks describe-nodegroup --cluster-name ${CLUSTER_NAME} --nodegroup-name ${node_group} --region ${REGION} --query 'nodegroup.version' --output text)
    
    if [ "$current_ng_version" != "$NEW_VERSION" ]; then
        echo "🚀 Upgrading node group ${node_group} from ${current_ng_version} to ${NEW_VERSION}..."
        update_id=$(aws eks update-nodegroup-version --cluster-name ${CLUSTER_NAME} --nodegroup-name ${node_group} --region ${REGION} --query 'update.id' --output text)
        echo "📝 Node group ${node_group} update ID: ${update_id}"
        check_update_status ${update_id} "Node Group ${node_group}"
    else
        echo "✅ Node group ${node_group} is already at version ${NEW_VERSION}"
    fi
done

# Step 5: Update EKS add-ons
echo "🔧 Updating EKS add-ons..."

# List current add-ons
echo "📋 Current add-ons:"
aws eks list-addons --cluster-name ${CLUSTER_NAME} --region ${REGION} --output table

# Update kube-proxy
echo "🔄 Updating kube-proxy..."
if aws eks describe-addon --cluster-name ${CLUSTER_NAME} --addon-name kube-proxy --region ${REGION} >/dev/null 2>&1; then
    kube_proxy_version=$(aws eks describe-addon-versions --addon-name kube-proxy --kubernetes-version ${NEW_VERSION} --region ${REGION} --query 'addons[0].addonVersions[0].addonVersion' --output text)
    aws eks update-addon --cluster-name ${CLUSTER_NAME} --addon-name kube-proxy --addon-version ${kube_proxy_version} --region ${REGION} --resolve-conflicts OVERWRITE || echo "⚠️  kube-proxy update failed or not needed"
else
    echo "ℹ️  kube-proxy add-on not installed"
fi

# Update CoreDNS
echo "🔄 Updating CoreDNS..."
if aws eks describe-addon --cluster-name ${CLUSTER_NAME} --addon-name coredns --region ${REGION} >/dev/null 2>&1; then
    coredns_version=$(aws eks describe-addon-versions --addon-name coredns --kubernetes-version ${NEW_VERSION} --region ${REGION} --query 'addons[0].addonVersions[0].addonVersion' --output text)
    aws eks update-addon --cluster-name ${CLUSTER_NAME} --addon-name coredns --addon-version ${coredns_version} --region ${REGION} --resolve-conflicts OVERWRITE || echo "⚠️  CoreDNS update failed or not needed"
else
    echo "ℹ️  CoreDNS add-on not installed"
fi

# Update VPC CNI
echo "🔄 Updating VPC CNI..."
if aws eks describe-addon --cluster-name ${CLUSTER_NAME} --addon-name vpc-cni --region ${REGION} >/dev/null 2>&1; then
    vpc_cni_version=$(aws eks describe-addon-versions --addon-name vpc-cni --kubernetes-version ${NEW_VERSION} --region ${REGION} --query 'addons[0].addonVersions[0].addonVersion' --output text)
    aws eks update-addon --cluster-name ${CLUSTER_NAME} --addon-name vpc-cni --addon-version ${vpc_cni_version} --region ${REGION} --resolve-conflicts OVERWRITE || echo "⚠️  VPC CNI update failed or not needed"
else
    echo "ℹ️  VPC CNI add-on not installed"
fi

# Step 6: Update cluster autoscaler
echo "🔄 Updating Cluster Autoscaler..."
if kubectl get deployment cluster-autoscaler -n kube-system >/dev/null 2>&1; then
    kubectl set image deployment/cluster-autoscaler cluster-autoscaler=registry.k8s.io/autoscaling/cluster-autoscaler:v${NEW_VERSION}.0 -n kube-system
    kubectl rollout status deployment/cluster-autoscaler -n kube-system
    echo "✅ Cluster autoscaler updated to v${NEW_VERSION}.0"
else
    echo "ℹ️  Cluster autoscaler not found, will be updated via Terraform"
fi

# Step 7: Update metrics server (if needed)
echo "🔄 Checking metrics server..."
if kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
    echo "✅ Metrics server is running"
else
    echo "ℹ️  Metrics server not found, will be deployed via Terraform"
fi

# Step 8: Verify the upgrade
echo "🔍 Verifying the upgrade..."
echo "📋 Final cluster information:"
aws eks describe-cluster --name ${CLUSTER_NAME} --region ${REGION} --query 'cluster.{Name:name,Version:version,Status:status}' --output table

echo "📋 Node group versions:"
for node_group in $node_groups; do
    version=$(aws eks describe-nodegroup --cluster-name ${CLUSTER_NAME} --nodegroup-name ${node_group} --region ${REGION} --query 'nodegroup.version' --output text)
    echo "  ${node_group}: ${version}"
done

echo "📋 Node status:"
kubectl get nodes -o wide

echo "📋 System pods status:"
kubectl get pods -n kube-system

echo "✅ EKS Cluster upgrade to Kubernetes ${NEW_VERSION} completed!"
echo "🎉 Your cluster is now running Kubernetes ${NEW_VERSION}"

# Health check
echo "🏥 Running health check..."
kubectl cluster-info

echo "📝 Next steps:"
echo "1. Update your Terraform configuration"
echo "2. Test your applications"
echo "3. Monitor cluster performance"
