# Create CloudWatch log group for API Gateway
resource "aws_cloudwatch_log_group" "restapi_proxy_log_group" {
  count = var.need_logging ? 1 : 0

  name = "/aws/apigateway/${var.api_name}-api-logs"

  retention_in_days = 30
  tags              = var.tags
}

# Create IAM role for API Gateway CloudWatch logging
resource "aws_iam_role" "restapi_proxy_cloudwatch" {
  name = "${var.api_name}-api-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  depends_on = [aws_cloudwatch_log_group.restapi_proxy_log_group]

  tags = var.tags
}

# Attach CloudWatch logging policy to the role
resource "aws_iam_role_policy" "restapi_proxy_cloudwatch" {
  name = "${var.api_name}-api-cloudwatch-policy"
  role = aws_iam_role.restapi_proxy_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })

  depends_on = [aws_iam_role.restapi_proxy_cloudwatch]

}

# Create account-level settings for API Gateway
resource "aws_api_gateway_account" "restapi_proxy_logging" {
  count = var.need_logging ? 1 : 0

  cloudwatch_role_arn = aws_iam_role.restapi_proxy_cloudwatch.arn

  depends_on = [aws_iam_role.restapi_proxy_cloudwatch]
}
