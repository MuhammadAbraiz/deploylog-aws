locals {
  region_account = "${var.region}:${local.account_id}"
  app_table_arn  = "arn:aws:dynamodb:${local.region_account}:table/deploylog-deployments"
  lambda_arn     = "arn:aws:lambda:${local.region_account}:function:deploylog-*"
  lambda_role    = "arn:aws:iam::${local.account_id}:role/deploylog-lambda-*"
  log_group_arn  = "arn:aws:logs:${local.region_account}:log-group:/aws/lambda/deploylog-*"
}

# Ceiling for any role the pipeline creates. Even if the deploy role is
# misused, a Lambda role it makes can never do more than this.
data "aws_iam_policy_document" "lambda_boundary" {
  statement {
    sid       = "AppTable"
    actions   = ["dynamodb:PutItem", "dynamodb:Query"]
    resources = [local.app_table_arn]
  }

  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${local.log_group_arn}:*"]
  }
}

resource "aws_iam_policy" "lambda_boundary" {
  name        = "deploylog-lambda-boundary"
  description = "Permissions boundary for Lambda roles created by the pipeline"
  policy      = data.aws_iam_policy_document.lambda_boundary.json
}
