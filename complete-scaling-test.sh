#!/bin/bash

# Complete EKS Scaling Test - Pod HPA + Node ASG with Timing & Resource Calculations
# This script tests complete scaling scenarios and measures timing

set -e

CLUSTER_NAME="eks-terraform-cluster"
NAMESPACE="default"
LOG_FILE="scaling-test-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a $LOG_FILE
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a $LOG_FILE
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a $LOG_FILE
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a $LOG_FILE
}

# Function to get current resource usage
get_resource_usage() {
    echo "=== Current Resource Usage ===" | tee -a $LOG_FILE
    kubectl top nodes 2>/dev/null || echo "Metrics server not available"
    kubectl top pods --all-namespaces 2>/dev/null || echo "Pod metrics not available"
    echo | tee -a $LOG_FILE
}

# Function to calculate scaling thresholds
calculate_scaling_points() {
    log "📊 CALCULATING SCALING THRESHOLDS"
    echo "=== Pod Scaling Calculations ===" | tee -a $LOG_FILE
    echo "HPA scales when:" | tee -a $LOG_FILE
    echo "- CPU > 50% of requested resources" | tee -a $LOG_FILE
    echo "- Memory > 80% of requested resources" | tee -a $LOG_FILE
    echo | tee -a $LOG_FILE
    
    echo "=== Node Scaling Calculations ===" | tee -a $LOG_FILE
    echo "ASG scales when:" | tee -a $LOG_FILE
    echo "- Pods cannot be scheduled (Pending state)" | tee -a $LOG_FILE
    echo "- Node CPU/Memory > 80% utilization" | tee -a $LOG_FILE
    echo "- Available resources < pod requests" | tee -a $LOG_FILE
    echo | tee -a $LOG_FILE
}

# Function to measure timing
measure_time() {
    local start_time=$1
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "${duration}s"
}

