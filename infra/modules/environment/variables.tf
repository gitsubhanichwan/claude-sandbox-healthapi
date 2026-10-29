variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "ecr_repository" {
  description = "The shared ECR repository resource."
  type = object({
    arn            = string
    repository_url = string
  })
}

variable "image_tag" {
  type = string
}

variable "app_version" {
  type = string
}

variable "cpu" {
  type    = string
  default = "256"
}

variable "memory" {
  type    = string
  default = "512"
}
