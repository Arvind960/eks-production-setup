# EKS Scaling Calculations & Timing Reference

## Pod Scaling (HPA) Calculations

### CPU-based Scaling
```
Scale Up Trigger: (Current CPU Usage / CPU Request) > Target Percentage
Default Target: 50%
Example: If pod requests 100m CPU and uses 60m CPU = 60% > 50% → Scale Up
```

### Memory-based Scaling
```
Scale Up Trigger: (Current Memory Usage / Memory Request) > Target Percentage  
Default Target: 80%
Example: If pod requests 128Mi and uses 110Mi = 85% > 80% → Scale Up
```

### HPA Formula
```
Desired Replicas = ceil(Current Replicas × (Current Metric Value / Target Metric Value))
Max Replicas: As defined in HPA spec
Min Replicas: As defined in HPA spec
```

## Node Scaling (ASG) Calculations

### Scale Up Triggers
1. **Pending Pods**: Pods cannot be scheduled due to insufficient resources
2. **Resource Pressure**: Node utilization > 80%
3. **Unschedulable**: Pod requests exceed available node capacity

### Node Capacity Calculation
```
Available CPU = Total Node CPU - System Reserved - Kube Reserved
Available Memory = Total Node Memory - System Reserved - Kube Reserved

For t3.medium (2 vCPU, 4GB RAM):
- Available CPU: ~1.8 vCPU (200m reserved for system)
- Available Memory: ~3.2GB (800MB reserved for system)
```

### Scale Down Triggers
1. **Low Utilization**: Node utilization < 50% for 10+ minutes
2. **Pod Consolidation**: All pods can fit on fewer nodes
3. **Empty Nodes**: Nodes with no user pods (system pods only)

## Timing Expectations

### Pod Scaling Times
- **Scale Up**: 30-60 seconds
  - HPA evaluation: 15s intervals
  - Pod creation: 10-30s
  - Container startup: 5-15s

- **Scale Down**: 5-10 minutes
  - Default scale-down delay: 5 minutes
  - Graceful termination: 30s

### Node Scaling Times
- **Scale Up (New Node)**:
  - EC2 instance launch: 1-2 minutes
  - Node registration: 30-60 seconds
  - Pod scheduling: 10-30 seconds
  - **Total: 2-4 minutes**

- **Scale Down (Node Termination)**:
  - Pod eviction: 1-2 minutes
  - Graceful shutdown: 30s
  - Node drain: 2-5 minutes
  - EC2 termination: 1-2 minutes
  - **Total: 10-15 minutes**

## Resource Monitoring Commands

### Real-time Monitoring
```bash
# Watch HPA scaling
watch kubectl get hpa

# Monitor pod scaling
watch kubectl get pods -l app=your-app

# Check node utilization
watch kubectl top nodes

# Monitor pending pods
watch "kubectl get pods --all-namespaces | grep Pending"

# ASG status
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names your-asg-name
```

### Detailed Resource Analysis
```bash
# Node allocatable resources
kubectl describe nodes

# Pod resource requests/limits
kubectl describe pod pod-name

# HPA metrics
kubectl describe hpa hpa-name

# Events for troubleshooting
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Scaling Scenarios

### Scenario 1: CPU Spike
```
1. Application receives high traffic
2. CPU usage increases > 50%
3. HPA triggers scale-up in 15-30s
4. New pods created in 30-60s
5. Load distributed, CPU normalizes
```

### Scenario 2: Memory Pressure + Node Scaling
```
1. Memory-intensive workload deployed
2. Pods request more memory than available
3. Pods enter Pending state
4. ASG detects unschedulable pods
5. New node launched in 2-4 minutes
6. Pending pods scheduled to new node
```

### Scenario 3: Scale Down
```
1. Load decreases
2. HPA waits 5 minutes (scale-down delay)
3. Pods terminated gradually
4. Node utilization drops < 50%
5. ASG waits 10+ minutes
6. Empty/underutilized nodes terminated
```

## Optimization Tips

### HPA Optimization
- Set appropriate CPU/memory requests
- Use custom metrics for better scaling decisions
- Tune scale-up/down policies
- Monitor metric collection intervals

### ASG Optimization
- Configure appropriate instance types
- Set reasonable min/max/desired capacity
- Use mixed instance types for cost optimization
- Enable detailed monitoring

### Cost Optimization
- Use Spot instances for non-critical workloads
- Right-size instance types
- Implement cluster autoscaler
- Monitor unused resources

## Troubleshooting

### Common Issues
1. **HPA not scaling**: Check metrics server, resource requests
2. **Nodes not scaling**: Verify ASG configuration, IAM permissions
3. **Slow scaling**: Review scaling policies, instance types
4. **Resource waste**: Monitor utilization, adjust requests/limits

### Debug Commands
```bash
# Check metrics server
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

# HPA debug
kubectl describe hpa your-hpa

# Node conditions
kubectl describe node node-name

# ASG activities
aws autoscaling describe-scaling-activities --auto-scaling-group-name your-asg
```
