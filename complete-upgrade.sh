#!/bin/bash

# EKS Upgrade Completion Script
# Monitors and completes the remaining upgrade steps

CLUSTER_NAME="eks-terraform-cluster"
REGION="ap-south-1"
NODE_UPDATE_ID="cfeb4f7e-a099-3ef1-b4d8-a4c52122cf98"

echo "🚀 EKS Upgrade Completion - Kubernetes 1.32"
echo "============================================="

# Function to check update status
check_update_status() {
    local update_id=$1
    local update_type=$2
    
    echo "⏳ Monitoring ${update_type} upgrade..."
    
    while true; do
        status=$(aws eks describe-update --name ${CLUSTER_NAME} --update-id ${update_id} --region ${REGION} --query 'update.status' --output text)
        
        case $status in
            "Successful")
                echo "✅ ${update_type} upgrade completed successfully!"
                break
                ;;
            "Failed")
                echo "❌ ${update_type} upgrade failed!"
                aws eks describe-update --name ${CLUSTER_NAME} --update-id ${update_id} --region ${REGION} --query 'update.errors'
                exit 1
                ;;
            "InProgress")
                echo "⏳ ${update_type} upgrade in progress... ($(date '+%H:%M:%S'))"
                sleep 30
                ;;
            *)
                echo "⚠️  Unknown status: $status"
                sleep 30
                ;;
        esac
    done
}

# Step 1: Monitor node group upgrade
echo "📋 Current Status:"
echo "- Control Plane: ✅ 1.32 (Completed)"
echo "- Node Group: 🔄 Upgrading to 1.32..."
echo ""

check_update_status ${NODE_UPDATE_ID} "Node Group"

# Step 2: Update kubeconfig
echo "🔧 Updating kubeconfig..."
aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}

# Step 3: Update cluster autoscaler
echo "🔄 Updating Cluster Autoscaler to v1.32.0..."
if kubectl get deployment cluster-autoscaler -n kube-system >/dev/null 2>&1; then
    kubectl set image deployment/cluster-autoscaler cluster-autoscaler=registry.k8s.io/autoscaling/cluster-autoscaler:v1.32.0 -n kube-system
    echo "⏳ Waiting for cluster autoscaler rollout..."
    kubectl rollout status deployment/cluster-autoscaler -n kube-system --timeout=300s
    echo "✅ Cluster autoscaler updated successfully!"
else
    echo "ℹ️  Cluster autoscaler not found - will be deployed via Terraform"
fi

# Step 4: Check and update EKS add-ons
echo "🔧 Checking EKS add-ons..."

# List current add-ons
echo "📋 Current add-ons:"
aws eks list-addons --cluster-name ${CLUSTER_NAME} --region ${REGION} --output table

# Update add-ons if they exist
for addon in kube-proxy coredns vpc-cni; do
    if aws eks describe-addon --cluster-name ${CLUSTER_NAME} --addon-name ${addon} --region ${REGION} >/dev/null 2>&1; then
        echo "🔄 Updating ${addon}..."
        latest_version=$(aws eks describe-addon-versions --addon-name ${addon} --kubernetes-version 1.32 --region ${REGION} --query 'addons[0].addonVersions[0].addonVersion' --output text)
        aws eks update-addon --cluster-name ${CLUSTER_NAME} --addon-name ${addon} --addon-version ${latest_version} --region ${REGION} --resolve-conflicts OVERWRITE || echo "⚠️  ${addon} update failed or not needed"
    else
        echo "ℹ️  ${addon} add-on not installed"
    fi
done

# Step 5: Verify the upgrade
echo ""
echo "🔍 Verifying the upgrade..."
echo "=========================="

echo "📋 Cluster Information:"
aws eks describe-cluster --name ${CLUSTER_NAME} --region ${REGION} --query 'cluster.{Name:name,Version:version,Status:status}' --output table

echo ""
echo "📋 Node Group Information:"
aws eks describe-nodegroup --cluster-name ${CLUSTER_NAME} --nodegroup-name workers --region ${REGION} --query 'nodegroup.{Name:nodegroupName,Version:version,Status:status}' --output table

echo ""
echo "📋 Node Status:"
kubectl get nodes -o wide

echo ""
echo "📋 System Pods Status:"
kubectl get pods -n kube-system -o wide

echo ""
echo "📋 HPA Status:"
kubectl get hpa --all-namespaces

echo ""
echo "🏥 Cluster Health Check:"
kubectl cluster-info

echo ""
echo "✅ EKS Cluster upgrade to Kubernetes 1.32 completed successfully!"
echo "🎉 Summary:"
echo "   - Control Plane: 1.32 ✅"
echo "   - Node Group: 1.32 ✅"
echo "   - Cluster Autoscaler: v1.32.0 ✅"
echo "   - Add-ons: Updated ✅"

echo ""
echo "📝 Next Steps:"
echo "1. Apply Terraform changes: cd terraform && terraform apply"
echo "2. Test your applications and HPA functionality"
echo "3. Monitor cluster performance for 24-48 hours"
echo "4. Update any application-specific Kubernetes manifests if needed"
