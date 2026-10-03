# local / prod 共通の構成。環境差分は envs/* の provider と変数だけにする
variable "name" { type = string }
variable "enable_serverless" {
  type    = bool
  default = true
}
variable "enable_container" {
  type    = bool
  default = true
}
# Lambda の言語: python / node / go（apps/ 配下のサンプルに対応）
variable "lambda_lang" {
  type    = string
  default = "python"
}
variable "container_port" {
  type    = number
  default = 8080
}
variable "container_image_tag" {
  type    = string
  default = "latest"
}
variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

locals {
  apps_dir = abspath("${path.module}/../../../apps")
  lambda_langs = {
    python = { dir = "${local.apps_dir}/lambda-python", runtime = "python3.12", handler = "handler.handler" }
    node   = { dir = "${local.apps_dir}/lambda-node", runtime = "nodejs20.x", handler = "index.handler" }
    go     = { dir = "${local.apps_dir}/lambda-go/dist", runtime = "provided.al2023", handler = "bootstrap" }
  }
  lambda = local.lambda_langs[var.lambda_lang]
  app_env = {
    DB_SECRET_ARN = module.base.db_secret_arn
    DB_HOST       = module.base.db_address
    DB_PORT       = tostring(module.base.db_port)
    DB_NAME       = module.base.db_name
    ASSETS_BUCKET = module.base.assets_bucket
  }
}

module "base" {
  source            = "../base"
  name              = var.name
  db_instance_class = var.db_instance_class
}

module "serverless" {
  count       = var.enable_serverless ? 1 : 0
  source      = "../serverless"
  name        = var.name
  source_dir  = local.lambda.dir
  runtime     = local.lambda.runtime
  handler     = local.lambda.handler
  environment = local.app_env
  secret_arns = [module.base.db_secret_arn]
}

module "container" {
  count          = var.enable_container ? 1 : 0
  source         = "../container"
  name           = var.name
  vpc_id         = module.base.vpc_id
  vpc_cidr       = module.base.vpc_cidr
  subnet_ids     = module.base.public_subnet_ids
  container_port = var.container_port
  image_tag      = var.container_image_tag
  environment    = merge(local.app_env, { PORT = tostring(var.container_port) })
  secret_arns    = [module.base.db_secret_arn]
}

output "db_address" { value = module.base.db_address }
output "db_port" { value = module.base.db_port }
output "db_secret_arn" { value = module.base.db_secret_arn }
output "assets_bucket" { value = module.base.assets_bucket }
output "api_id" { value = try(module.serverless[0].api_id, null) }
output "api_endpoint" { value = try(module.serverless[0].api_endpoint, null) }
output "ecr_repository_url" { value = try(module.container[0].ecr_repository_url, null) }
output "alb_name" { value = try(module.container[0].alb_name, null) }
output "alb_dns_name" { value = try(module.container[0].alb_dns_name, null) }
