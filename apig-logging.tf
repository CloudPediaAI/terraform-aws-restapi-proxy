# Create CloudWatch log group for API Gateway
resource "aws_cloudwatch_log_group" "restapi_proxy_log_group" {
  count = var.need_logging ? 1 : 0

  name = "/aws/apigateway/${var.api_name}-api-logs"

  retention_in_days = 30
  tags              = var.tags
}

# Create account-level settings for API Gateway
resource "aws_api_gateway_account" "restapi_proxy_logging" {
  count = var.need_logging ? 1 : 0

  cloudwatch_role_arn = var.cloudwatch_role_arn
}
