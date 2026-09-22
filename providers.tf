terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # --- Remote state backend (S3) ---
  # Uncomment this block ONLY after you've manually created the S3 bucket
  # (see README "One-time setup" section). Leave it commented for your
  # very first `terraform init` so you don't get a chicken-and-egg error.
  #
  # backend "s3" {
  #   bucket = "CHANGE-ME-your-unique-tf-state-bucket"
  #   key    = "gitops-eks-platform/terraform.tfstate"
  #   region = "ap-south-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
