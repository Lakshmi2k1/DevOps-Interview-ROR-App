# Private S3 bucket for Active Storage. App pods reach it through an IRSA
# role instead of access keys.

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "media" {
  bucket        = "${local.name}-media-${random_id.bucket_suffix.hex}"
  force_destroy = true
  tags          = merge(local.tags, { Name = "${local.name}-media" })
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Scoped to just this bucket.
data "aws_iam_policy_document" "app_s3" {
  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [aws_s3_bucket.media.arn]
  }

  statement {
    sid    = "ObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.media.arn}/*"]
  }
}

resource "aws_iam_policy" "app_s3" {
  name        = "${local.name}-app-s3"
  description = "Access to the ${aws_s3_bucket.media.id} bucket for the ROR app"
  policy      = data.aws_iam_policy_document.app_s3.json
  tags        = local.tags
}

module "app_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name = "${local.name}-app-s3"

  role_policy_arns = {
    s3 = aws_iam_policy.app_s3.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.app_namespace}:${var.app_service_account}"]
    }
  }

  tags = local.tags
}
