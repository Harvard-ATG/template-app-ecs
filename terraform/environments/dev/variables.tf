variable "env" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "template-app-ecs"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "task_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "template_app"
}

variable "database_username" {
  description = "PostgreSQL database username"
  type        = string
  default     = "template_app"
}

variable "rds_instance_class" {
  description = "RDS instance class (can be upgraded later without data loss)"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB (can be increased later)"
  type        = number
  default     = 20
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}
