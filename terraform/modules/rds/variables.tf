variable "env" {
  description = "Environment (dev, prod)"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class (e.g., db.t3.micro, db.t3.small)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling in GB"
  type        = number
  default     = 100
}

variable "postgres_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.3"
}

variable "database_name" {
  description = "Name of the default database to create"
  type        = string
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying (set to false for prod)"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection (recommended for prod)"
  type        = bool
  default     = false
}

variable "allowed_security_group_id" {
  description = "Security group ID allowed to connect to RDS (typically ECS security group)"
  type        = string
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}
