output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "environments" {
  description = "Per-environment service endpoint, deploy role, cluster and service."
  value = {
    staging    = module.staging.summary
    production = module.production.summary
  }
}
