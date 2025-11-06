terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.19.0"
      configuration_aliases = [aws.us-east-1, aws]
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "default" {}

locals {
  dummy = true
}
