# Public subnets hold only the ALB and NAT gateway. EKS nodes and RDS sit in
# private subnets with no direct route to the internet.

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 8)]

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags required by the AWS Load Balancer Controller for subnet discovery.
  public_subnet_tags = {
    "kubernetes.io/role/elb"                  = "1"
    "kubernetes.io/cluster/${local.name}-eks" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"         = "1"
    "kubernetes.io/cluster/${local.name}-eks" = "shared"
  }

  tags = local.tags
}

# Route private-subnet S3 traffic over the AWS backbone without NAT.
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = module.vpc.private_route_table_ids

  tags = merge(local.tags, { Name = "${local.name}-s3-gateway-endpoint" })
}
