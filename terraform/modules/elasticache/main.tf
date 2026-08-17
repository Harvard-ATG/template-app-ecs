locals {
  identifier = "atg-${var.app_name}-${var.env}"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Get network information
module "network_data" {
  source = "git::https://github.com/Harvard-ATG/atg-ops-appserver.git//terraform/modules/reusable/network-data?ref=main"
  env    = var.env
}

# Get tagging constants
module "constants" {
  source  = "git::https://github.com/Harvard-ATG/atg-ops-appserver.git//terraform/modules/reusable/constants?ref=main"
  env     = var.env
  product = var.app_name
}

# ElastiCache Subnet Group - use private subnets
resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.identifier}-cache-subnet-group"
  subnet_ids = module.network_data.private_subnet_ids

  tags = merge(
    module.constants.default_tags,
    {
      Name = "${local.identifier}-cache-subnet-group"
    }
  )
}

# Security Group for ElastiCache
resource "aws_security_group" "redis" {
  name        = "${local.identifier}-redis-sg"
  description = "Security group for ${var.app_name} ElastiCache Redis in ${var.env}"
  vpc_id      = module.network_data.vpc_id

  tags = merge(
    module.constants.default_tags,
    {
      Name = "${local.identifier}-redis-sg"
    }
  )
}

# Allow inbound Redis traffic from ECS tasks
resource "aws_security_group_rule" "redis_ingress_from_ecs" {
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_id
  security_group_id        = aws_security_group.redis.id
  description              = "Allow Redis access from ECS tasks"
}

# Allow inbound Redis traffic from VPN (for admin access)
resource "aws_security_group_rule" "redis_ingress_from_vpn" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = module.network_data.vpn_private_cidr_blocks
  security_group_id = aws_security_group.redis.id
  description       = "Allow Redis access from VPN"
}

# Allow all outbound traffic
resource "aws_security_group_rule" "redis_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redis.id
  description       = "Allow all outbound traffic"
}

# Parameter Group for Redis configuration
resource "aws_elasticache_parameter_group" "main" {
  name   = "${local.identifier}-redis-params"
  family = var.parameter_group_family

  # Optimize for session storage
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = merge(
    module.constants.default_tags,
    {
      Name = "${local.identifier}-redis-params"
    }
  )
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "main" {
  cluster_id           = local.identifier
  engine               = "redis"
  engine_version       = var.redis_version
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.main.name
  port                 = var.port

  # Network configuration
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  # Snapshot configuration
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window
  maintenance_window       = var.maintenance_window

  # Security
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled

  # Automatic minor version upgrades
  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = merge(
    module.constants.default_tags,
    {
      Name = local.identifier
    }
  )
}
