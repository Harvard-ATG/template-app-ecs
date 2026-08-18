# Vendored Modules Configuration Guide

## ⚠️ REQUIRED: Update Network Configuration

The vendored modules contain placeholder values that **MUST be updated** with your AWS infrastructure details before use.

## Files to Configure

### 1. `network-data/variables.tf`

Update with your actual AWS VPC and subnet IDs:

```terraform
variable "vpc_ids" {
  default = {
    "dev"  = "vpc-XXXXXXXXX"  # ← Replace with your dev VPC ID
    "qa"   = "vpc-XXXXXXXXX"  # ← Replace with your QA VPC ID
    "prod" = "vpc-XXXXXXXXX"  # ← Replace with your prod VPC ID
  }
}

variable "public_subnet_ids" {
  default = {
    "dev"  = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]  # ← Replace
    "qa"   = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]  # ← Replace
    "prod" = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]  # ← Replace
  }
}

variable "private_subnet_ids" {
  default = {
    "dev"  = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]  # ← Replace
    "qa"   = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]  # ← Replace
    "prod" = ["subnet-XXXXXXXXX", "subnet-XXXXXXXXX"]  # ← Replace
  }
}

variable "vpn_private_cidr_blocks" {
  default = ["10.0.0.0/8"]  # ← Replace with your VPN CIDR blocks
}
```

### 2. `constants/main.tf`

Update with your organization's domain:

```terraform
# Line 7: Replace "example.com" with your actual domain
default_route53_zone = var.env != "prod" ? "${var.env}.example.com" : "example.com"
```

## How to Find Your AWS Values

##***REMOVED***
```bash
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table
```

### Subnet IDs
```bash
# Public subnets (typically in public route tables)
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-YOUR_VPC_ID" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Look for subnets tagged as "public" or check route tables for internet gateway
```

### VPN CIDR Blocks
Check with your network team for the CIDR blocks used by your organization's VPN.

## Alternative: Use Terraform Data Sources

Instead of hardcoding values, you can use data sources to dynamically lookup resources:

```terraform
# Example: Look up VPC by tags
data "aws_vpc" "main" {
  tags = {
    Name        = "my-vpc-${var.env}"
    Environment = var.env
  }
}

# Example: Look up subnets by VPC and tags
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  tags = {
    Type = "private"
  }
}
```

## Security Note

**Never commit real AWS IDs to public repositories.** If you're using this template:
- Keep the repository private, OR
- Use environment-specific `terraform.tfvars` files (gitignored)
- Use AWS Secrets Manager / Parameter Store for sensitive values
