# 会社の AWS 向け。中身は local と同じ app_stack、違うのは provider だけ
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 6.0" }
    random  = { source = "hashicorp/random", version = "~> 3.6" }
    archive = { source = "hashicorp/archive", version = "~> 2.4" }
  }

  # チーム運用するなら state は S3 に置く（バケットは事前に作成）
  # backend "s3" {
  #   bucket       = "your-tfstate-bucket"
  #   key          = "webapp/prod.tfstate"
  #   region       = "ap-northeast-1"
  #   use_lockfile = true
  # }
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
variable "aws_profile" {
  type    = string
  default = "company"
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = var.aws_profile
  default_tags {
    tags = { Project = var.name, ManagedBy = "terraform" }
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
