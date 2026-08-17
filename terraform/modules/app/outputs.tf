output "api_service_arn" {
  description = "ARN of the API ECS service"
  value       = module.ecs_app_api.service_arn
}

output "api_task_definition_arn" {
  description = "ARN of the API task definition"
  value       = module.ecs_app_api.task_definition_arn
}

output "migration_task_definition_arn" {
  description = "ARN of the migration task definition"
  value       = aws_ecs_task_definition.migration.arn
}

output "api_security_group_id" {
  description = "Security group ID for the API service"
  value       = module.ecs_app_api.security_group_id
}

output "ecs_security_group_id" {
  description = "ECS security group ID (alias for api_security_group_id, used by RDS/ElastiCache modules)"
  value       = module.ecs_app_api.security_group_id
}

output "domain_name" {
  description = "Domain name for the application"
  value       = module.route53.record_name
}

output "api_task_role_arn" {
  description = "ARN of the API task role"
  value       = module.ecs_app_api.task_role_arn
}

output "api_task_execution_role_arn" {
  description = "ARN of the API task execution role"
  value       = module.ecs_app_api.task_execution_role_arn
}
