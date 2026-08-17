output "endpoint" {
  description = "ElastiCache Redis endpoint (hostname)"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "port" {
  description = "ElastiCache Redis port"
  value       = aws_elasticache_cluster.main.port
}

output "security_group_id" {
  description = "Security group ID for the ElastiCache cluster"
  value       = aws_security_group.redis.id
}

output "cluster_id" {
  description = "ElastiCache cluster identifier"
  value       = aws_elasticache_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ElastiCache cluster"
  value       = aws_elasticache_cluster.main.arn
}
