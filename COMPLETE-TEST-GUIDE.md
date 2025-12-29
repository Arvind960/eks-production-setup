# Complete EKS Scaling Test - Quick Start

## What This Test Does

This comprehensive test measures:
- **Pod scaling timing** (HPA)
- **Node scaling timing** (ASG) 
- **Resource utilization** at each scaling point
- **Scale-up and scale-down** complete cycles

## Prerequisites

1. EKS cluster running with metrics server
2. Cluster autoscaler configured
3. HPA enabled
4. Required YAML files in directory

## Run Complete Test

```bash
cd /home/ubuntu/eks-production-setup
./complete-scaling-test.sh
```

## What You'll See

### Phase 1: Pod Scaling (2-5 minutes)
- Deploys CPU-intensive app with HPA
- Generates load to trigger scaling
- Measures time to scale from 1→N pods
- **Expected**: 30-60 seconds for pod scaling

### Phase 2: Node Scaling (5-10 minutes)  
- Deploys memory-intensive workload
- Creates pending pods to trigger ASG
- Measures time for new node provisioning
- **Expected**: 2-4 minutes for new node

### Phase 3: Scale Down (10-20 minutes)
- Removes load generators
- Waits for HPA scale-down (5 min delay)
- Waits for node termination (10-15 min)
- **Expected**: 15+ minutes total

## Key Metrics Measured

- **Pod scaling time**: 30-60s
- **Node provisioning time**: 2-4 minutes
- **Node termination time**: 10-15 minutes
- **Resource utilization** at scaling points
- **Total test duration**: 20-30 minutes

## Output Files

- `scaling-test-YYYYMMDD-HHMMSS.log` - Detailed timing log
- Console output with real-time status
- Resource usage snapshots

## Scaling Thresholds

### Pod Scaling Triggers
- CPU > 50% of requested resources
- Memory > 80% of requested resources

### Node Scaling Triggers  
- Pods in Pending state (unschedulable)
- Node utilization > 80%
- Insufficient resources for pod requests

## Monitor During Test

```bash
# In separate terminals:
watch kubectl get hpa
watch kubectl get pods
watch kubectl get nodes
watch kubectl top nodes
```

## Expected Results

```
=== SCALING TEST RESULTS ===
Total test duration: 1800s (30 minutes)
HPA pod scaling time: 45s
ASG node scaling time: 180s (3 minutes)
Initial nodes: 2
Peak nodes: 3
Current nodes: 2

=== SCALING THRESHOLDS OBSERVED ===
Pod scaling triggered at: CPU > 50%
Node scaling triggered by: Pending pods
Node provisioning time: ~2-4 minutes
Node termination time: ~10-15 minutes
```

## Cleanup

The script automatically cleans up all test resources on completion or interruption.

## Troubleshooting

If test fails:
1. Check cluster connectivity: `kubectl get nodes`
2. Verify metrics server: `kubectl top nodes`
3. Check ASG configuration: `aws autoscaling describe-auto-scaling-groups`
4. Review logs in generated log file
