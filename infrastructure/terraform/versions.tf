terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Bucket must exist before `terraform init` - see infrastructure/README.md.
  # Native S3 locking (no DynamoDB table) needs Terraform >= 1.10.
  backend "s3" {
    bucket       = "mallow-ror-tfstate-874456855739"
    key          = "mallow-ror/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
