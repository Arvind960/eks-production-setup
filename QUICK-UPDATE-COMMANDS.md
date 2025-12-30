# Quick Component Update Commands

## kubectl Update
```bash
# Download and install kubectl v1.32.0
curl -LO https://dl.k8s.io/release/v1.32.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bash_profile
kubectl version --client
```

## VPC CNI Update
```bash
# Method 1: AWS CLI
aws eks update-addon --cluster-name <cluster-name> --addon-name vpc-cni --addon-version v1.19.0-eksbuild.1 --resolve-conflicts OVERWRITE

# Method 2: kubectl
kubectl set image daemonset aws-node -n kube-system aws-node=602401143452.dkr.ecr.ap-south-1.amazonaws.com/amazon-k8s-cni:v1.19.0-eksbuild.1
kubectl set image daemonset aws-node -n kube-system aws-node-init=602401143452.dkr.ecr.ap-south-1.amazonaws.com/amazon-k8s-cni-init:v1.19.0-eksbuild.1
```

## AWS Load Balancer Controller Update
```bash
kubectl set image deployment/aws-load-balancer-controller -n kube-system controller=602401143452.dkr.ecr.ap-south-1.amazonaws.com/amazon/aws-load-balancer-controller:v2.8.1
kubectl rollout status deployment/aws-load-balancer-controller -n kube-system
```

## CoreDNS Update
```bash
# Method 1: AWS CLI
aws eks update-addon --cluster-name <cluster-name> --addon-name coredns --addon-version v1.11.3-eksbuild.1 --resolve-conflicts OVERWRITE

# Method 2: kubectl
kubectl set image deployment/coredns -n kube-system coredns=602401143452.dkr.ecr.ap-south-1.amazonaws.com/eks/coredns:v1.11.3-eksbuild.1
```

## kube-proxy Update
```bash
# Method 1: AWS CLI
aws eks update-addon --cluster-name <cluster-name> --addon-name kube-proxy --addon-version v1.32.0-eksbuild.2 --resolve-conflicts OVERWRITE

# Method 2: kubectl
kubectl set image daemonset/kube-proxy -n kube-system kube-proxy=602401143452.dkr.ecr.ap-south-1.amazonaws.com/eks/kube-proxy:v1.32.0-minimal-eksbuild.2
```

## Cluster Autoscaler Update
```bash
kubectl set image deployment/cluster-autoscaler -n kube-system cluster-autoscaler=registry.k8s.io/autoscaling/cluster-autoscaler:v1.32.0
kubectl rollout restart deployment/cluster-autoscaler -n kube-system
kubectl rollout status deployment/cluster-autoscaler -n kube-system
```

## Verification Commands
```bash
# Check all component versions
./check-component-versions.sh

# Check specific components
kubectl describe ds aws-node -n kube-system | grep Image:
kubectl describe deployment coredns -n kube-system | grep Image:
kubectl describe ds kube-proxy -n kube-system | grep Image:
kubectl describe deployment cluster-autoscaler -n kube-system | grep Image:
kubectl describe deployment aws-load-balancer-controller -n kube-system | grep Image:

# Check pod status
kubectl get pods -n kube-system
```
