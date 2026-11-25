variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Prefix for every resource. The deploy role only allows deploylog-*"
  type        = string
  default     = "deploylog"
}
