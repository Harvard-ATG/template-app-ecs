variable "env" {
  description = "Environment (dev, prod)"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "git_repo" {
  description = "Git repository URL (SSH format)"
  type        = string
}

variable "git_version" {
  description = "Git branch or tag to build"
  type        = string
  default     = "main"
}

variable "ecr_repository_name" {
  description = "Base ECR repository name (will build -api and -web suffixed repos)"
  type        = string
}

variable "build_ssh_key_ssm_path" {
  description = "SSM Parameter path containing GitHub SSH private key"
  type        = string
}

variable "buildspec_path" {
  description = "Path to buildspec.yml file relative to repository root"
  type        = string
  default     = "buildspec.yml"
}

variable "build_timeout" {
  description = "Build timeout in minutes"
  type        = number
  default     = 45
}
