# Quick Resource Calculation Cheat Sheet

## Our Test Case Calculations

### HPA Test - CPU Intensive App
```
Pod Configuration:
├── CPU Request: 100m (0.1 core)
├── CPU Limit: 200m (0.2 core)  
├── Memory Request: 128Mi
└── Memory Limit: 256Mi

HPA Configuration:
├── Min Replicas: 2
├── Max Replicas: 8
└── CPU Target: 50%

Calculation:
├── Trigger Point: 100m × 50% = 50m
├── Actual Usage: 100m (100%)
├── Scale Decision: 100m > 50m → SCALE UP
└── Result: 2 → 8 pods
```

### ASG Test - Memory Intensive App
```
Pod Configuration:
├── Memory Request: 800Mi per pod
├── CPU Request: 100m per pod
└── Pod Count: 20

Node Capacity (t3.medium):
├── Total Memory: ~4GB
├── Available Memory: ~3.3GB (3,379Mi)
└── System Reserved: ~0.7GB

Calculation:
├── Pods per Node: 3,379Mi ÷ 800Mi = 4.2 → 4 pods
├── Required Nodes: 20 pods ÷ 4 pods/node = 5 nodes
├── Current Nodes: 4
└── Result: Scale from 4 → 5 nodes
```

## Resource Formulas

### HPA CPU Percentage
```
CPU % = (Actual CPU Usage / CPU Request) × 100

Example: 75m actual / 100m request = 75%
```

### ASG Node Requirements  
```
Required Nodes = ceil(Total Requests / Node Capacity)

Memory: ceil(16,000Mi / 3,379Mi) = 5 nodes
```

### Scaling Decisions
```
HPA: Current Usage > (Request × Target%) → Scale Up
ASG: Pending Pods > 0 → Scale Up Nodes
```

## Quick Commands
```bash
# Check current usage
kubectl top pods
kubectl top nodes

# Run calculations
./calculate-resources.sh

# Monitor scaling
kubectl get hpa -w
kubectl get nodes -w
```
