variable "env" {
  description = "Environment (dev, prod)"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type (e.g., cache.t3.micro, cache.t3.small)"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes (1 for non-clustered)"
  type        = number
  default     = 1
}

variable "redis_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "parameter_group_family" {
  description = "Redis parameter group family"
  type        = string
  default     = "redis7"
}

variable "port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "allowed_security_group_id" {
  description = "Security group ID allowed to connect to Redis (typically ECS security group)"
  type        = string
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain automatic snapshots (0 to disable)"
  type        = number
  default     = 5
}

variable "snapshot_window" {
  description = "Daily time range for snapshots (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "maintenance_window" {
  description = "Weekly maintenance window (UTC)"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover (requires num_cache_nodes > 1)"
  type        = bool
  default     = false
}

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Enable encryption in transit (TLS)"
  type        = bool
  default     = false
}
