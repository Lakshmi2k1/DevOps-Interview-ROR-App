output "region" {
  description = "AWS region."
  value       = var.region
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "configure_kubectl" {
  description = "Command to configure kubectl for the cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ecr_rails_repository_url" {
  description = "ECR repository URL for the Rails application image."
  value       = aws_ecr_repository.this["rails"].repository_url
}

output "ecr_nginx_repository_url" {
  description = "ECR repository URL for the Nginx image."
  value       = aws_ecr_repository.this["nginx"].repository_url
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (host)."
  value       = aws_db_instance.this.address
}

output "rds_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the RDS credentials."
  value       = aws_secretsmanager_secret.db.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket used by the application."
  value       = aws_s3_bucket.media.id
}

output "app_irsa_role_arn" {
  description = "IAM role ARN assumed by the application pods for S3 access (set as serviceAccount.roleArn in the Helm chart)."
  value       = module.app_irsa.iam_role_arn
}

output "db_name" {
  description = "Initial database name (Helm value env.RDS_DB_NAME)."
  value       = var.db_name
}

output "db_username" {
  description = "RDS master username (Helm value env.RDS_USERNAME)."
  value       = var.db_username
}

output "app_namespace" {
  description = "Namespace the app is expected to run in (must match the IRSA binding)."
  value       = var.app_namespace
}

output "github_actions_role_arn" {
  description = "IAM role ARN for the GitHub Actions ECR workflow. Store this as the AWS_ROLE_ARN secret in the GitHub repo."
  value       = var.enable_github_oidc ? aws_iam_role.github_actions[0].arn : null
}

output "application_url_command" {
  description = "Command to fetch the public ALB hostname once the Ingress is provisioned by the Helm release."
  value       = "kubectl get ingress -n ${var.app_namespace} -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'"
}

output "helm_install_hint" {
  description = "Example helm command wired to the Terraform outputs."
  value       = <<-EOT
    helm upgrade --install ror-app infrastructure/helm/ror-app \
      --namespace ${var.app_namespace} --create-namespace \
      --set image.rails.repository=${aws_ecr_repository.this["rails"].repository_url} \
      --set image.nginx.repository=${aws_ecr_repository.this["nginx"].repository_url} \
      --set serviceAccount.roleArn=${module.app_irsa.iam_role_arn} \
      --set env.RDS_HOSTNAME=${aws_db_instance.this.address} \
      --set env.RDS_DB_NAME=${var.db_name} \
      --set env.RDS_USERNAME=${var.db_username} \
      --set env.S3_BUCKET_NAME=${aws_s3_bucket.media.id} \
      --set env.S3_REGION_NAME=${var.region} \
      --set secret.RDS_PASSWORD=<from-secrets-manager>
  EOT
}
