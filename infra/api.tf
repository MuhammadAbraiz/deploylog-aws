resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

# Anyone can read the log
resource "aws_apigatewayv2_route" "list" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /deployments"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Only signed requests (the pipeline's role) can write to it
resource "aws_apigatewayv2_route" "create" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "POST /deployments"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "AWS_IAM"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 10
    throttling_rate_limit  = 5
  }
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowHttpApi"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*/deployments"
}
