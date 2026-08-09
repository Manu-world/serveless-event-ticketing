variable "prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "lambda_invoke_arns" {
  type = map(string)
}

variable "cloudfront_domain_name" {
  type = string
}

variable "lambda_function_names" {
  type = map(string)
}

variable "authorizer_function_name" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "throttling_burst_limit" {
  type    = number
  default = 100
}

variable "throttling_rate_limit" {
  type    = number
  default = 50
}
