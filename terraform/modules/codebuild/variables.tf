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

variable "ecr_repository_url" {
  description = "ECR repository URL for pushing images"
  type        = string
}

variable "dockerfile_path" {
  description = "Path to Dockerfile relative to repository root"
  type        = string
  default     = "Dockerfile"
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
