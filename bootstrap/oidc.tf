data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  github_host = "token.actions.githubusercontent.com"
  repo_owner  = split("/", var.github_repo)[0]
  repo_name   = split("/", var.github_repo)[1]
  github_sub  = "repo:${local.repo_owner}@${var.github_owner_id}/${local.repo_name}@${var.github_repo_id}:ref:refs/heads/main"
}

# One GitHub OIDC provider per account. Reuse it if it already exists.
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://${local.github_host}"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://${local.github_host}"
}

locals {
  oidc_provider_arn = (var.create_oidc_provider
    ? aws_iam_openid_connect_provider.github[0].arn
    : data.aws_iam_openid_connect_provider.github[0].arn
  )
}

# Only workflows on the main branch of this one repo can assume the role.
data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_host}:sub"
      values   = [local.github_sub]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name                 = "deploylog-github-deploy"
  description          = "Assumed by GitHub Actions on main to deploy DeployLog"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600
}
