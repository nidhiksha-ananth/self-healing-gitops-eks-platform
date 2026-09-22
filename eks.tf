# Community EKS module — same reasoning as the VPC module: it correctly
# wires up the IAM roles, OIDC provider (needed later for IRSA), security
# groups, and node group launch templates, which is a LOT to get right
# by hand.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Public endpoint so you can run kubectl from your laptop without a VPN/
  # bastion. Fine for a portfolio project; in real prod this is usually
  # private-only or IP-restricted.
  cluster_endpoint_public_access = true

  # This creates the IAM OIDC provider automatically — required later
  # (Day 3+) for IRSA (IAM Roles for Service Accounts), which the spec
  # calls out under Security Practices.
  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size
    }
  }

  # Gives your own IAM identity (the one running terraform apply) cluster-admin
  # access via EKS access entries, so kubectl works immediately after apply.
  enable_cluster_creator_admin_permissions = true

  tags = {
    Project = var.project_name
  }
}
