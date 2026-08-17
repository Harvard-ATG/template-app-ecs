output "project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.main.name
}

output "project_arn" {
  description = "CodeBuild project ARN"
  value       = aws_codebuild_project.main.arn
}

output "webhook_url" {
  description = "GitHub webhook URL"
  value       = aws_codebuild_webhook.main.payload_url
}

output "webhook_secret" {
  description = "GitHub webhook secret"
  value       = aws_codebuild_webhook.main.secret
  sensitive   = true
}
