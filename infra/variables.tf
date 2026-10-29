variable "region" {
  type    = string
  default = "ap-southeast-3"
}

variable "github_subject_prefix" {
  description = "OIDC subject prefix of the GitHub repo allowed to assume the deploy roles. This repo uses immutable subject claims (owner and repo IDs); see: gh api repos/<owner>/<repo>/actions/oidc/customization/sub"
  type        = string
  default     = "repo:gitsubhanichwan@179078035/claude-sandbox-healthapi@1438479873"
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
