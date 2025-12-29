# EKS HPA and ASG Testing Scenario

## Test Environment
- **Date**: December 29, 2025
- **EKS Cluster**: eks-terraform-cluster
- **Region**: ap-south-1
- **Initial Nodes**: 4
- **Node Type**: t3.medium (2 vCPU, 4GB RAM)

## Test 1: Horizontal Pod Autoscaler (HPA) Testing

### Objective
Verify HPA scales pods based on CPU utilization metrics.

### Test Configuration
- **Application**: nginx:alpine with stress-ng
- **Initial Replicas**: 2
- **Min Replicas**: 2, Max Replicas**: 8
- **CPU Threshold**: 50%
- **Resource Requests**: 100m CPU, 128Mi memory

### Test Execution
```bash
# Deploy CPU-intensive workload
kubectl apply -f cpu-intensive-hpa.yaml

# Monitor scaling
kubectl get hpa cpu-intensive-hpa -w
kubectl get pods -l app=cpu-intensive-app -w
```

### Test Results
- **Initial CPU Usage**: 27%
- **Peak CPU Usage**: 100%
- **Final Pod Count**: 8 pods (scaled from 2)
- **Scaling Time**: ~2 minutes
- **Status**: ✅ SUCCESS
## Test 2: Auto Scaling Group (ASG) Testing

### Objective
Verify cluster autoscaler scales nodes when pods cannot be scheduled.

### Test Configuration
- **Initial Nodes**: 4, **Max Nodes**: 5
- **Pod Resource Request**: 800Mi memory, 100m CPU
- **Pod Count**: 20 (to exceed cluster capacity)

### Test Execution
```bash
# Deploy memory-intensive workload
kubectl apply -f memory-hog.yaml

# Monitor cluster autoscaler
kubectl logs -l app=cluster-autoscaler -n kube-system --tail=10
kubectl get nodes -w
```

### Test Results
- **Initial Nodes**: 4
- **Pending Pods**: 18 (insufficient memory)
- **Final Nodes**: 5 (new node: ip-172-31-35-112)
- **Scaling Time**: ~2 minutes
- **Status**: ✅ SUCCESS

## Key Test Files Created
- `cpu-intensive-hpa.yaml` - CPU stress test with HPA
- `memory-hog.yaml` - Memory stress test for ASG
- `TEST-SCENARIO.md` - This documentation

## Success Criteria Met
- ✅ HPA scaled pods from 2 to 8 based on CPU utilization
- ✅ ASG scaled nodes from 4 to 5 based on unschedulable pods
- ✅ Both scaling mechanisms responded within 2-3 minutes
