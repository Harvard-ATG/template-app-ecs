locals {
  region     = data.aws_region.current.name
  env        = var.env
  app_name   = var.app_name
  image_tag  = var.image_tag
  task_count = var.task_count
}

data "aws_region" "current" {}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "atg-tf-remote-state"
    key    = "appserver/${local.env}/shared/terraform.tfstate"
    region = local.region
  }
}

module "ecr" {
  source          = "git::https://github.com/Harvard-ATG/atg-ops-appserver.git//terraform/modules/reusable/ecr?ref=main"
  repository_name = local.app_name
}

module "codebuild" {
  source = "../../modules/codebuild"
  
  env                    = local.env
  app_name               = local.app_name
  git_repo               = "git@github.com:Harvard-ATG/template-app-ecs.git"  # Update with your actual repo URL
  git_version            = "main"
  ecr_repository_url     = module.ecr.repository_url
  dockerfile_path        = "packages/api/Dockerfile"
  buildspec_path         = "buildspec.yml"
  build_ssh_key_ssm_path = "/${local.env}/${local.app_name}/build_ssh_key"
}

## ---- APPLICATION MODULE ----
# Note: Must be created before RDS/ElastiCache modules so security group exists

module "template_app" {
  source       = "../../modules/app"
  env          = local.env
  app_name     = local.app_name
  cluster_name = data.terraform_remote_state.shared.outputs.ecs_cluster_name
  image        = "${module.ecr.repository_url}:${local.image_tag}"
  task_count   = local.task_count
  
  # Database and Redis endpoints will be provided by modules below
  database_endpoint = module.rds.endpoint
  database_name     = var.database_name
  database_username = var.database_username
  
  # Redis is optional - comment out the next line to disable ElastiCache
  redis_endpoint = module.elasticache.endpoint
  # redis_endpoint = ""  # Uncomment this and comment line above to disable Redis
  
  load_balancer = {
    security_group_id  = data.terraform_remote_state.shared.outputs.lb_sg_id
    https_listener_arn = data.terraform_remote_state.shared.outputs.lb_https_listener_arn
    dns_name           = data.terraform_remote_state.shared.outputs.lb_dns_name
    zone_id            = data.terraform_remote_state.shared.outputs.lb_zone_id
  }
}

## ---- RDS DATABASE ----

module "rds" {
  source = "../../modules/rds"
  
  env      = local.env
  app_name = local.app_name
  
  # Database configuration
  database_name     = var.database_name
  master_username   = var.database_username
  
  # Instance sizing (can be upgraded later without data loss)
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  
  # Dev-specific settings
  backup_retention_days = 7
  multi_az              = false
  skip_final_snapshot   = true
  deletion_protection   = false
  
  # Allow ECS tasks to connect
  allowed_security_group_id = module.template_app.ecs_security_group_id
}

## ---- ELASTICACHE REDIS (OPTIONAL) ----
# Comment out this entire module block to disable Redis

module "elasticache" {
  source = "../../modules/elasticache"
  
  env      = local.env
  app_name = local.app_name
  
  # Instance sizing
  node_type       = var.redis_node_type
  num_cache_nodes = 1
  
  # Dev-specific settings
  snapshot_retention_limit = 5
  
  # Allow ECS tasks to connect
  allowed_security_group_id = module.template_app.ecs_security_group_id
}
