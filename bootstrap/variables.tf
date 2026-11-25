variable "region" {
  description = "AWS region for everything in this project"
  type        = string
  default     = "us-east-1"
}

variable "github_repo" {
  description = "GitHub repo allowed to deploy, as owner/name"
  type        = string
  default     = "MuhammadAbraiz/deploylog-aws"
}

variable "create_oidc_provider" {
  description = "Set to false if the account already has the GitHub OIDC provider"
  type        = bool
  default     = false
}

# GitHub puts numeric IDs in the OIDC sub claim, e.g.
# repo:owner@123/name@456:ref:refs/heads/main
# IDs never change, so a deleted and recreated repo with the same name can't deploy.
variable "github_owner_id" {
  description = "Numeric ID of the repo owner (GitHub API: /users/<owner>)"
  type        = string
  default     = "98274826"
}

variable "github_repo_id" {
  description = "Numeric ID of the repo (GitHub API: /repos/<owner>/<name>)"
  type        = string
  default     = "1471642139"
}
