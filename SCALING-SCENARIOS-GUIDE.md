# HPA and ASG Scaling Scenarios - Complete Examples

## HPA Scenarios

### Scenario 1: Basic CPU Scaling
**Setup**: 2 pods, CPU target 50%
**Trigger**: Average CPU > 50%
**Example**:
- Pod 1: 40% CPU, Pod 2: 70% CPU
- Average: (40+70)/2 = 55% > 50%
- **Result**: Scale to 3 pods

### Scenario 2: Memory Scaling
**Setup**: 3 pods, Memory target 80%
**Trigger**: Average Memory > 80%
**Example**:
- Pod 1: 70%, Pod 2: 85%, Pod 3: 90%
- Average: (70+85+90)/3 = 81.7% > 80%
- **Result**: Scale to 4 pods

### Scenario 3: Multi-Metric (CPU + Memory)
**Setup**: 4 pods, CPU 60%, Memory 75%
**Trigger**: ANY metric exceeds target
**Example**:
- CPU average: 45% (below 60%)
- Memory average: 80% (above 75%)
- **Result**: Scale up (memory triggered)

### Scenario 4: Mixed Pod Usage
**Setup**: 4 pods, CPU target 50%
**Example**:
- Pod 1: 30%, Pod 2: 40%, Pod 3: 45%, Pod 4: 85%
- Average: (30+40+45+85)/4 = 50%
- **Result**: Scale to 5 pods (exactly at threshold)

### Scenario 5: No Scaling Case
**Setup**: 3 pods, CPU target 70%
**Example**:
- Pod 1: 60%, Pod 2: 65%, Pod 3: 55%
- Average: (60+65+55)/3 = 60% < 70%
- **Result**: No scaling

## ASG Scenarios

### Scenario 1: Pending Pods (Most Common)
**Trigger**: Pods cannot be scheduled
**Example**:
- Node capacity: 2 CPU, 4GB RAM
- New pod requests: 1.5 CPU, 3GB RAM
- Existing usage: 1 CPU, 2GB RAM
- **Result**: Pod goes Pending → ASG scales up

### Scenario 2: Large Memory Request
**Trigger**: Single pod needs more memory than available
**Example**:
- Node available: 3.2GB RAM
- Pod requests: 4GB RAM
- **Result**: Pod Pending → New node launched

### Scenario 3: Batch Job Scaling
**Trigger**: Multiple pods need scheduling
**Example**:
- Job creates 10 pods simultaneously
- Each pod needs 1 CPU, 2GB RAM
- Current nodes can fit only 6 pods
- **Result**: 4 pods Pending → ASG adds nodes

### Scenario 4: Node Resource Exhaustion
**Trigger**: Node utilization > 80%
**Example**:
- Node: 2 CPU, 4GB RAM
- Current usage: 1.8 CPU, 3.5GB RAM
- New pod requests: 500m CPU, 1GB RAM
- **Result**: Cannot fit → ASG scales

### Scenario 5: Scale Down
**Trigger**: Low utilization for 10+ minutes
**Example**:
- 3 nodes, each <50% utilized
- All pods can fit on 2 nodes
- **Result**: ASG terminates 1 node

## Real Calculation Examples

### HPA Calculation Formula
```
Desired Replicas = ceil(Current Replicas × (Current Metric / Target Metric))
```

**Example 1**: CPU Scaling
- Current: 4 pods
- Current CPU: 75%
- Target CPU: 50%
- Calculation: ceil(4 × (75/50)) = ceil(6) = 6 pods

**Example 2**: Memory Scaling
- Current: 6 pods
- Current Memory: 90%
- Target Memory: 80%
- Calculation: ceil(6 × (90/80)) = ceil(6.75) = 7 pods

**Example 3**: Scale Down
- Current: 8 pods
- Current CPU: 30%
- Target CPU: 60%
- Calculation: ceil(8 × (30/60)) = ceil(4) = 4 pods

### ASG Node Calculations

**t3.medium Node Capacity**:
- Total: 2 vCPU, 4GB RAM
- Available: ~1.8 vCPU, ~3.2GB RAM (after system overhead)

**Example 1**: Pod Fitting
- Pod requests: 500m CPU, 1GB RAM
- Pods per node: min(1.8/0.5, 3.2/1) = min(3.6, 3.2) = 3 pods

**Example 2**: Memory Constraint
- Pod requests: 200m CPU, 2GB RAM
- Pods per node: min(1.8/0.2, 3.2/2) = min(9, 1.6) = 1 pod (memory limited)

## Test Commands

### Monitor HPA Scaling
```bash
# Watch HPA status
watch kubectl get hpa

# Check pod metrics
kubectl top pods

# View HPA details
kubectl describe hpa my-hpa
```

### Monitor ASG Scaling
```bash
# Watch nodes
watch kubectl get nodes

# Check pending pods
kubectl get pods --all-namespaces | grep Pending

# ASG activities
aws autoscaling describe-scaling-activities --auto-scaling-group-name my-asg
```

### Generate Load for Testing
```bash
# CPU load
kubectl run cpu-load --image=busybox --restart=Never -- /bin/sh -c "while true; do :; done"

# Memory load
kubectl run memory-load --image=progrium/stress --restart=Never -- --vm 1 --vm-bytes 2G
```

## Expected Timing

### HPA Timing
- **Metric collection**: Every 15 seconds
- **Scale up decision**: 15-30 seconds
- **Pod creation**: 30-60 seconds
- **Total scale up**: 1-2 minutes

### ASG Timing
- **Pending pod detection**: 30-60 seconds
- **Scale up decision**: 1-2 minutes
- **Node launch**: 2-3 minutes
- **Pod scheduling**: 30 seconds
- **Total scale up**: 4-6 minutes

### Scale Down Timing
- **HPA scale down delay**: 5 minutes (default)
- **ASG scale down delay**: 10-15 minutes
- **Node termination**: 2-3 minutes

## Common Patterns

### Pattern 1: Traffic Spike
1. Load increases → CPU/Memory rises
2. HPA scales pods (1-2 min)
3. If nodes full → ASG scales nodes (4-6 min)
4. Load distributes → Metrics normalize

### Pattern 2: Batch Processing
1. Job submitted → Multiple pods created
2. Pods go Pending → ASG triggered immediately
3. New nodes launch → Pods scheduled
4. Job completes → Pods terminate → Nodes scale down

### Pattern 3: Gradual Growth
1. Steady load increase → HPA scales gradually
2. Eventually hits node limits → ASG adds capacity
3. Growth continues → Process repeats
