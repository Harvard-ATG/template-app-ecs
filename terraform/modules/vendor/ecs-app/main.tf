data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_default_tags" "current" {}

locals {
  # Account and region information
  account        = data.aws_caller_identity.current.account_id
  region         = data.aws_region.current.name
  env            = var.env
  department     = var.department
  app_name       = var.app_name
  app_name_short = var.app_name_short

  # Service/Task configuration
  resource_prefix        = "${local.department}-${local.app_name}-${local.env}"
  resource_prefix_short  = "${local.department}-${local.app_name_short}-${local.env}" # atg-diglatin-dev
  cluster_name           = var.cluster_name
  domain_names           = var.domain_names
  fargate_version        = var.fargate_version
  task_count             = var.task_count
  task_cpu               = var.task_cpu
  task_memory            = var.task_memory
  splunk_enabled         = var.splunk_enabled
  splunk_url             = var.splunk_url
  splunk_index           = var.splunk_index
  splunk_sourcetype      = var.splunk_sourcetype
  enable_execute_command = var.enable_execute_command
  tags                   = var.tags

  # See https://docs.docker.com/engine/logging/log_tags/
  docker_labels = {
    environment = local.env,
    department  = local.department,
    product     = local.app_name,
  }

  # See https://docs.docker.com/engine/logging/drivers/awslogs/
  cloudwatch_log_driver = {
    "logDriver" : "awslogs",
    "options" : {
      "awslogs-create-group" : "true",
      "awslogs-region" : local.region,
      "awslogs-group" : "/ecs/${local.department}-${local.app_name}-${local.env}",
      "awslogs-stream-prefix" : "ecs",
    }
    "secretOptions" : null
  }
  # See https://docs.docker.com/engine/logging/drivers/splunk/
  splunk_log_driver = {
    "logDriver" : "splunk",
    "options" : {
      "splunk-url" : local.splunk_url,
      "splunk-source" : "${local.department}-${local.app_name}",
      "splunk-sourcetype" : local.splunk_sourcetype,
      "splunk-index" : local.splunk_index,
      "splunk-gzip" : "true",
      "tag" : "{{.ImageName}}::{{.Name}}::{{.ID}}",
      "labels" : "department,product,environment"
    },
    "secretOptions" : [{
      "name" : "splunk-token",
      "valueFrom" : local.ssm_param_splunk_token
    }]
  }
  containers = [
    for container in var.containers : merge(container, {
      "logConfiguration" : local.splunk_enabled ? local.splunk_log_driver : local.cloudwatch_log_driver,
      "dockerLabels" : local.docker_labels
    })
  ]
  exposed_port           = var.containers[0].portMappings[0].containerPort
  exposed_container_name = var.containers[0].name


  # Network configuration
  vpc_id              = var.network_config.vpc_id
  private_subnet_ids  = var.network_config.private_subnet_ids
  allowed_cidr_blocks = var.network_config.allowed_cidr_blocks

  # Load balancer configuration
  lb_security_group_id  = var.load_balancer_config.security_group_id
  lb_https_listener_arn = var.load_balancer_config.https_listener_arn
  health_check_path     = var.load_balancer_config.health_check_path
  health_check_matcher  = var.load_balancer_config.health_check_matcher

  # SSM Parameters
  ssm_param_app_path      = "arn:aws:ssm:${local.region}:${local.account}:parameter/${local.env}/${local.app_name}"
  ssm_param_defaults_path = "arn:aws:ssm:${local.region}:${local.account}:parameter/${local.env}/defaults"
  ssm_param_splunk_token  = "${local.ssm_param_defaults_path}/splunk_token"
}

## ---- USERS & ROLES & POLICIES ----
resource "aws_iam_role" "task_role" {
  name = "${local.resource_prefix}-task-role"
  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "task_policy" {
  name   = "${local.resource_prefix}-task-policy"
  role   = aws_iam_role.task_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowECSExec",
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_iam_role" "task_execution_role" {
  name               = "${local.resource_prefix}-task-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.task_execution_role.id
}

resource "aws_iam_role_policy" "task_execution_policy" {
  name = "${local.resource_prefix}-task-execution-policy"
  role = aws_iam_role.task_execution_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudwatchLogsAccess",
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Sid": "SSMParametersAccess",
      "Effect": "Allow",
      "Resource": [
        "${local.ssm_param_app_path}/*",
        "${local.ssm_param_splunk_token}"
      ],
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
    }
  ]
}
EOF

}


## ---- LOAD BALANCER LISTENER RULES & TARGET GROUPS ----
# Upddate count to 1 if domain_names is not empty and skip_host_header_rule is false
# in order to create the host header rule only when needed.
resource "aws_lb_listener_rule" "https_lb_listener_host" {
  count        = length(local.domain_names) > 0 ? 1 : 0
  listener_arn = local.lb_https_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
  condition {
    host_header {
      values = local.domain_names
    }
  }
  tags = {
    Name = "${local.app_name_short}-ecs"
  }
}

resource "aws_lb_target_group" "ecs_tg" {
  name                 = "${local.resource_prefix_short}-ecs-tg"
  port                 = local.exposed_port
  protocol             = "HTTP"
  vpc_id               = local.vpc_id
  target_type          = "ip"
  deregistration_delay = 10
  slow_start           = 30
  health_check {
    path                = local.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 4
    timeout             = 6
    interval            = 30
    matcher             = local.health_check_matcher
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "${local.resource_prefix}-ecs-sg"
  description = "Allow HTTP access"
  vpc_id      = local.vpc_id
  ingress {
    from_port       = local.exposed_port
    to_port         = local.exposed_port
    protocol        = "tcp"
    security_groups = [local.lb_security_group_id]
    description     = "Allow HTTP traffic from the load balancer"
  }
  dynamic "ingress" {
    for_each = length(local.allowed_cidr_blocks) > 0 ? [true] : []
    content {
      from_port   = local.exposed_port
      to_port     = local.exposed_port
      protocol    = "tcp"
      cidr_blocks = local.allowed_cidr_blocks
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## ---- TASK DEFINITION & SERVICE ----
resource "aws_ecs_task_definition" "main" {
  family                   = "${local.resource_prefix}-task-definition"
  container_definitions    = jsonencode(local.containers)
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.task_cpu
  memory                   = local.task_memory
  tags = merge({
    Name = "${local.resource_prefix}-task-definition"
  }, local.tags)
}

resource "aws_ecs_service" "main" {
  name                    = "${local.resource_prefix}-service"
  cluster                 = local.cluster_name
  task_definition         = "${aws_ecs_task_definition.main.family}:${aws_ecs_task_definition.main.revision}"
  desired_count           = local.task_count
  launch_type             = "FARGATE"
  platform_version        = local.fargate_version
  enable_execute_command  = local.enable_execute_command
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"
  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = local.exposed_container_name
    container_port   = local.exposed_port
  }
  depends_on = [
    aws_ecs_task_definition.main,
  ]
  tags = merge({
    Name = "${local.resource_prefix}-service",
  }, local.tags)
}
