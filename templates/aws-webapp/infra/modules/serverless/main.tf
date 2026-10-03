# サーバーレス: API Gateway (HTTP API) + Lambda
# 言語は runtime / handler / source_dir で切り替える（Python / Node.js / Go など）
variable "name" { type = string }
variable "source_dir" { type = string }
variable "runtime" { type = string }
variable "handler" { type = string }
variable "environment" {
  type    = map(string)
  default = {}
}
variable "secret_arns" {
  type    = list(string)
  default = []
}
variable "timeout" {
  type    = number
  default = 10
}
variable "memory_size" {
  type    = number
  default = 256
}

data "archive_file" "code" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/.build/${var.name}-lambda.zip"
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "secrets" {
  count = length(var.secret_arns) > 0 ? 1 : 0
  name  = "read-secrets"
  role  = aws_iam_role.lambda.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = ["secretsmanager:GetSecretValue"], Resource = var.secret_arns }]
  })
}

resource "aws_lambda_function" "this" {
  function_name    = "${var.name}-api"
  role             = aws_iam_role.lambda.arn
  runtime          = var.runtime
  handler          = var.handler
  filename         = data.archive_file.code.output_path
  source_code_hash = data.archive_file.code.output_base64sha256
  timeout          = var.timeout
  memory_size      = var.memory_size
  environment { variables = var.environment }
}

resource "aws_apigatewayv2_api" "this" {
  name          = "${var.name}-http"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.this.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

output "api_id" { value = aws_apigatewayv2_api.this.id }
output "api_endpoint" { value = aws_apigatewayv2_api.this.api_endpoint }
output "function_name" { value = aws_lambda_function.this.function_name }
