# Create API Gateway REST API
resource "aws_api_gateway_rest_api" "restapi_proxy" {
  name = var.api_name

  endpoint_configuration {
    types = ["EDGE"]
  }

  binary_media_types = var.binary_media_types

  tags = var.tags
}

# Create proxy resource that matches all paths
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.restapi_proxy.id
  parent_id   = aws_api_gateway_rest_api.restapi_proxy.root_resource_id
  path_part   = "{proxy+}"
}

# Create ANY method to catch all HTTP methods
resource "aws_api_gateway_method" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.restapi_proxy.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = "ANY"

  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# Create integration with the EC2 instance
resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.restapi_proxy.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "${var.http_endpoint}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  connection_type = "INTERNET"
}

# Add method response for proxy
resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.restapi_proxy.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }

  depends_on = [aws_api_gateway_method.proxy]
}

# Add integration response for proxy
resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.restapi_proxy.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"      = var.cors_allowed_origins,
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }

  depends_on = [aws_api_gateway_method_response.proxy]
}

# Create root path resource
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id = aws_api_gateway_rest_api.restapi_proxy.id
  resource_id = aws_api_gateway_rest_api.restapi_proxy.root_resource_id
  http_method = "ANY"

  authorization = "NONE"
}

# Create root path integration
resource "aws_api_gateway_integration" "proxy_root" {
  rest_api_id = aws_api_gateway_rest_api.restapi_proxy.id
  resource_id = aws_api_gateway_rest_api.restapi_proxy.root_resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  # Use Elastic IP instead of public DNS to maintain consistent endpoint
  uri = "${var.http_endpoint}/"

  connection_type = "INTERNET"
}

# Enable CORS
resource "aws_api_gateway_method" "options" {
  rest_api_id = aws_api_gateway_rest_api.restapi_proxy.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = "OPTIONS"

  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  rest_api_id = aws_api_gateway_rest_api.restapi_proxy.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options.http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.restapi_proxy.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.restapi_proxy.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods"     = "'GET,POST,PUT,DELETE,OPTIONS,PATCH'",
    "method.response.header.Access-Control-Allow-Origin"      = var.cors_allowed_origins,
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }
}

# Create API Gateway deployment
resource "aws_api_gateway_deployment" "restapi_proxy" {
  rest_api_id = aws_api_gateway_rest_api.restapi_proxy.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.restapi_proxy,
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_integration.proxy.id,
      aws_api_gateway_integration.proxy.uri,
      aws_api_gateway_integration.options.id,
      aws_api_gateway_method.proxy_root.id,
      aws_api_gateway_integration.proxy_root.id,
      aws_api_gateway_integration.proxy_root.uri,
      aws_api_gateway_method.options.id,
      aws_api_gateway_integration_response.proxy.id,
      aws_api_gateway_integration_response.options.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create API Gateway stage
resource "aws_api_gateway_stage" "restapi_proxy" {
  deployment_id = aws_api_gateway_deployment.restapi_proxy.id
  rest_api_id   = aws_api_gateway_rest_api.restapi_proxy.id
  stage_name    = "${terraform.workspace}_${var.api_version}"

  dynamic "access_log_settings" {
    for_each = var.need_logging ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.restapi_proxy_log_group[0].arn
      format = jsonencode({
        requestId      = "$context.requestId"
        ip             = "$context.identity.sourceIp"
        requestTime    = "$context.requestTime"
        httpMethod     = "$context.httpMethod"
        resourcePath   = "$context.resourcePath"
        proxyPath      = "$util.escapeJavaScript($context.identity.sourceIp)"
        status         = "$context.status"
        protocol       = "$context.protocol"
        responseLength = "$context.responseLength"
        userAgent      = "$context.identity.userAgent"
        path           = "$context.path"
        request = {
          proxy       = "$util.escapeJavaScript($input.params('proxy'))"
          querystring = "$util.escapeJavaScript($input.json('$.querystring'))"
          path        = "$context.path"
          headers     = "$util.escapeJavaScript($input.json('$.header'))"
        }
      })
    }
  }

  tags = var.tags

  #   depends_on = [aws_cloudwatch_log_group.api_gateway]
}

# Add CloudWatch logging
resource "aws_api_gateway_method_settings" "restapi_proxy" {
  count = var.need_logging ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.restapi_proxy.id
  stage_name  = aws_api_gateway_stage.restapi_proxy.stage_name
  method_path = "*/*"

  depends_on = [aws_api_gateway_account.restapi_proxy_logging[0]]

  settings {
    metrics_enabled    = true
    logging_level      = var.logging_level
    data_trace_enabled = true
    # detailed_metrics_enabled = true
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
}
