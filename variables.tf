variable "api_name" {
  description = "Name of the API"
  type        = string
  default     = "rest-api-proxy"
}

variable "http_endpoint" {
  description = "HTTP endpoint of the backend service"
  type        = string
  default     = null
}

variable "logging_level" {
  description = "Logging level for the API Gateway"
  type        = string
  default     = "ERROR"
}

variable "api_version" {
  description = "Version of the API"
  type        = string
  default     = "v1"
}

variable "domain_name" {
  description = "Custom domain name for the API Gateway"
  type        = string
  default     = null
}

variable "hosted_zone_id" {
  description = "Hosted zone ID for the Route53 DNS.  This is required if domain_name is specified."
  type        = string
  default     = null
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins for the API Gateway"
  type        = string
  default     = "'*'"
}

variable "tags" {
  type        = map(any)
  description = "Key/Value pairs for the tags"
  default = {
    created_by = "Terraform Module cloudpediaai/restapi-proxy/aws"
  }
}

variable "need_logging" {
  description = "API Logging will be ENABLED if true"
  type = bool
  default = false
}

variable "cloudwatch_role_arn" {
  description = "ARN of the CloudWatch role for API Gateway logging"
  type = string
  default = null
  validation {
    condition     = !(var.need_logging) || (var.need_logging && var.cloudwatch_role_arn != null)
    error_message = "cloudwatch_role_arn must be provided if need_logging is set to true."
  }
}