output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "node_group_arn" {
  description = "EKS node group ARN"
  value       = aws_eks_node_group.workers.arn
}

output "vpc_id" {
  description = "VPC ID used by the cluster"
  value       = data.aws_vpc.default.id
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "cluster_autoscaler_role_arn" {
  description = "Cluster Autoscaler IAM role ARN"
  value       = aws_iam_role.cluster_autoscaler.arn
}

output "cluster_autoscaler_status" {
  description = "Command to check cluster autoscaler status"
  value       = "kubectl get deployment cluster-autoscaler -n kube-system"
}
