terraform {
  required_version = "~> 1.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.98.0"
    }
  }
  backend "s3" {
    bucket = "atg-tf-remote-state"
    key    = "appserver/prod/template-app-ecs/terraform.tfstate"
    region = "us-east-1"
  }
}
