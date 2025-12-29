# CPU and Memory Calculation Guide for HPA/ASG Testing

## Understanding Kubernetes Resource Units

### CPU Units
- **1 CPU** = 1000 millicores (1000m)
- **100m** = 0.1 CPU core
- **500m** = 0.5 CPU core
- **1000m** = 1 full CPU core

### Memory Units
- **Ki** = Kibibyte (1024 bytes)
- **Mi** = Mebibyte (1024 Ki = 1,048,576 bytes)
- **Gi** = Gibibyte (1024 Mi = 1,073,741,824 bytes)

## HPA CPU Calculation

### Test Case: CPU-Intensive HPA
```yaml
resources:
  requests:
    cpu: 100m      # Request 0.1 CPU core
    memory: 128Mi  # Request 128 MB
  limits:
    cpu: 200m      # Limit to 0.2 CPU core
    memory: 256Mi  # Limit to 256 MB
```

### HPA Threshold Calculation
```
HPA Target: 50% CPU utilization
Pod CPU Request: 100m
Trigger Point: 100m × 50% = 50m actual usage

When pod uses > 50m CPU → HPA scales up
When pod uses < 50m CPU → HPA scales down
```

### Our Test Results
```
Initial CPU Usage: 27m (27% of 100m request)
Peak CPU Usage: 100m+ (100%+ of 100m request)
Scaling Triggered: Yes (exceeded 50% threshold)
```

### CPU Calculation Formula
```
CPU Percentage = (Actual CPU Usage / CPU Request) × 100

Example:
- Actual Usage: 75m
- CPU Request: 100m  
- CPU Percentage: (75m / 100m) × 100 = 75%
```

## ASG Memory Calculation

### Node Capacity Analysis
```bash
# Check node capacity
kubectl describe node <node-name> | grep -A 5 "Capacity:"
```

### Typical t3.medium Node:
```
Total Memory: ~4GB (3.8GB usable)
System Reserved: ~0.5GB
Available for Pods: ~3.3GB
```

### Test Case: Memory-Intensive ASG
```yaml
resources:
  requests:
    memory: 800Mi  # Request 800 MB per pod
    cpu: 100m
  limits:
    memory: 1Gi    # Limit to 1 GB per pod
    cpu: 200m
```

### Memory Calculation per Node
```
Node Available Memory: 3.3GB (3,379Mi)
Pod Memory Request: 800Mi
Pods per Node: 3,379Mi ÷ 800Mi = 4.2 → 4 pods max

With 20 pods requested:
Required Nodes: 20 pods ÷ 4 pods/node = 5 nodes
Current Nodes: 4
Additional Nodes Needed: 1
```

## Practical Calculation Examples

### Example 1: HPA Scaling Calculation
```
Scenario: Web application with variable load

Pod Configuration:
- CPU Request: 200m
- Memory Request: 256Mi
- HPA Target: 70% CPU

Calculations:
- Scale-up trigger: 200m × 70% = 140m actual usage
- Scale-down trigger: 200m × 70% = 140m actual usage
- Current usage: 180m → (180m/200m) × 100 = 90% → Scale UP
```

### Example 2: ASG Node Requirement
```
Scenario: Batch processing jobs

Pod Configuration:
- Memory Request: 1.5Gi per pod
- CPU Request: 500m per pod
- Job Pods: 15

Node Capacity (t3.large):
- Memory: 8GB (7.5GB usable)
- CPU: 2 cores (2000m)

Memory Constraint:
- Pods per node: 7.5GB ÷ 1.5GB = 5 pods
- Required nodes: 15 pods ÷ 5 pods/node = 3 nodes

CPU Constraint:
- Pods per node: 2000m ÷ 500m = 4 pods
- Required nodes: 15 pods ÷ 4 pods/node = 3.75 → 4 nodes

Limiting Factor: CPU (need 4 nodes)
```

## Monitoring Commands for Calculations

### Check Current Resource Usage
```bash
# Pod resource usage
kubectl top pods
kubectl top pods --containers

# Node resource usage
kubectl top nodes

# Detailed pod resource info
kubectl describe pod <pod-name> | grep -A 10 "Requests:"
```

### Check Node Capacity
```bash
# Node allocatable resources
kubectl describe nodes | grep -A 5 "Allocatable:"

# Node resource allocation
kubectl describe nodes | grep -A 10 "Allocated resources:"
```

### HPA Metrics
```bash
# Current HPA status
kubectl get hpa

# Detailed HPA metrics
kubectl describe hpa <hpa-name>

# HPA scaling history
kubectl get events | grep HorizontalPodAutoscaler
```

## Resource Planning Formulas

### HPA Planning
```
Required Replicas = (Current Metric Value / Target Metric Value) × Current Replicas

Example:
- Current CPU: 150m
- Target CPU: 100m (70% of 143m request)
- Current Replicas: 2
- Required Replicas: (150/100) × 2 = 3 replicas
```

### ASG Planning
```
Required Nodes = ceil(Total Pod Requests / Node Capacity)

Memory Example:
- Total Memory Requests: 20 pods × 800Mi = 16,000Mi
- Node Memory Capacity: 3,300Mi
- Required Nodes: ceil(16,000 ÷ 3,300) = ceil(4.85) = 5 nodes
```

## Best Practices for Resource Sizing

### HPA Sizing
1. **Set realistic requests**: Based on actual application usage
2. **Use 50-80% thresholds**: Avoid too sensitive scaling
3. **Monitor for 5+ minutes**: Allow metrics to stabilize
4. **Consider both CPU and memory**: Use multiple metrics

### ASG Sizing
1. **Plan for peak load**: Size for maximum expected pods
2. **Account for system overhead**: ~15-20% of node capacity
3. **Consider startup time**: Nodes take 2-3 minutes to ready
4. **Set appropriate max limits**: Prevent runaway scaling

## Troubleshooting Resource Issues

### Common HPA Issues
```bash
# Check if metrics server is running
kubectl get pods -n kube-system | grep metrics-server

# Verify pod has resource requests
kubectl describe pod <pod-name> | grep -A 5 "Requests:"

# Check HPA can get metrics
kubectl describe hpa <hpa-name> | grep -A 5 "Metrics:"
```

### Common ASG Issues
```bash
# Check cluster autoscaler logs
kubectl logs -l app=cluster-autoscaler -n kube-system

# Check for pending pods
kubectl get pods | grep Pending

# Check node resource pressure
kubectl describe nodes | grep -A 5 "Conditions:"
```
