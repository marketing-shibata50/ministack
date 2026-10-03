# MK2 上の MiniStack 向け。`terraform apply` しても会社の AWS には一切触れない
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 6.0" }
    random  = { source = "hashicorp/random", version = "~> 3.6" }
    archive = { source = "hashicorp/archive", version = "~> 2.4" }
  }
}

variable "name" {
  type    = string
  default = "webapp"
}
variable "lambda_lang" {
  type    = string
  default = "python"
}
variable "enable_serverless" {
  type    = bool
  default = true
}
variable "enable_container" {
  type    = bool
  default = true
}
variable "ministack_endpoint" {
  type    = string
  default = "http://localhost:4566"
}

provider "aws" {
  region                      = "ap-northeast-1"
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = var.ministack_endpoint
    apigatewayv2   = var.ministack_endpoint
    cloudwatch     = var.ministack_endpoint
    cognitoidp     = var.ministack_endpoint
    dynamodb       = var.ministack_endpoint
    ec2            = var.ministack_endpoint
    ecr            = var.ministack_endpoint
    ecs            = var.ministack_endpoint
    elbv2          = var.ministack_endpoint
    events         = var.ministack_endpoint
    iam            = var.ministack_endpoint
    lambda         = var.ministack_endpoint
    logs           = var.ministack_endpoint
    rds            = var.ministack_endpoint
    s3             = var.ministack_endpoint
    secretsmanager = var.ministack_endpoint
    ses            = var.ministack_endpoint
    sns            = var.ministack_endpoint
    sqs            = var.ministack_endpoint
    ssm            = var.ministack_endpoint
    sts            = var.ministack_endpoint
  }
}

module "app" {
  source            = "../../modules/app_stack"
  name              = var.name
  lambda_lang       = var.lambda_lang
  enable_serverless = var.enable_serverless
  enable_container  = var.enable_container
}

output "app" { value = module.app }
