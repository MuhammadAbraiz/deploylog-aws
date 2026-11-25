output "deploy_role_arn" {
  description = "Set as the AWS_ROLE_ARN secret in GitHub"
  value       = aws_iam_role.deploy.arn
}

output "state_bucket" {
  description = "Set as the TF_STATE_BUCKET variable in GitHub"
  value       = aws_s3_bucket.state.bucket
}

output "lock_table" {
  description = "Set as the TF_LOCK_TABLE variable in GitHub"
  value       = aws_dynamodb_table.lock.name
}
