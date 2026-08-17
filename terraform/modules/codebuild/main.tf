data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  region       = data.aws_region.current.name
  ecr_registry = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com"
  project_name = "atg-${var.app_name}-${var.env}"
}

# CodeBuild Project
resource "aws_codebuild_project" "main" {
  name          = "${local.project_name}-image-build"
  description   = "Builds Docker images for ${var.app_name} ${var.env} environment"
  build_timeout = var.build_timeout
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "GIT_REPO"
      value = var.git_repo
    }

    environment_variable {
      name  = "GIT_VERSION"
      value = var.git_version
    }

    environment_variable {
      name  = "ECR_REGISTRY"
      value = local.ecr_registry
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URL"
      value = var.ecr_repository_url
    }

    environment_variable {
      name  = "DOCKERFILE_PATH"
      value = var.dockerfile_path
    }

    environment_variable {
      name  = "BUILD_SSH_KEY_SSM_PATH"
      value = var.build_ssh_key_ssm_path
    }
  }

  source {
    type            = "GITHUB"
    location        = var.git_repo
    git_clone_depth = 1
    buildspec       = var.buildspec_path
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${local.project_name}-image-build"
      stream_name = "build-log"
    }
  }
}

# GitHub Webhook for automatic builds
resource "aws_codebuild_webhook" "main" {
  project_name = aws_codebuild_project.main.name

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "^refs/heads/${var.git_version}$"
    }
  }
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild" {
  name = "${local.project_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for CodeBuild
resource "aws_iam_role_policy" "codebuild" {
  name = "${local.project_name}-codebuild-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/codebuild/${local.project_name}-image-build",
          "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/codebuild/${local.project_name}-image-build:*"
        ]
      },
      {
        Sid    = "SSMParameterAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = [
          "arn:aws:ssm:${local.region}:${local.account_id}:parameter${var.build_ssh_key_ssm_path}"
        ]
      }
    ]
  })
}
