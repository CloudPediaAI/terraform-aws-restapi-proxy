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
  description = "Hosted zone ID for the Route53 DNS"
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
  description = "Enable or disable logging"
  type = bool
  default = false
}
