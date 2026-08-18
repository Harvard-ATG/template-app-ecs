variable "env" {
  description = "The environment name (dev, qa, prod, etc)."
  type        = string
  default     = "dev"
}

variable "vpc_ids" {
  description = "VPC IDs for each environment. REQUIRED: Update with your AWS VPC IDs before use."
  type        = map(string)
  default = {
    "dev"  = "vpc-XXXXXXXXX"  # Replace with your dev VPC ID
    "qa"   = "vpc-XXXXXXXXX"  # Replace with your QA VPC ID
    "prod" = "vpc-XXXXXXXXX"  # Replace with your prod VPC ID
  }
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for each environment. REQUIRED: Update with your AWS subnet IDs."
  type        = map(list(string))
  default = {
    "dev"  = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]  # Replace with your dev public subnets
    "qa"   = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]  # Replace with your QA public subnets
    "prod" = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]  # Replace with your prod public subnets
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for each environment. REQUIRED: Update with your AWS subnet IDs."
  type        = map(list(string))
  default = {
    "dev"  = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]  # Replace with your dev private subnets
    "qa"   = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]  # Replace with your QA private subnets
    "prod" = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]  # Replace with your prod private subnets
  }
}

variable "vpn_private_cidr_blocks" {
  default     = ["10.0.0.0/8"]  # Replace with your organization's VPN CIDR blocks
  description = "VPN CIDR blocks that need access to resources"
  type        = list(string)
}
