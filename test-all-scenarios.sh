#!/bin/bash

# Test All HPA and ASG Scenarios
# This script demonstrates all possible scaling scenarios

set -e

echo "🚀 Testing All HPA and ASG Scenarios"
echo "===================================="

# Function to wait and monitor
wait_and_monitor() {
    local duration=$1
    local description=$2
    echo "⏳ $description - waiting ${duration}s..."
    
    for i in $(seq 1 $duration); do
        if [ $((i % 30)) -eq 0 ]; then
            echo "📊 Status at ${i}s:"
            kubectl get hpa 2>/dev/null || echo "No HPA found"
            kubectl get pods --no-headers | wc -l | xargs -I {} echo "Pods: {}"
            kubectl get nodes --no-headers | wc -l | xargs -I {} echo "Nodes: {}"
        fi
        sleep 1
    done
}

# Scenario 1: Basic CPU Scaling
echo "📋 Scenario 1: Basic CPU Scaling"
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cpu-test
  template:
    metadata:
      labels:
        app: cpu-test
    spec:
      containers:
      - name: cpu-app
        image: busybox
        command: ["sh", "-c", "while true; do :; done"]
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: cpu-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: cpu-test
  minReplicas: 2
  maxReplicas: 8
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
EOF

wait_and_monitor 120 "CPU scaling test"

echo "✅ CPU Test Results:"
kubectl get hpa cpu-hpa
kubectl get pods -l app=cpu-test --no-headers | wc -l | xargs -I {} echo "Final pods: {}"

# Scenario 2: Memory Scaling
echo -e "\n📋 Scenario 2: Memory Scaling"
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: memory-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: memory-test
  template:
    metadata:
      labels:
        app: memory-test
    spec:
      containers:
      - name: memory-app
        image: progrium/stress
        args: ["--vm", "1", "--vm-bytes", "100M", "--vm-keep"]
        resources:
          requests:
            cpu: 50m
            memory: 128Mi
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: memory-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: memory-test
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
EOF

wait_and_monitor 120 "Memory scaling test"

echo "✅ Memory Test Results:"
kubectl get hpa memory-hpa
kubectl get pods -l app=memory-test --no-headers | wc -l | xargs -I {} echo "Final pods: {}"

# Scenario 3: ASG Trigger (Large Memory Request)
echo -e "\n📋 Scenario 3: ASG Node Scaling"
initial_nodes=$(kubectl get nodes --no-headers | wc -l)
echo "Initial nodes: $initial_nodes"

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: large-memory
spec:
  replicas: 3
  selector:
    matchLabels:
      app: large-memory
  template:
    metadata:
      labels:
        app: large-memory
    spec:
      containers:
      - name: memory-hog
        image: nginx
        resources:
          requests:
            cpu: 500m
            memory: 2Gi
          limits:
            cpu: 1000m
            memory: 3Gi
EOF

wait_and_monitor 300 "ASG node scaling test"

final_nodes=$(kubectl get nodes --no-headers | wc -l)
echo "✅ ASG Test Results:"
echo "Initial nodes: $initial_nodes"
echo "Final nodes: $final_nodes"
echo "Node change: $((final_nodes - initial_nodes))"

# Scenario 4: Multi-Metric HPA
echo -e "\n📋 Scenario 4: Multi-Metric Scaling"
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-metric
spec:
  replicas: 2
  selector:
    matchLabels:
      app: multi-metric
  template:
    metadata:
      labels:
        app: multi-metric
    spec:
      containers:
      - name: app
        image: nginx
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: multi-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: multi-metric
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 75
EOF

# Generate mixed load
kubectl run load-gen --image=busybox --restart=Never -- /bin/sh -c "
while true; do
  # CPU load
  timeout 30 yes > /dev/null 2>&1 || true
  # Memory allocation
  dd if=/dev/zero of=/tmp/mem bs=1M count=200 2>/dev/null || true
  sleep 10
done"

wait_and_monitor 180 "Multi-metric scaling test"

echo "✅ Multi-Metric Test Results:"
kubectl get hpa multi-hpa

# Summary
echo -e "\n📊 FINAL SUMMARY"
echo "================="
echo "HPA Status:"
kubectl get hpa
echo -e "\nPod Counts:"
kubectl get deployments -o custom-columns=NAME:.metadata.name,REPLICAS:.status.replicas
echo -e "\nNode Count:"
kubectl get nodes --no-headers | wc -l | xargs -I {} echo "Total nodes: {}"

# Cleanup
echo -e "\n🧹 Cleaning up..."
kubectl delete deployment cpu-test memory-test large-memory multi-metric --ignore-not-found=true
kubectl delete hpa cpu-hpa memory-hpa multi-hpa --ignore-not-found=true
kubectl delete pod load-gen --ignore-not-found=true

echo "✅ All scenario tests completed!"
