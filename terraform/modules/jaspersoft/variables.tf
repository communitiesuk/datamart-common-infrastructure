variable "prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  type = string
}

variable "vpc" {
  type = object({
    id         = string
    cidr_block = string
  })
}

variable "public_alb" {
  type = object({
    arn               = string
    arn_suffix        = string
    security_group_id = string
    certificate_arn   = string
    cloudfront_key    = string
  })
}

variable "ssh_key_name" {
  type = string
}

variable "private_instance_subnet" {
  type = object({ id = string, cidr_block = string })
}

variable "database_subnets" {
  type = list(object({ id = string, cidr_block = string }))
}

variable "allow_ssh_from_sg_id" {
  description = "This security group will be allowed to connect to the Jasper Server instance on port 22"
  type        = string
}

variable "jaspersoft_binaries_s3_bucket" {
  description = "Existing S3 bucket containing Jaspersoft binaries. See README.md"
  type        = string
}

variable "instance_type" {
  default = "t3a.medium"
  type    = string
}

variable "java_max_heap" {
  description = "Maximum memory allocated to tomcat on the Jaspersoft instance (the -Xmx JAVA_OPTS flag)"
  default     = "4096m"
  type        = string
}

variable "private_dns" {
  type = object({
    zone_id     = string
    base_domain = string
  })
}

variable "ad_domain" {
  default = "dluhcdata"
}

variable "patch_maintenance_window" {
  type = object({
    window_id            = string
    service_role_arn     = string
    errors_sns_topic_arn = string
  })
}

variable "extra_instance_policy_arn" {
  type        = string
  description = "ARN of IAM policy to give instance necessary permissions for access via Session Manager"
}

variable "patch_cloudwatch_log_expiration_days" {
  type = number
}

variable "config_s3_log_expiration_days" {
  type = number
}

variable "app_cloudwatch_log_expiration_days" {
  type = number
}

variable "alarms_sns_topic_arn" {
  description = "SNS topic ARN to send alarm notifications to"
  type        = string
}

variable "ebs_backup_error_notification_emails" {
  type = list(string)
}
