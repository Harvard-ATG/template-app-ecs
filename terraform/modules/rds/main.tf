locals {
  identifier = "atg-${var.app_name}-${var.env}"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Get network information
module "network_data" {
  source = "../vendor/network-data"
  env    = var.env
}

# Get environment constants (default tags, etc)
module "constants" {
  source  = "../vendor/constants"
  env     = var.env
  product = var.app_name
}

# Generate a random password for the RDS master user
resource "random_password" "master_password" {
  length  = 32
  special = true
  # Avoid characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store the password in AWS Systems Manager Parameter Store
resource "aws_ssm_parameter" "database_password" {
  name        = "/${var.env}/${var.app_name}-api/database_password"
  description = "RDS master password for ${var.app_name} ${var.env}"
  type        = "SecureString"
  value       = random_password.master_password.result
  tags        = module.constants.default_tags

  lifecycle {
    ignore_changes = [value]
  }
}

# DB Subnet Group - use private subnets for RDS
resource "aws_db_subnet_group" "main" {
  name       = "${local.identifier}-subnet-group"
  subnet_ids = module.network_data.private_subnet_ids

  tags = merge(
    module.constants.default_tags,
    {
      Name = "${local.identifier}-subnet-group"
    }
  )
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${local.identifier}-rds-sg"
  description = "Security group for ${var.app_name} RDS instance in ${var.env}"
  vpc_id      = module.network_data.vpc_id

  tags = merge(
    module.constants.default_tags,
    {
      Name = "${local.identifier}-rds-sg"
    }
  )
}

# Allow inbound PostgreSQL traffic from ECS tasks
resource "aws_security_group_rule" "rds_ingress_from_ecs" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow PostgreSQL access from ECS tasks"
}

# Allow inbound PostgreSQL traffic from VPN (for admin access)
resource "aws_security_group_rule" "rds_ingress_from_vpn" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = module.network_data.vpn_private_cidr_blocks
  security_group_id = aws_security_group.rds.id
  description       = "Allow PostgreSQL access from VPN"
}

# Allow all outbound traffic
resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = local.identifier

  # Engine configuration
  engine               = "postgres"
  engine_version       = var.postgres_version
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = "gp3"
  storage_encrypted    = true

  # Database configuration
  db_name  = var.database_name
  username = var.master_username
  password = random_password.master_password.result
  port     = 5432

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = var.backup_retention_days
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  copy_tags_to_snapshot   = true
  delete_automated_backups = false

  # High availability
  multi_az = var.multi_az

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  # Deletion protection
  deletion_protection = var.deletion_protection

  # Allow minor version upgrades automatically
  auto_minor_version_upgrade = true
  apply_immediately          = false

  # Parameter group (using default for now, can be customized)
  parameter_group_name = "default.postgres16"

  tags = merge(
    module.constants.default_tags,
    {
      Name = local.identifier
    }
  )

  lifecycle {
    # Prevent accidental deletion in production
    prevent_destroy = false
    
    # Ignore password changes after initial creation
    ignore_changes = [password]
  }
}
