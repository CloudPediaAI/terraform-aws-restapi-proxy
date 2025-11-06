output "api_url" {
  value       = (local.need_custom_domain) ? "https://${aws_api_gateway_domain_name.restapi_proxy[0].domain_name}/${var.api_version}" : aws_api_gateway_stage.restapi_proxy.invoke_url
  description = "URL of the REST API created by this module"
}
