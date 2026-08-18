variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "department" {
  type        = string
  description = "The name of the department or team responsible for the application (e.g. atg, uw, etc)"
  default     = "atg"
}

variable "env" {
  description = "The environment for this deployment, e.g., dev, qa, stage, prod"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "stage", "prod"], var.env)
    error_message = "The env variable must be one of: dev, qa, stage, prod."
  }
}

variable "app_name" {
  type        = string
  description = "The application name used for naming resources. This should be the same as the name of the product or service being deployed (e.g. catchpy)."
}

variable "app_name_short" {
  type        = string
  description = "A shortened version of the application name, used for naming resources with short character limits like ELBs."
  validation {
    condition     = length(var.app_name_short) <= 10
    error_message = "The app_name_short must be 10 characters or less."
  }
}

variable "cluster_name" {
  type        = string
  description = "The name of the ECS cluster where the service will be deployed"
}

variable "domain_names" {
  type        = list(string)
  description = "The domain names for the application. These are used for routing traffic to the application through the load balancer."
  default     = []
}

variable "network_config" {
  description = "Network configuration for the service"
  type = object({
    vpc_id              = string
    private_subnet_ids  = list(string)
    allowed_cidr_blocks = list(string)
  })
}

variable "fargate_version" {
  description = "The version of Fargate to use for the service. This should match the version of the AWS provider."
  type        = string
  default     = "1.4.0"
}

variable "task_cpu" {
  type        = number
  description = "The task CPU units to allocate for the ECS task. This is a measure of the CPU resources allocated to the task."
  default     = 1024
}

variable "task_memory" {
  type        = number
  description = "The task memory in MiB to allocate for the ECS task. This is the amount of memory allocated to the task."
  default     = 2048
}

variable "task_count" {
  type        = string
  description = "The desired number of task instances to run in the ECS service. This determines how many copies of the application will be running."
  default     = 0
}

variable "containers" {
  description = "List of container definitions for the ECS task"
  type = list(object({
    name      = string
    image     = string
    cpu       = optional(number, null)
    memory    = optional(number, null)
    essential = optional(bool, true)
    portMappings = optional(list(object({
      containerPort = number
      protocol      = optional(string, "tcp")
    })), [])
    environment = optional(list(object({
      name  = string
      value = string
    })), [])
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })), [])
    command    = optional(list(string), [])
    entryPoint = optional(list(string), [])
    linuxParameters = optional(object({
      initProcessEnabled = optional(bool, false)
    }), null)
    mountsPoints = optional(list(object({
      sourceVolume  = string
      containerPath = string
      readOnly      = optional(bool, false)
    })), [])
  }))
}

variable "load_balancer_config" {
  description = "Configuration for the load balancer"
  type = object({
    security_group_id    = string,
    https_listener_arn   = string,
    health_check_path    = string,
    health_check_matcher = string
  })
}

variable "splunk_enabled" {
  type        = bool
  description = "Enable Splunk logging for the application"
  default     = true
}

variable "splunk_url" {
  type        = string
  description = "The harvard splunk endpoint URL for logging. This is where the application will send its logs for monitoring and analysis."
  default     = "https://http-inputs-harvard.splunkcloud.com"
}

variable "splunk_index" {
  description = "Splunk index for this application"
  type        = string
  default     = "soc-isites"
}

variable "splunk_sourcetype" {
  description = "Splunk sourcetype for this application"
  type        = string
  default     = null
}

variable "enable_execute_command" {
  type        = bool
  description = "Enable ECS Exec for the service"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to ECS resources."
  default     = {}
}
