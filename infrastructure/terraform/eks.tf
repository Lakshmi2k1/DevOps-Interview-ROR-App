# EKS cluster with worker nodes in private subnets. IRSA is enabled so pods
# can assume IAM roles (S3 access, ALB controller) without static credentials.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = "${local.name}-eks"
  cluster_version = var.cluster_version

  # Needed so kubectl/Terraform can reach the API server; nodes stay private.
  cluster_endpoint_public_access = true

  # Lets Terraform manage cluster resources (the ALB controller helm release)
  # right after creation.
  enable_cluster_creator_admin_permissions = true

  enable_irsa = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  eks_managed_node_group_defaults = {
    subnet_ids = module.vpc.private_subnets
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      labels = {
        role = "app"
      }
    }
  }

  tags = local.tags
}
