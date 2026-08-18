output "ecr_api_repository_url" {
  description = "ECR API repository URL"
  value       = module.ecr_api.repository_url
}

output "ecr_web_repository_url" {
  description = "ECR Web repository URL"
  value       = module.ecr_web.repository_url
}

output "api_service_arn" {
  description = "ARN of the API ECS service"
  value       = module.template_app.api_service_arn
}

output "web_service_arn" {
  description = "ARN of the Web ECS service"
  value       = module.template_app.web_service_arn
}

output "domain_name" {
  description = "Domain name for the application"
  value       = module.template_app.domain_name
}

output "migration_task_definition_arn" {
  description = "ARN of the migration task definition"
  value       = module.template_app.migration_task_definition_arn
}