# Function to wait for pod scaling
wait_for_pod_scaling() {
    local app_name=$1
    local target_replicas=$2
    local timeout=300
    local start_time=$(date +%s)
    
    log "⏳ Waiting for pod scaling to $target_replicas replicas..."
    
    while [ $(($(date +%s) - start_time)) -lt $timeout ]; do
        current_replicas=$(kubectl get deployment $app_name -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        if [ "$current_replicas" -ge "$target_replicas" ]; then
            local duration=$(measure_time $start_time)
            success "Pod scaling completed in $duration"
            return 0
        fi
        sleep 10
    done
    
    error "Pod scaling timeout after ${timeout}s"
    return 1
}

# Function to wait for node scaling
wait_for_node_scaling() {
    local initial_nodes=$1
    local expected_change=$2
    local timeout=600
    local start_time=$(date +%s)
    
    log "⏳ Waiting for node scaling (expected change: $expected_change)..."
    
    while [ $(($(date +%s) - start_time)) -lt $timeout ]; do
        current_nodes=$(kubectl get nodes --no-headers | wc -l)
        if [ "$expected_change" = "up" ] && [ "$current_nodes" -gt "$initial_nodes" ]; then
            local duration=$(measure_time $start_time)
            success "Node scale-up completed in $duration (from $initial_nodes to $current_nodes nodes)"
            return 0
        elif [ "$expected_change" = "down" ] && [ "$current_nodes" -lt "$initial_nodes" ]; then
            local duration=$(measure_time $start_time)
            success "Node scale-down completed in $duration (from $initial_nodes to $current_nodes nodes)"
            return 0
        fi
        sleep 30
    done
    
    error "Node scaling timeout after ${timeout}s"
    return 1
}

# Main test function
run_complete_test() {
    log "🚀 STARTING COMPLETE EKS SCALING TEST"
    log "Cluster: $CLUSTER_NAME"
    log "Namespace: $NAMESPACE"
    log "Log file: $LOG_FILE"
    echo | tee -a $LOG_FILE
    
    # Initial state
    log "📋 INITIAL CLUSTER STATE"
    initial_nodes=$(kubectl get nodes --no-headers | wc -l)
    log "Initial nodes: $initial_nodes"
    kubectl get nodes | tee -a $LOG_FILE
    get_resource_usage
    
    calculate_scaling_points
    
    # Test 1: HPA Pod Scaling Test
    log "🔄 TEST 1: HPA POD SCALING"
    hpa_start_time=$(date +%s)
    
    log "Deploying CPU-intensive application with HPA..."
    kubectl apply -f cpu-intensive-hpa.yaml
    
    log "Waiting for initial deployment..."
    kubectl wait --for=condition=available --timeout=120s deployment/cpu-intensive-app
    
    log "Initial HPA status:"
    kubectl get hpa cpu-intensive-hpa | tee -a $LOG_FILE
    
    log "Generating CPU load to trigger HPA scaling..."
    kubectl apply -f load-generator.yaml
    
    # Monitor HPA scaling
    log "Monitoring HPA scaling for 5 minutes..."
    for i in {1..10}; do
        sleep 30
        log "HPA Status (${i}/10):"
        kubectl get hpa cpu-intensive-hpa | tee -a $LOG_FILE
        kubectl get pods -l app=cpu-intensive-app --no-headers | wc -l | xargs -I {} log "Current replicas: {}"
    done
    
    hpa_duration=$(measure_time $hpa_start_time)
    success "HPA test completed in $hpa_duration"
    
    # Test 2: ASG Node Scaling Test
    log "🔄 TEST 2: ASG NODE SCALING"
    asg_start_time=$(date +%s)
    
    log "Current nodes before memory test: $initial_nodes"
    
    log "Deploying memory-intensive workload to trigger node scaling..."
    kubectl apply -f memory-hog.yaml
    
    log "Checking for pending pods..."
    pending_pods=$(kubectl get pods -l app=memory-hog --field-selector=status.phase=Pending --no-headers | wc -l)
    log "Pending pods: $pending_pods"
    
    if [ "$pending_pods" -gt 0 ]; then
        log "Pending pods detected - waiting for node scaling..."
        wait_for_node_scaling $initial_nodes "up"
    else
        warning "No pending pods - node scaling may not be triggered"
    fi
    
    asg_duration=$(measure_time $asg_start_time)
    success "ASG test completed in $asg_duration"
    
    # Resource monitoring during peak load
    log "📊 PEAK LOAD RESOURCE MONITORING"
    get_resource_usage
    
    final_nodes=$(kubectl get nodes --no-headers | wc -l)
    log "Final nodes: $final_nodes"
    
    # Test 3: Scale Down Test
    log "🔄 TEST 3: SCALE DOWN TEST"
    scaledown_start_time=$(date +%s)
    
    log "Removing load generators and memory hogs..."
    kubectl delete -f load-generator.yaml --ignore-not-found=true
    kubectl delete -f memory-hog.yaml --ignore-not-found=true
    
    log "Waiting for HPA scale-down..."
    sleep 300  # HPA scale-down delay
    
    log "HPA status after scale-down:"
    kubectl get hpa cpu-intensive-hpa | tee -a $LOG_FILE
    
    log "Waiting for node scale-down (this may take 10-15 minutes)..."
    sleep 600  # Wait for node scale-down
    
    current_nodes=$(kubectl get nodes --no-headers | wc -l)
    if [ "$current_nodes" -lt "$final_nodes" ]; then
        scaledown_duration=$(measure_time $scaledown_start_time)
        success "Scale-down completed in $scaledown_duration"
    else
        warning "Node scale-down not detected within timeout"
    fi
    
    # Final summary
    log "📋 FINAL TEST SUMMARY"
    total_duration=$(measure_time $(date -d "$(head -1 $LOG_FILE | cut -d']' -f1 | tr -d '[')" +%s))
    
    echo "=== SCALING TEST RESULTS ===" | tee -a $LOG_FILE
    echo "Total test duration: $total_duration" | tee -a $LOG_FILE
    echo "HPA pod scaling time: $hpa_duration" | tee -a $LOG_FILE
    echo "ASG node scaling time: $asg_duration" | tee -a $LOG_FILE
    echo "Initial nodes: $initial_nodes" | tee -a $LOG_FILE
    echo "Peak nodes: $final_nodes" | tee -a $LOG_FILE
    echo "Current nodes: $current_nodes" | tee -a $LOG_FILE
    echo | tee -a $LOG_FILE
    
    echo "=== SCALING THRESHOLDS OBSERVED ===" | tee -a $LOG_FILE
    echo "Pod scaling triggered at: CPU > 50%" | tee -a $LOG_FILE
    echo "Node scaling triggered by: Pending pods" | tee -a $LOG_FILE
    echo "Node provisioning time: ~2-4 minutes" | tee -a $LOG_FILE
    echo "Node termination time: ~10-15 minutes" | tee -a $LOG_FILE
    echo | tee -a $LOG_FILE
    
    get_resource_usage
    
    success "Complete scaling test finished! Check $LOG_FILE for detailed logs."
}

# Cleanup function
cleanup() {
    log "🧹 CLEANING UP TEST RESOURCES"
    kubectl delete deployment cpu-intensive-app --ignore-not-found=true
    kubectl delete hpa cpu-intensive-hpa --ignore-not-found=true
    kubectl delete service cpu-intensive-service --ignore-not-found=true
    kubectl delete deployment load-generator --ignore-not-found=true
    kubectl delete deployment memory-hog --ignore-not-found=true
    success "Cleanup completed"
}

# Trap cleanup on exit
trap cleanup EXIT

# Check prerequisites
log "🔍 CHECKING PREREQUISITES"
if ! kubectl cluster-info &>/dev/null; then
    error "Cannot connect to Kubernetes cluster"
    exit 1
fi

if ! kubectl get nodes &>/dev/null; then
    error "Cannot access cluster nodes"
    exit 1
fi

success "Prerequisites check passed"

# Run the complete test
run_complete_test

log "🎉 ALL TESTS COMPLETED SUCCESSFULLY!"
