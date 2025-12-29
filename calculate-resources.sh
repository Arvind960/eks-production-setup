#!/bin/bash
# Resource Calculation Helper Script

echo "=== EKS Resource Calculator ==="
echo

# Function to convert memory units
convert_memory() {
    local value=$1
    local unit=$2
    
    case $unit in
        "Ki") echo $(($value * 1024)) ;;
        "Mi") echo $(($value * 1048576)) ;;
        "Gi") echo $(($value * 1073741824)) ;;
        *) echo $value ;;
    esac
}

# Function to calculate HPA scaling
calculate_hpa() {
    local current_usage=$1
    local cpu_request=$2
    local target_percent=$3
    local current_replicas=$4
    
    local target_usage=$((cpu_request * target_percent / 100))
    local required_replicas=$((current_usage * current_replicas / target_usage))
    
    echo "HPA Calculation:"
    echo "  Current Usage: ${current_usage}m"
    echo "  CPU Request: ${cpu_request}m" 
    echo "  Target: ${target_percent}% (${target_usage}m)"
    echo "  Current Replicas: $current_replicas"
    echo "  Required Replicas: $required_replicas"
    echo
}

# Function to calculate ASG requirements
calculate_asg() {
    local pod_memory_mi=$1
    local pod_count=$2
    local node_memory_mi=$3
    
    local total_memory_needed=$((pod_memory_mi * pod_count))
    local pods_per_node=$((node_memory_mi / pod_memory_mi))
    local required_nodes=$(((pod_count + pods_per_node - 1) / pods_per_node))
    
    echo "ASG Calculation:"
    echo "  Pod Memory Request: ${pod_memory_mi}Mi"
    echo "  Total Pods: $pod_count"
    echo "  Node Memory Available: ${node_memory_mi}Mi"
    echo "  Pods per Node: $pods_per_node"
    echo "  Required Nodes: $required_nodes"
    echo
}

# Get current cluster info
echo "📊 Current Cluster Status:"
echo "Nodes:"
kubectl get nodes --no-headers | wc -l | xargs echo "  Count:"
echo "  Details:"
kubectl top nodes 2>/dev/null || echo "  (Metrics server not available)"
echo

echo "Pods:"
kubectl get pods --all-namespaces --no-headers | wc -l | xargs echo "  Total Count:"
echo

# Example calculations based on our test cases
echo "🧮 Test Case Calculations:"
echo

echo "1. HPA Test Case (CPU-Intensive App):"
calculate_hpa 100 100 50 2

echo "2. ASG Test Case (Memory-Intensive App):"
calculate_asg 800 20 3300

echo "📋 Quick Reference:"
echo "CPU Units:"
echo "  1000m = 1 CPU core"
echo "  500m = 0.5 CPU core" 
echo "  100m = 0.1 CPU core"
echo
echo "Memory Units:"
echo "  1Gi = 1024Mi = 1,073,741,824 bytes"
echo "  1Mi = 1024Ki = 1,048,576 bytes"
echo "  1Ki = 1024 bytes"
echo

echo "🔍 Useful Commands:"
echo "  kubectl top pods                    # Pod resource usage"
echo "  kubectl top nodes                   # Node resource usage"
echo "  kubectl describe hpa <name>         # HPA details"
echo "  kubectl describe node <name>        # Node capacity"
echo "  kubectl get events --sort-by=.metadata.creationTimestamp  # Recent events"
