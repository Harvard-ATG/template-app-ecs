variable "env" {
  description = "Environment (dev or prod)"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "template-app-ecs"
}

variable "app_name_short" {
  description = "Short application name for resource naming (max 6 chars to allow for suffixes like -api)"
  type        = string
  default     = "tmpapp"
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "image" {
  description = "Docker image URI"
  type        = string
}

variable "task_count" {
  description = "Number of tasks to run"
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = string
  default     = "512"
}

variable "load_balancer" {
  description = "Load balancer configuration"
  type = object({
    security_group_id  = string
    https_listener_arn = string
    dns_name           = string
    zone_id            = string
  })
}

variable "database_endpoint" {
  description = "PostgreSQL database endpoint (hostname) - from RDS module"
  type        = string
  default     = ""
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

variable "redis_endpoint" {
  description = "Redis endpoint (hostname) - from ElastiCache module (optional)"
  type        = string
  default     = ""
}

variable "route53_zone_name" {
  description = "Route53 zone name (leave empty to use default)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Custom domain name (leave empty to use default)"
  type        = string
  default     = ""
}
