output "repository_arn" {
  description = "Full ARN of the repository"
  value       = aws_ecr_repository.default.arn
}

output "repository_url" {
  description = "The URL of the repository (in the form aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName)."
  value       = aws_ecr_repository.default.repository_url
}

output "registry_url" {
  description = "The registry ID where the repository was created."
  value       = aws_ecr_repository.default.registry_id
}

output "name" {
  description = "The name of the repository"
  value       = aws_ecr_repository.default.name
}
