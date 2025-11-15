# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-11-14

### Added
- New `need_logging` variable to enable/disable API Gateway logging (default: `false`)
- New `cloudwatch_role_arn` variable to specify external CloudWatch IAM role ARN for logging
- Dynamic `access_log_settings` block in API Gateway stage that activates only when `need_logging = true`
- Validation rule for `cloudwatch_role_arn` to ensure it's provided when logging is enabled

### Changed
- **BREAKING**: IAM role and policy creation for CloudWatch logging removed from module
- **BREAKING**: Users must now provide their own CloudWatch IAM role ARN via `cloudwatch_role_arn` variable when enabling logging
- API Gateway account settings (`aws_api_gateway_account`) now uses externally provided IAM role instead of creating one

### Improved
- Resolved account-level resource conflicts when multiple module instances are deployed in the same AWS account
- Prevented unnecessary Terraform updates on `aws_api_gateway_account` resource
- Made logging configuration fully optional to reduce costs when logging is not needed

### Migration Guide
If you're upgrading from v1.0.x and using logging:

1. Create a shared IAM role for API Gateway CloudWatch logging in your root module or separate shared resources:
   ```hcl
   resource "aws_iam_role" "api_gateway_cloudwatch" {
     name = "api-gateway-cloudwatch-global-role"
     assume_role_policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{
         Action = "sts:AssumeRole"
         Effect = "Allow"
         Principal = {
           Service = "apigateway.amazonaws.com"
         }
       }]
     })
   }

   resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
     name = "api-gateway-cloudwatch-policy"
     role = aws_iam_role.api_gateway_cloudwatch.id
     policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{
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
       }]
     })
   }
   ```

2. Update your module calls to pass the role ARN:
   ```hcl
   module "api_proxy" {
     source              = "cloudpediaai/restapi-proxy/aws"
     version             = "1.1.0"
     need_logging        = true
     cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
     # ... other variables
   }
   ```

## [1.0.0] - Initial Release

### Added
- Initial module release with API Gateway REST API proxy functionality
- Support for custom domain names with ACM certificates
- CORS configuration
- CloudWatch logging support
- Route53 DNS integration
- HTTP proxy integration with backend endpoints
