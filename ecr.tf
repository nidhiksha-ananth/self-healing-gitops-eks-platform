# ECR has no hourly cost — only storage (~$0.10/GB/month) and it's tiny
# for a couple of container images. Unlike the VPC/EKS resources, there's
# no need to destroy this between sessions. Apply it once and leave it.

resource "aws_ecr_repository" "app" {
  name                 = "gitops-eks-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Keep only the last 10 images so storage (and cost) doesn't creep up
# over time as CI runs repeatedly.
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

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

output "ecr_repository_url" {
  description = "Push images here"
  value       = aws_ecr_repository.app.repository_url
}
