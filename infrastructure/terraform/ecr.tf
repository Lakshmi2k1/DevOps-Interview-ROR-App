# One repo each for the rails and nginx images. Scan on push, keep only the
# last 10 tags per repo so they don't grow unbounded.

locals {
  ecr_repositories = {
    rails = "${local.name}/rails_app"
    nginx = "${local.name}/nginx"
  }
}

resource "aws_ecr_repository" "this" {
  for_each = local.ecr_repositories

  name                 = each.value
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
