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

module "ecr_api" {
  source          = "../../modules/vendor/ecr"
  repository_name = "${local.app_name}-api"
}

module "ecr_web" {
  source          = "../../modules/vendor/ecr"
  repository_name = "${local.app_name}-web"
}

## ---- APPLICATION MODULE ----
# Note: Must be created before RDS/ElastiCache modules so security group exists

module "template_app" {
  source       = "../../modules/app"
  env          = local.env
  app_name     = local.app_name
  cluster_name = data.terraform_remote_state.shared.outputs.ecs_cluster_name
  image_api    = "${module.ecr_api.repository_url}:${local.image_tag}"
  image_web    = "${module.ecr_web.repository_url}:${local.image_tag}"
  task_count   = local.task_count
  task_cpu     = "512"
  task_memory  = "1024"
  
  # Database and Redis endpoints will be provided by modules below
  database_endpoint = module.rds.endpoint
  database_name     = var.database_name
  database_username = var.database_username
  
  # Redis is optional - uncomment the module below to enable
  # redis_endpoint = module.elasticache.endpoint
  redis_endpoint = ""  # No Redis - sessions stored in PostgreSQL
  
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
  
  # Production-specific settings
  backup_retention_days = 30
  multi_az              = true
  skip_final_snapshot   = false
  deletion_protection   = true
  performance_insights_enabled = true
  
  # Allow ECS tasks to connect
  allowed_security_group_id = module.template_app.ecs_security_group_id
}

## ---- ELASTICACHE REDIS (OPTIONAL) ----
# Redis is DISABLED by default - sessions are stored in PostgreSQL
# Uncomment the module below to enable Redis for caching/sessions

# module "elasticache" {
#   source = "../../modules/elasticache"
#   
#   env      = local.env
#   app_name = local.app_name
#   
#   # Instance sizing
#   node_type       = var.redis_node_type
#   num_cache_nodes = 1
#   
#   # Production-specific settings
#   snapshot_retention_limit = 7
#   
#   # Allow ECS tasks to connect
#   allowed_security_group_id = module.template_app.ecs_security_group_id
# }
