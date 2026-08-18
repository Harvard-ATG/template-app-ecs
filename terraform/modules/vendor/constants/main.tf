locals {
  # Resource prefix to create unique resource names across different environments
  resource_prefix = "${var.department}-${var.product}-${var.env}"

  # Default Route53 zone name based on environment
  # REQUIRED: Update with your organization's domain structure
  # Example: "example.com" for production, "<env>.example.com" for non-production
  default_route53_zone = var.env != "prod" ? "${var.env}.example.com" : "example.com"

  # Default AWS region for resources
  default_region = "us-east-1"

  # Default tags applied to all resources
  # These tags are used for cost allocation, management, and identification
  # They should be consistent across all resources in the environment
  default_tags = merge(
    {
      environment = var.env
      department  = var.department
      product     = var.product
      data_class  = var.data_class
      hosted_by   = var.hosted_by
      criticality = var.criticality
      managed_by  = "terraform"
    }
  )
}
