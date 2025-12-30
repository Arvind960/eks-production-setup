# EKS Manual Upgrade Guide: 1.31 → 1.32

## Overview
This guide provides manual upgrade steps using AWS Console (GUI) and kubectl with YAML files.

## Reference Links for Component Versions

### Official AWS Documentation
- **EKS Version Guide**: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
- **Add-on Versions**: https://docs.aws.amazon.com/eks/latest/userguide/managing-add-ons.html
- **EKS Add-on Version Matrix**: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html

### Component Version References
1. **Cluster Autoscaler**: https://github.com/kubernetes/autoscaler/releases
2. **CoreDNS**: https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
3. **VPC CNI**: https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html
4. **kube-proxy**: https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html
5. **Metrics Server**: https://github.com/kubernetes-sigs/metrics-server/releases

### Version Compatibility Matrix for Kubernetes 1.32
```
Component               Version for K8s 1.32
--------------------------------------------------
Cluster Autoscaler      v1.32.0
CoreDNS                 v1.11.3-eksbuild.1
VPC CNI                 v1.19.0-eksbuild.1
kube-proxy              v1.32.0-eksbuild.2
Metrics Server          v0.7.2
```

## Manual Upgrade Steps

### Step 1: Upgrade Control Plane (AWS Console)

1. **Navigate to EKS Console**
   - Go to: https://console.aws.amazon.com/eks/
   - Select your region: `ap-south-1`
   - Click on cluster: `eks-terraform-cluster`

2. **Upgrade Control Plane**
   - Click **"Update cluster version"** button
   - Select **Kubernetes version**: `1.32`
   - Click **"Update"**
   - Wait 10-15 minutes for completion

### Step 2: Upgrade Node Groups (AWS Console)

1. **Navigate to Node Groups**
   - In EKS cluster page, click **"Compute"** tab
   - Click on node group: `workers`

2. **Update Node Group**
   - Click **"Update now"** button
   - Select **Kubernetes version**: `1.32`
   - Choose update strategy: **Rolling update**
   - Click **"Update"**
   - Wait 15-20 minutes for completion

### Step 3: Update Add-ons (AWS Console)

#### CoreDNS
1. Go to **"Add-ons"** tab in EKS cluster
2. Select **coredns** → Click **"Edit"**
3. Version: `v1.11.3-eksbuild.1`
4. Conflict resolution: **Overwrite**
5. Click **"Save changes"**

#### VPC CNI
1. Select **vpc-cni** → Click **"Edit"**
2. Version: `v1.19.0-eksbuild.1`
3. Click **"Save changes"**

#### kube-proxy
1. Select **kube-proxy** → Click **"Edit"**
2. Version: `v1.32.0-eksbuild.2`
3. Click **"Save changes"**

### Step 4: Update Cluster Autoscaler (kubectl + YAML)

Create the updated YAML file:

```yaml
# cluster-autoscaler-1.32.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    app: cluster-autoscaler
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
      annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/port: '8085'
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
      - image: registry.k8s.io/autoscaling/cluster-autoscaler:v1.32.0
        name: cluster-autoscaler
        resources:
          limits:
            cpu: 100m
            memory: 600Mi
          requests:
            cpu: 100m
            memory: 600Mi
        command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/eks-terraform-cluster
        - --balance-similar-node-groups
        - --skip-nodes-with-system-pods=false
        volumeMounts:
        - name: ssl-certs
          mountPath: /etc/ssl/certs/ca-certificates.crt
          readOnly: true
        imagePullPolicy: "Always"
        env:
        - name: AWS_REGION
          value: ap-south-1
      volumes:
      - name: ssl-certs
        hostPath:
          path: "/etc/ssl/certs/ca-bundle.crt"
```

Apply the update:
```bash
kubectl apply -f cluster-autoscaler-1.32.yaml
```

### Step 5: Update Metrics Server (kubectl + YAML)

```yaml
# metrics-server-1.32.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  strategy:
    rollingUpdate:
      maxUnavailable: 0
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=10250
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        image: registry.k8s.io/metrics-server/metrics-server:v0.7.2
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /livez
            port: https
            scheme: HTTPS
          periodSeconds: 10
        name: metrics-server
        ports:
        - containerPort: 10250
          name: https
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /readyz
            port: https
            scheme: HTTPS
          initialDelaySeconds: 20
          periodSeconds: 10
        resources:
          requests:
            cpu: 100m
            memory: 200Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          seccompProfile:
            type: RuntimeDefault
        volumeMounts:
        - mountPath: /tmp
          name: tmp-dir
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-cluster-critical
      serviceAccountName: metrics-server
      volumes:
      - emptyDir: {}
        name: tmp-dir
```

Apply the update:
```bash
kubectl apply -f metrics-server-1.32.yaml
```

## Verification Commands

### Check Cluster Version
```bash
# Via AWS CLI
aws eks describe-cluster --name eks-terraform-cluster --region ap-south-1 --query 'cluster.version'

# Via kubectl
kubectl version --short
```

### Check Node Versions
```bash
kubectl get nodes -o wide
```

### Check Add-on Versions
```bash
# CoreDNS
kubectl get deployment coredns -n kube-system -o jsonpath='{.spec.template.spec.containers[0].image}'

# Metrics Server
kubectl get deployment metrics-server -n kube-system -o jsonpath='{.spec.template.spec.containers[0].image}'

# Cluster Autoscaler
kubectl get deployment cluster-autoscaler -n kube-system -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Check System Pods
```bash
kubectl get pods -n kube-system
```

### Test HPA Functionality
```bash
kubectl get hpa --all-namespaces
kubectl top nodes
kubectl top pods --all-namespaces
```

## Troubleshooting

### Common Issues and Solutions

1. **Node group upgrade stuck**
   - Check Auto Scaling Group in EC2 console
   - Ensure sufficient capacity for rolling update

2. **Pods not scheduling**
   - Check node taints: `kubectl describe nodes`
   - Verify resource requests vs available capacity

3. **Cluster Autoscaler not working**
   - Check logs: `kubectl logs -f deployment/cluster-autoscaler -n kube-system`
   - Verify IAM permissions for autoscaling

4. **Metrics Server issues**
   - Check logs: `kubectl logs -f deployment/metrics-server -n kube-system`
   - Verify API service: `kubectl get apiservice v1beta1.metrics.k8s.io`

### Useful Commands
```bash
# Check cluster events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check node conditions
kubectl describe nodes

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check cluster info
kubectl cluster-info
```

## Post-Upgrade Checklist

- [ ] Control plane upgraded to 1.32
- [ ] Node groups upgraded to 1.32
- [ ] All add-ons updated to compatible versions
- [ ] Cluster Autoscaler updated to v1.32.0
- [ ] Metrics Server updated to v0.7.2
- [ ] All system pods running
- [ ] HPA functionality tested
- [ ] Application workloads verified
- [ ] Monitoring and logging working

## Additional Resources

- **AWS EKS Best Practices**: https://aws.github.io/aws-eks-best-practices/
- **Kubernetes 1.32 Release Notes**: https://kubernetes.io/docs/setup/release/notes/
- **EKS Troubleshooting**: https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html
