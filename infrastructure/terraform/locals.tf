locals {
  name = "${var.name_prefix}-${var.environment}"

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  tags = {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
    Assignment  = "mallow-devops-task"
  }
}
