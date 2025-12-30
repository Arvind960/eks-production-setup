#!/bin/bash

# EKS Cluster Upgrade Script: 1.31 → 1.32
# This script upgrades the EKS cluster and all components to Kubernetes 1.32

set -e

CLUSTER_NAME="eks-terraform-cluster"
REGION="ap-south-1"
NEW_VERSION="1.32"

echo "🚀 Starting EKS Cluster Upgrade to Kubernetes ${NEW_VERSION}"
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

# Step 1: Check current cluster status
echo "📋 Current cluster information:"
aws eks describe-cluster --name ${CLUSTER_NAME} --region ${REGION} --query 'cluster.{Name:name,Version:version,Status:status}' --output table

# Step 2: Upgrade control plane (if not already started)
echo "🔄 Checking if control plane upgrade is needed..."
current_version=$(aws eks describe-cluster --name ${CLUSTER_NAME} --region ${REGION} --query 'cluster.version' --output text)

if [ "$current_version" != "$NEW_VERSION" ]; then
    echo "🚀 Starting control plane upgrade..."
    update_id=$(aws eks update-cluster-version --name ${CLUSTER_NAME} --kubernetes-version ${NEW_VERSION} --region ${REGION} --query 'update.id' --output text)
    echo "📝 Control plane update ID: ${update_id}"
    check_update_status ${update_id} "Control Plane"
else
    echo "✅ Control plane is already at version ${NEW_VERSION}"
fi

# Step 3: Update kubeconfig
echo "🔧 Updating kubeconfig..."
aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}

# Step 4: Upgrade node groups
echo "🔄 Upgrading node groups..."
node_groups=$(aws eks list-nodegroups --cluster-name ${CLUSTER_NAME} --region ${REGION} --query 'nodegroups' --output text)

for node_group in $node_groups; do
    echo "🔄 Upgrading node group: ${node_group}"
    
    # Check current node group version
    current_ng_version=$(aws eks describe-nodegroup --cluster-name ${CLUSTER_NAME} --nodegroup-name ${node_group} --region ${REGION} --query 'nodegroup.version' --output text)
    
    if [ "$current_ng_version" != "$NEW_VERSION" ]; then
        update_id=$(aws eks update-nodegroup-version --cluster-name ${CLUSTER_NAME} --nodegroup-name ${node_group} --region ${REGION} --query 'update.id' --output text)
        echo "📝 Node group ${node_group} update ID: ${update_id}"
        check_update_status ${update_id} "Node Group ${node_group}"
    else
        echo "✅ Node group ${node_group} is already at version ${NEW_VERSION}"
    fi
done

# Step 5: Update add-ons
echo "🔧 Updating EKS add-ons..."

# Update kube-proxy
echo "🔄 Updating kube-proxy..."
kube_proxy_version=$(aws eks describe-addon-versions --addon-name kube-proxy --kubernetes-version ${NEW_VERSION} --region ${REGION} --query 'addons[0].addonVersions[0].addonVersion' --output text)
aws eks update-addon --cluster-name ${CLUSTER_NAME} --addon-name kube-proxy --addon-version ${kube_proxy_version} --region ${REGION} || echo "⚠️  kube-proxy update failed or not needed"

# Update CoreDNS
echo "🔄 Updating CoreDNS..."
coredns_version=$(aws eks describe-addon-versions --addon-name coredns --kubernetes-version ${NEW_VERSION} --region ${REGION} --query 'addons[0].addonVersions[0].addonVersion' --output text)
aws eks update-addon --cluster-name ${CLUSTER_NAME} --addon-name coredns --addon-version ${coredns_version} --region ${REGION} || echo "⚠️  CoreDNS update failed or not needed"

# Update VPC CNI
echo "🔄 Updating VPC CNI..."
vpc_cni_version=$(aws eks describe-addon-versions --addon-name vpc-cni --kubernetes-version ${NEW_VERSION} --region ${REGION} --query 'addons[0].addonVersions[0].addonVersion' --output text)
aws eks update-addon --cluster-name ${CLUSTER_NAME} --addon-name vpc-cni --addon-version ${vpc_cni_version} --region ${REGION} || echo "⚠️  VPC CNI update failed or not needed"

# Step 6: Update cluster autoscaler
echo "🔄 Updating Cluster Autoscaler..."
kubectl set image deployment/cluster-autoscaler cluster-autoscaler=registry.k8s.io/autoscaling/cluster-autoscaler:v${NEW_VERSION}.0 -n kube-system || echo "⚠️  Cluster autoscaler update will be done via Terraform"

# Step 7: Verify the upgrade
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

echo "✅ EKS Cluster upgrade to Kubernetes ${NEW_VERSION} completed successfully!"
echo "🎉 Your cluster is now running Kubernetes ${NEW_VERSION}"

# Optional: Run a quick health check
echo "🏥 Running health check..."
kubectl cluster-info
kubectl get componentstatuses || echo "⚠️  Component status check not available in newer versions"

echo "📝 Next steps:"
echo "1. Test your applications to ensure compatibility with Kubernetes ${NEW_VERSION}"
echo "2. Update any custom applications or operators if needed"
echo "3. Monitor cluster performance and logs"
echo "4. Update your Terraform configuration to reflect the new version"
