variable "env" {
  description = "The environment name (dev, qa, prod, etc)."
  type        = string
  default     = "dev"
}
variable "vpc_ids" {
  description = "VPC IDs for the environment."
  type        = map(string)
  default = {
    "dev"  = "vpc-XXXXXXXXX"
    "qa"   = "vpc-XXXXXXXXX"
    "prod" = "vpc-XXXXXXXXX"
  }
}
variable "public_subnet_ids" {
  description = "Public subnets for the environment."
  type        = map(list(string))
  default = {
    "dev"  = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]
    "qa"   = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]
    "prod" = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]
  }
}
variable "private_subnet_ids" {
  description = "Private subnets for the environment."
  type        = map(list(string))
  default = {
    "dev"  = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]
    "qa"   = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]
    "prod" = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]
  }
}
variable "vpn_private_cidr_blocks" {
  default     = ["10.0.0.0/8"]
  description = "VPN CIDR blocks that need access to resources"
  type        = list(string)
}
