locals {
  need_custom_domain = (var.hosted_zone_id != null && var.hosted_zone_id != "" && var.domain_name != null && var.domain_name != "")
}

resource "aws_acm_certificate" "restapi_proxy" {
  count = local.need_custom_domain ? 1 : 0

  provider          = aws.us-east-1
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # Encode then Decode Validation options to avoid conditional for_each
  domain_validations_str = jsonencode((local.need_custom_domain) ? aws_acm_certificate.restapi_proxy[0].domain_validation_options : [
    {
      domain_name           = "dummy"
      resource_record_name  = "dummy"
      resource_record_type  = "CNAME"
      resource_record_value = "dummy"
    },
  ])
  domain_validations = jsondecode(local.domain_validations_str)
  # use first item for validations
  domain_validation = local.domain_validations[0]
}

resource "aws_route53_record" "restapi_proxy_root_validation" {
  depends_on = [aws_acm_certificate.restapi_proxy]

  count = (local.need_custom_domain) ? 1 : 0

  zone_id         = var.hosted_zone_id
  ttl             = 60
  allow_overwrite = true
  name            = local.domain_validation.resource_record_name
  records         = [local.domain_validation.resource_record_value]
  type            = local.domain_validation.resource_record_type
}

# resource "aws_route53_record" "restapi_proxy_root_validation" {
#   count = local.need_custom_domain ? 1 : 0

#   for_each = {
#     for dvo in aws_acm_certificate.restapi_proxy[0].domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = var.hosted_zone_id
# }

resource "aws_acm_certificate_validation" "restapi_proxy" {
  count = local.need_custom_domain ? 1 : 0

  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.restapi_proxy[0].arn
  validation_record_fqdns = [for record in aws_route53_record.restapi_proxy_root_validation : record.fqdn]
}

# Create API Gateway Custom Domain
resource "aws_api_gateway_domain_name" "restapi_proxy" {
  count = local.need_custom_domain ? 1 : 0

  domain_name     = var.domain_name
  certificate_arn = aws_acm_certificate.restapi_proxy[0].arn

  depends_on = [aws_acm_certificate_validation.restapi_proxy]

  tags = var.tags
}

# Create base path mapping
resource "aws_api_gateway_base_path_mapping" "restapi_proxy" {
  count = local.need_custom_domain ? 1 : 0

  api_id      = aws_api_gateway_rest_api.restapi_proxy.id
  stage_name  = aws_api_gateway_stage.restapi_proxy.stage_name
  domain_name = aws_api_gateway_domain_name.restapi_proxy[0].domain_name
  base_path   = var.api_version
}

# Create DNS record for the API Gateway domain
resource "aws_route53_record" "restapi_proxy" {
  count = local.need_custom_domain ? 1 : 0

  # provider = aws.us-east-1
  name    = aws_api_gateway_domain_name.restapi_proxy[0].domain_name
  type    = "A"
  zone_id = var.hosted_zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.restapi_proxy[0].cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.restapi_proxy[0].cloudfront_zone_id
  }
}

# Output the custom domain URL
# output "api_custom_domain" {
#   value = "https://${aws_api_gateway_domain_name.restapi_proxy.domain_name}"
# }
