# We use the official community VPC module instead of hand-rolling every
# subnet/route-table resource. This is standard practice in real teams —
# be ready to explain WHY: it's battle-tested, handles edge cases (AZ
# failure, tagging for EKS/ALB auto-discovery) that are easy to get wrong
# by hand, and is faster to review in a PR than 300 lines of raw resources.

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i)]
  public_subnets  = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i + 100)]

  # Worker nodes live in private subnets; only the ALB/NAT touch the
  # public subnets. This mirrors the "Reason" in the project spec: EKS
  # worker nodes stay private, load balancer is internet-facing.
  enable_nat_gateway = true
  single_nat_gateway = true # cost control: 1 NAT gateway instead of 1-per-AZ
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Required tags so EKS and the AWS Load Balancer Controller can
  # auto-discover these subnets for internal/internet-facing load balancers.
  public_subnet_tags = {
    "kubernetes.io/role/elb"                     = "1"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"            = "1"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
  }
}
