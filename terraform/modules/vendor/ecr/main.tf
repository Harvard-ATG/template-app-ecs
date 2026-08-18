locals {
  repository_name       = "${var.department}/${var.repository_name}"
  image_tag_mutability  = var.image_tag_mutability
  scan_on_push          = var.scan_on_push
  tags                  = var.tags
  expiration_after_days = var.expiration_after_days
  force_delete          = var.force_delete
}

resource "aws_ecr_repository" "default" {
  name                 = local.repository_name
  image_tag_mutability = local.image_tag_mutability
  image_scanning_configuration {
    scan_on_push = local.scan_on_push
  }
  force_delete = local.force_delete
  tags         = local.tags
}

resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  count      = local.expiration_after_days > 0 ? 1 : 0
  repository = aws_ecr_repository.default.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire images older than ${local.expiration_after_days} days"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = local.expiration_after_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_repository_policy" "cross_account_policy" {
  count      = length(var.cross_account_ids) > 0 ? 1 : 0
  repository = aws_ecr_repository.default.name
  policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Sid    = "AllowCrossAccountAccess",
        Effect = "Allow",
        Principal = {
          AWS = formatlist("arn:aws:iam::%s:root", var.cross_account_ids)
        },
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:ListImages"
        ]
      }
    ]
  })
}
