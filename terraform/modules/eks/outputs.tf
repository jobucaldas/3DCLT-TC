output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "eks_cluster_ca" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "keda_operator_role_arn" {
  value = aws_iam_role.keda_operator.arn
}

output "external_secrets_role_arn" {
  value = aws_iam_role.external_secrets.arn
}

output "app_pods_role_arn" {
  value = aws_iam_role.app_pods.arn
}

output "update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}
