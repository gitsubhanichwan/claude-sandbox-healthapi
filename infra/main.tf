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

# Express Mode places services with the same networking in one ALB. A single
# infrastructure role (immutable per service) removes any doubt about sharing.
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "infrastructure" {
  name               = "healthapi-infrastructure"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "infrastructure" {
  role       = aws_iam_role.infrastructure.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleforExpressGatewayServices"
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

  infrastructure_role_arn = aws_iam_role.infrastructure.arn
  max_task_count          = 1

  depends_on = [aws_iam_role_policy_attachment.infrastructure]
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

  infrastructure_role_arn = aws_iam_role.infrastructure.arn
  max_task_count          = 1

  depends_on = [aws_iam_role_policy_attachment.infrastructure]
}
