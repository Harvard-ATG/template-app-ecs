output "vpc_id" {
  description = "VPC ID for the environment."
  value       = local.vpc_id
}
output "public_subnet_ids" {
  description = "List of public subnet IDs for the environment."
  value       = local.public_subnet_ids
}
output "private_subnet_ids" {
  description = "List of private subnet IDs for the environment."
  value       = local.private_subnet_ids
}
output "vpn_private_cidr_blocks" {
  description = "List of VPN private CIDR blocks."
  value       = local.vpn_private_cidr_blocks
}
