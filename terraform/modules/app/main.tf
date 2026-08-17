locals {
  region         = data.aws_region.current.name
  account        = data.aws_caller_identity.current.account_id
  env            = var.env
  app_name       = var.app_name
  app_name_short = var.app_name_short
  cluster_name   = var.cluster_name
  image          = var.image
  exposed_port   = 8000
  task_cpu       = var.task_cpu
  task_memory    = var.task_memory
  task_count     = var.task_count
  load_balancer  = var.load_balancer
  tags           = module.constants.default_tags
  route53_zone_name = var.route53_zone_name != "" ? var.route53_zone_name : module.constants.default_route53_zone
  domain_name    = var.domain_name != "" ? var.domain_name : "${var.app_name}.${local.route53_zone_name}"
  # SSM parameters are stored at /{env}/{app_name}-api/* to match IAM policy from ecs-app module
  ssm_root       = "arn:aws:ssm:${local.region}:${local.account}:parameter/${local.env}/${local.app_name}-api"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "network_data" {
  source = "git::https://github.com/Harvard-ATG/atg-ops-appserver.git//terraform/modules/reusable/network-data?ref=main"
  env    = var.env
}

module "constants" {
  source  = "git::https://github.com/Harvard-ATG/atg-ops-appserver.git//terraform/modules/reusable/constants?ref=main"
  env     = var.env
  product = var.app_name
}

## ---- API SERVICE ----

module "ecs_app_api" {
  source         = "git::https://github.com/Harvard-ATG/atg-ops-appserver.git//terraform/modules/reusable/ecs-app?ref=main"
  env            = local.env
  app_name       = "${local.app_name}-api"
  app_name_short = "${local.app_name_short}-api"
  domain_names   = ["${local.app_name}.${local.route53_zone_name}"]
  cluster_name   = local.cluster_name
  task_count     = local.task_count
  task_cpu       = local.task_cpu
  task_memory    = local.task_memory
  containers = [
    {
      name      = "api"
      image     = local.image
      essential = true
      linuxParameters = {
        initProcessEnabled = true
      }
      portMappings = [{
        containerPort = local.exposed_port
      }]
      environment = concat([
        { "name" : "APP_ENVIRONMENT", "value" : local.env },
        { "name" : "APP_LOG_LEVEL", "value" : "INFO" },
        { "name" : "APP_DATABASE_HOST", "value" : var.database_endpoint },
        { "name" : "APP_DATABASE_NAME", "value" : var.database_name },
        { "name" : "APP_DATABASE_USER", "value" : var.database_username },
        { "name" : "APP_REDIS_PORT", "value" : "6379" },
        { "name" : "APP_ALLOWED_ORIGINS", "value" : "https://${local.domain_name}" },
        { "name" : "APP_COOKIE_SECURE", "value" : "true" },
      ],
      # Only add Redis host if provided (optional)
      var.redis_endpoint != "" ? [
        { "name" : "APP_REDIS_HOST", "value" : var.redis_endpoint }
      ] : []
      )
      secrets = [
        { "name" : "APP_DATABASE_PASSWORD", "valueFrom" : "${local.ssm_root}/database_password" },
        { "name" : "APP_SECRET_KEY", "valueFrom" : "${local.ssm_root}/session_secret" },
        { "name" : "APP_ANTHROPIC_API_KEY", "valueFrom" : "${local.ssm_root}/anthropic_api_key" },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${local.app_name}-api-${local.env}"
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ]
  network_config = {
    vpc_id              = module.network_data.vpc_id
    private_subnet_ids  = module.network_data.private_subnet_ids
    allowed_cidr_blocks = module.network_data.vpn_private_cidr_blocks
  }
  load_balancer_config = {
    security_group_id    = local.load_balancer.security_group_id
    https_listener_arn   = local.load_balancer.https_listener_arn
    health_check_path    = "/api/v1/health"
    health_check_matcher = "200"
    path_patterns        = ["/api/*"]
    priority             = 100
  }

  splunk_sourcetype = "python"
  tags              = local.tags
}

## ---- ROUTE53 DNS ----

module "route53" {
  source               = "git::https://github.com/Harvard-ATG/atg-ops-appserver.git//terraform/modules/reusable/route53?ref=main"
  route_53_record_name = local.domain_name
  route_53_zone_name   = local.route53_zone_name
  lb_dns_name          = local.load_balancer.dns_name
  lb_zone_id           = local.load_balancer.zone_id
}

## ---- MIGRATION TASK DEFINITION ----

# Separate task definition for running database migrations
resource "aws_ecs_task_definition" "migration" {
  family                   = "atg-${local.app_name}-${local.env}-migration"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.task_cpu
  memory                   = local.task_memory
  execution_role_arn       = module.ecs_app_api.task_execution_role_arn
  task_role_arn            = module.ecs_app_api.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "migration"
      image     = local.image
      essential = true
      command   = ["migrate"]
      linuxParameters = {
        initProcessEnabled = true
      }
      environment = [
        { "name" : "APP_DATABASE_HOST", "value" : var.database_endpoint },
        { "name" : "APP_DATABASE_NAME", "value" : var.database_name },
        { "name" : "APP_DATABASE_USER", "value" : var.database_username },
      ]
      secrets = [
        { "name" : "APP_DATABASE_PASSWORD", "valueFrom" : "${local.ssm_root}/database_password" },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${local.app_name}-${local.env}/migration"
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "migration"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])

  tags = local.tags
}
