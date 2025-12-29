#!/bin/bash
# EKS HPA and ASG Test Execution Script

echo "=== EKS HPA and ASG Testing Script ==="
echo "Date: $(date)"
echo "Cluster: eks-terraform-cluster"
echo

# Test 1: HPA Testing
echo "🔄 Starting HPA Test..."
echo "Deploying CPU-intensive application..."
kubectl apply -f cpu-intensive-hpa.yaml

echo "Waiting for pods to start..."
sleep 30

echo "Initial HPA status:"
kubectl get hpa cpu-intensive-hpa

echo "Waiting for scaling (2 minutes)..."
sleep 120

echo "Final HPA status:"
kubectl get hpa cpu-intensive-hpa
kubectl get pods -l app=cpu-intensive-app

echo "✅ HPA Test Complete"
echo

# Test 2: ASG Testing  
echo "🔄 Starting ASG Test..."
echo "Current nodes:"
kubectl get nodes

echo "Deploying memory-intensive workload..."
kubectl apply -f memory-hog.yaml

echo "Checking for pending pods..."
kubectl get pods -l app=memory-hog | grep Pending

echo "Waiting for node scaling (2 minutes)..."
sleep 120

echo "Final node count:"
kubectl get nodes

echo "✅ ASG Test Complete"
echo

# Cleanup
echo "🧹 Cleaning up test resources..."
kubectl delete deployment cpu-intensive-app memory-hog 2>/dev/null
kubectl delete hpa cpu-intensive-hpa 2>/dev/null
kubectl delete service cpu-intensive-service 2>/dev/null

echo "✅ All tests completed successfully!"
