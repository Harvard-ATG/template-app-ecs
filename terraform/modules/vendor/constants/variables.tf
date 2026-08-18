# See https://enterprisearchitecture.harvard.edu/enterprise-tags
variable "product" {
  type        = string
  description = "HUIT Enterprise Standard Tag. Used for AWS cost reporting, typically the application name."
  default     = "atgapp"
}

variable "env" {
  description = "The environment for this deployment, e.g., dev, qa, prod"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "stage", "prod"], var.env)
    error_message = "Must be one of the standard env names used by the team."
  }
  default = "dev"
}

variable "environment_map" {
  description = "HUIT Enterprise Standard Tag. Maps env to Development, Test, Stage, Production."
  type        = map(string)
  default = {
    "dev"   = "Development"
    "qa"    = "Test"
    "stage" = "Stage"
    "prod"  = "Production"
  }
}

variable "department" {
  type        = string
  description = "The name of the department or team responsible for the application (e.g. atg, uw, etc)"
  validation {
    condition     = contains(["atg", "uw", "at"], var.department)
    error_message = "Must be one of the standard department names used by the team."
  }
  default = "atg"
}

# https://privsec.harvard.edu/classify-risk
variable "data_class" {
  description = "HUIT Enterprise Standard Tag. The data classification (i.e. Level4 or Nonlevel4)."
  type        = string
  validation {
    condition     = contains(["Nonlevel4", "Level4"], var.data_class)
    error_message = "Must conform to HUIT enterprise tagging standard."
  }
  default = "Nonlevel4"
}

variable "hosted_by" {
  description = "HUIT Enterprise Standard Tag. Identifies the group responsible for vulnerability remediation tasks."
  validation {
    condition     = contains(["AcademicTech", "AcademicTech-FAS", "AcademicTech-UW"], var.hosted_by)
    error_message = "Must conform to HUIT enterprise tagging standard."
  }
  default = "AcademicTech-FAS"
}

variable "criticality" {
  description = "HUIT Enterprise Standard Tag. Used to identify the criticality of the resource."
  validation {
    condition     = contains(["Non-Critical", "Important", "Critical", "Mission Critical", "Foundational / Life Safety"], var.criticality)
    error_message = "Must conform to HUIT enterprise tagging standard."
  }
  default = "Important"
}
