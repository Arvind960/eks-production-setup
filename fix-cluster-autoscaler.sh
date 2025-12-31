#!/bin/bash
# Fix cluster-autoscaler RBAC for EKS 1.33+ compatibility
# Run this script after EKS upgrades to ensure cluster-autoscaler works

echo "🔧 Fixing cluster-autoscaler RBAC permissions for EKS 1.33+ compatibility..."

# Add volumeattachments permission to existing ClusterRole
kubectl patch clusterrole cluster-autoscaler --type='json' -p='[
  {
    "op": "test",
    "path": "/rules/12/resources",
    "value": ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"]
  },
  {
    "op": "replace",
    "path": "/rules/12/resources",
    "value": ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities", "volumeattachments"]
  }
]' 2>/dev/null || echo "⚠️  ClusterRole already has volumeattachments permission or structure is different"

# Restart cluster-autoscaler to apply new permissions
echo "🔄 Restarting cluster-autoscaler deployment..."
kubectl rollout restart deployment/cluster-autoscaler -n kube-system

# Wait for rollout to complete
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/cluster-autoscaler -n kube-system --timeout=300s

# Verify no permission errors
echo "✅ Checking for permission errors..."
sleep 10
if kubectl logs deployment/cluster-autoscaler -n kube-system --tail=20 | grep -i "forbidden\|volumeattachments.*forbidden" > /dev/null; then
    echo "❌ Still seeing permission errors. Manual intervention may be required."
    exit 1
else
    echo "✅ Cluster-autoscaler is working properly!"
fi

echo "🎉 Fix completed successfully!"
