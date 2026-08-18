output "default_region" {
  description = "Default AWS region for the deployment"
  value       = local.default_region
}
output "default_tags" {
  description = "Default tags applied to all resources"
  value       = local.default_tags
}
output "default_route53_zone" {
  description = "Default Route 53 zone name based on environment"
  value       = local.default_route53_zone
}
output "resource_prefix" {
  description = "Prefix used for naming resources"
  value       = local.resource_prefix
}
