# Production EKS Configuration
aws_region     = "ap-south-1"
cluster_name   = "eks-terraform-cluster"
k8s_version    = "1.32"
instance_type  = "t3.small"
min_nodes      = 2
max_nodes      = 5
desired_nodes  = 2
