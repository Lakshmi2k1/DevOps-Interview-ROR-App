###############################################################################
# Input variables
###############################################################################

variable "region" {
  description = "AWS region to deploy all resources into."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix applied to the names of all created resources."
  type        = string
  default     = "mallow-ror"
}

variable "environment" {
  description = "Environment name used for tagging (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread the subnets across."
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (cheaper) instead of one per AZ."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# EKS
# ---------------------------------------------------------------------------
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.30"
}

variable "node_instance_types" {
  description = "Instance types for the EKS managed node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes (headroom for scaling)."
  type        = number
  default     = 3
}

# ---------------------------------------------------------------------------
# RDS (PostgreSQL)
# ---------------------------------------------------------------------------
variable "db_engine_version" {
  description = "PostgreSQL engine version for RDS."
  type        = string
  default     = "13.23"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage (GiB) for the RDS instance."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name (maps to RDS_DB_NAME env var)."
  type        = string
  default     = "rails"
}

variable "db_username" {
  description = "Master username for RDS (maps to RDS_USERNAME env var)."
  type        = string
  default     = "postgres"
}

variable "db_port" {
  description = "Port PostgreSQL listens on (maps to RDS_PORT env var)."
  type        = number
  default     = 5432
}

# ---------------------------------------------------------------------------
# Application / Kubernetes
# ---------------------------------------------------------------------------
variable "app_namespace" {
  description = "Kubernetes namespace the application runs in."
  type        = string
  default     = "ror-app"
}

variable "app_service_account" {
  description = "Kubernetes service account name used by the app pods (bound to the S3 IAM role via IRSA). Must match the serviceAccount.name used by the Helm chart."
  type        = string
  default     = "ror-app"
}

# ---------------------------------------------------------------------------
# CI / GitHub Actions OIDC
# ---------------------------------------------------------------------------
variable "enable_github_oidc" {
  description = "Create a GitHub OIDC provider + IAM role that GitHub Actions can assume to push images to ECR (keyless CI)."
  type        = bool
  default     = true
}

variable "github_repo" {
  description = "GitHub repository (owner/name) allowed to assume the CI role, e.g. Lakshmi2k1/DevOps-Interview-ROR-App."
  type        = string
  default     = "Lakshmi2k1/DevOps-Interview-ROR-App"
}
