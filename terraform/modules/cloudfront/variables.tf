variable "prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "public_alb_subnets" {
  type = list(object({ id = string, cidr_block = string }))
}

variable "alb_log_expiration_days" {
  type    = number
  default = 180
}

variable "cloudfront_access_log_expiration_days" {
  type    = number
  default = 180
}

variable "cloudfront_domain" {
  type = object({
    aliases             = list(string),
    acm_certificate_arn = string
  })
}
