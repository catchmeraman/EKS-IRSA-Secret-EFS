output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "s3_reader_role_arn" {
  value = aws_iam_role.app_role.arn
}

output "efs_file_system_id" {
  value = aws_efs_file_system.eks_efs.id
}

output "efs_dns_name" {
  value = aws_efs_file_system.eks_efs.dns_name
}

output "secrets_manager_secret_arn" {
  value = aws_secretsmanager_secret.app_secret.arn
}

output "cloudwatch_role_arn" {
  value = aws_iam_role.cloudwatch_agent.arn
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}
