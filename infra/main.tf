# ---------- shared: ECR + GitHub OIDC ----------

resource "aws_ecr_repository" "app" {
  name                 = "healthapi"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# ---------- per environment ----------

module "staging" {
  source = "./modules/environment"
  providers = {
    aws = aws.staging
  }

  environment       = "staging"
  region            = var.region
  github_repo       = var.github_repo
  oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
  ecr_repository    = aws_ecr_repository.app
  image_tag         = var.image_tag
  app_version       = var.app_versions["staging"]
}

module "production" {
  source = "./modules/environment"
  providers = {
    aws = aws.production
  }

  environment       = "production"
  region            = var.region
  github_repo       = var.github_repo
  oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
  ecr_repository    = aws_ecr_repository.app
  image_tag         = var.image_tag
  app_version       = var.app_versions["production"]
}
