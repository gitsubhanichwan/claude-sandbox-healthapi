variable "region" {
  type    = string
  default = "ap-southeast-3"
}

variable "github_repo" {
  description = "GitHub repository (owner/name) allowed to assume the deploy roles."
  type        = string
  default     = "gitsubhanichwan/claude-sandbox-healthapi"
}

variable "image_tag" {
  description = "Image tag used when a service is first created. Later deploys are done by CI and ignored by Terraform."
  type        = string
  default     = "bootstrap"
}

variable "app_versions" {
  description = "Initial APP_VERSION per environment."
  type        = map(string)
  default = {
    staging    = "staging"
    production = "production"
  }
}
