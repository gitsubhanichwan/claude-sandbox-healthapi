variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "github_subject_prefix" {
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

variable "infrastructure_role_arn" {
  description = "Shared ECS infrastructure role. One role for all services keeps them eligible to share an Express Mode ALB."
  type        = string
}

variable "max_task_count" {
  type    = number
  default = 1
}

variable "cpu" {
  type    = string
  default = "256"
}

variable "memory" {
  type    = string
  default = "512"
}
