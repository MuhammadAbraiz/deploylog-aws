output "api_url" {
  description = "Base URL of the DeployLog API"
  value       = trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")
}
