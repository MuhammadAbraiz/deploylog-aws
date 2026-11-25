# What the pipeline may touch: its own state, and resources named deploylog-*.
data "aws_iam_policy_document" "deploy" {
  statement {
    sid       = "StateBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "StateObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/infra/*"]
  }

  statement {
    sid       = "StateLock"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
    resources = [aws_dynamodb_table.lock.arn]
  }

  statement {
    sid       = "AppTable"
    actions   = ["dynamodb:*"]
    resources = [local.app_table_arn]
  }

  statement {
    sid       = "Lambda"
    actions   = ["lambda:*"]
    resources = [local.lambda_arn, "${local.lambda_arn}:*"]
  }

  statement {
    sid = "LogGroups"
    actions = [
      "logs:CreateLogGroup", "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy", "logs:DeleteRetentionPolicy",
      "logs:TagResource", "logs:UntagResource", "logs:ListTagsForResource",
    ]
    resources = [local.log_group_arn, "${local.log_group_arn}:*"]
  }

  statement {
    sid       = "DescribeLogGroups"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }

  statement {
    sid = "HttpApi"
    actions = [
      "apigateway:GET", "apigateway:POST", "apigateway:PUT",
      "apigateway:PATCH", "apigateway:DELETE",
      "apigateway:TagResource", "apigateway:UntagResource",
    ]
    resources = [
      "arn:aws:apigateway:${var.region}::/apis",
      "arn:aws:apigateway:${var.region}::/apis/*",
      "arn:aws:apigateway:${var.region}::/tags/*",
    ]
  }

  # Lambda roles can only be created or given policies with the boundary attached.
  statement {
    sid = "LambdaRoleWithBoundary"
    actions = [
      "iam:CreateRole", "iam:PutRolePolicy", "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy",
    ]
    resources = [local.lambda_role]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [aws_iam_policy.lambda_boundary.arn]
    }
  }

  statement {
    sid = "LambdaRoleRead"
    actions = [
      "iam:GetRole", "iam:DeleteRole", "iam:TagRole", "iam:UntagRole",
      "iam:GetRolePolicy", "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole", "iam:UpdateAssumeRolePolicy",
    ]
    resources = [local.lambda_role]
  }

  statement {
    sid       = "PassLambdaRole"
    actions   = ["iam:PassRole"]
    resources = [local.lambda_role]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }

  statement {
    sid       = "RecordDeployment"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${local.region_account}:*/*/POST/deployments"]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "deploy"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}
