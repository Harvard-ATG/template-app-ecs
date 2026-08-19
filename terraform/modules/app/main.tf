locals {
  region            = data.aws_region.current.name
  account           = data.aws_caller_identity.current.account_id
  env               = var.env
  app_name          = var.app_name
  app_name_short    = var.app_name_short
  cluster_name      = var.cluster_name
  image_api         = var.image_api
  image_web         = var.image_web
  exposed_port_api  = 8000
  exposed_port_web  = 3000
  task_cpu          = var.task_cpu
  task_memory       = var.task_memory
  task_count        = var.task_count
  load_balancer     = var.load_balancer
  tags              = module.constants.default_tags
  route53_zone_name = var.route53_zone_name != "" ? var.route53_zone_name : module.constants.default_route53_zone
  domain_name       = var.domain_name != "" ? var.domain_name : "${var.app_name}.${local.route53_zone_name}"
  # SSM parameters are stored at /{env}/{app_name}-api/* to match IAM policy from ecs-app module
  ssm_root          = "arn:aws:ssm:${local.region}:${local.account}:parameter/${local.env}/${local.app_name}-api"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "network_data" {
  source = "../vendor/network-data"
  env    = var.env
}

module "constants" {
  source  = "../vendor/constants"
  env     = var.env
  product = var.app_name
}

## ---- API SERVICE ----

module "ecs_app_api" {
  source         = "../vendor/ecs-app"
  env            = local.env
  app_name       = "${local.app_name}-api"
  app_name_short = "${local.app_name_short}-api"
  domain_names   = []  # Disable module's ALB rule creation - we'll create custom rules below
  cluster_name   = local.cluster_name
  task_count     = local.task_count
  task_cpu       = local.task_cpu
  task_memory    = local.task_memory
  containers = [
    {
      name      = "api"
      image     = local.image_api
      essential = true
      linuxParameters = {
        initProcessEnabled = true
      }
      portMappings = [{
        containerPort = local.exposed_port_api
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

  # Disable Splunk logging - use CloudWatch Logs instead (configured in container logConfiguration above)
  splunk_enabled = false
  tags = local.tags
}

## ---- FRONTEND SERVICE ----

module "ecs_app_web" {
  source         = "../vendor/ecs-app"
  env            = local.env
  app_name       = "${local.app_name}-web"
  app_name_short = "${local.app_name_short}-web"
  domain_names   = []  # Disable module's ALB rule creation - we'll create custom rules below
  cluster_name   = local.cluster_name
  task_count     = local.task_count
  task_cpu       = local.task_cpu
  task_memory    = local.task_memory
  containers = [
    {
      name      = "web"
      image     = local.image_web
      essential = true
      linuxParameters = {
        initProcessEnabled = true
      }
      portMappings = [{
        containerPort = local.exposed_port_web
      }]
      environment = [
        { "name" : "NODE_ENV", "value" : "production" },
        { "name" : "API_BASE_URL", "value" : "https://${local.domain_name}" },
        { "name" : "NEXT_PUBLIC_API_URL", "value" : "https://${local.domain_name}" },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${local.app_name}-web-${local.env}"
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
    health_check_path    = "/"
    health_check_matcher = "200"
    path_patterns        = ["/*"]
    priority             = 200  # Lower priority than API (higher number = lower priority)
  }

  # Disable Splunk logging - use CloudWatch Logs instead
  splunk_enabled = false
  tags = local.tags
}

## ---- CUSTOM ALB LISTENER RULES ----
# Create path-based routing rules manually since the ecs-app module doesn't
# properly handle path_patterns when multiple services share the same domain

# Data sources to get the target groups created by the ecs-app modules
data "aws_lb_target_group" "api" {
  name = "atg-${local.app_name_short}-api-${local.env}-ecs-tg"
  
  depends_on = [module.ecs_app_api]
}

data "aws_lb_target_group" "web" {
  name = "atg-${local.app_name_short}-web-${local.env}-ecs-tg"
  
  depends_on = [module.ecs_app_web]
}

# API Rule: Match /api/* paths
resource "aws_lb_listener_rule" "api" {
  listener_arn = local.load_balancer.https_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = data.aws_lb_target_group.api.arn
  }

  condition {
    host_header {
      values = [local.domain_name]
    }
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  tags = local.tags
}

# Web Rule: Match /* paths (catch-all)
resource "aws_lb_listener_rule" "web" {
  listener_arn = local.load_balancer.https_listener_arn
  priority     = 200  # Lower priority than API (higher number = evaluated later)

  action {
    type             = "forward"
    target_group_arn = data.aws_lb_target_group.web.arn
  }

  condition {
    host_header {
      values = [local.domain_name]
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = local.tags
}

## ---- ROUTE53 DNS ----

module "route53" {
  source               = "../vendor/route53"
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
      image     = local.image_api
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
