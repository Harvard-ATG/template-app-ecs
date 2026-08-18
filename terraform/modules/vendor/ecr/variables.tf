variable "department" {
  type        = string
  description = "The name of the department or team responsible for the application (e.g. atg, uw, etc)"
  default     = "atg"
}

variable "repository_name" {
  type        = string
  description = "The name of the ECR repository. This should be unique within the department."
  default     = "webapp"
}

variable "image_tag_mutability" {
  type        = string
  description = "The tag mutability setting for the repository."
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Must be one of: MUTABLE or IMMUTABLE."
  }
  # Default to MUTABLE for backwards compatibility
  default = "MUTABLE"
}

variable "scan_on_push" {
  type        = bool
  description = "Indicates whether images are scanned after being pushed to the repository."
  default     = true
}

variable "force_delete" {
  type        = bool
  description = "If true, will delete the repository even if it contains images."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the ECR repository."
  default     = {}
}

variable "expiration_after_days" {
  type        = number
  description = "Delete images older than X days. Set to 0 to disable."
  default     = 0
}

variable "cross_account_ids" {
  description = "List of AWS account IDs to grant ECR access to"
  type        = list(string)
  default     = ["363687077708"] # tlt-prod account
}
