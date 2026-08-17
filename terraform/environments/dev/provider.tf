provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      terraform   = "true"
      environment = var.env
      application = var.app_name
    }
  }
}
