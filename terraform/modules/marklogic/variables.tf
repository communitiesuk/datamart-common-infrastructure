variable "default_tags" {
  type        = map(string)
  description = "Tags to use for each resource"
}

variable "environment" {
  description = "test, staging or production"
  type        = string
}

variable "vpc" {
  description = "The main VPC"
}

variable "instance_type" {
  description = "EC2 instance type for MarkLogic"
  default     = "r5.4xlarge"
}

variable "private_subnets" {
  description = "Three private subnets"
}

variable "private_dns" {
  type = object({
    zone_id     = string
    base_domain = string
  })
}

variable "data_volume_size_gb" {
  description = "Size in GB of the data EBS volume for each instace"
  default     = 20
}

variable "ebs_backup_error_notification_emails" {
  type = list(string)
}

variable "patch_maintenance_window" {
  type = object({
    window_id            = string
    service_role_arn     = string
    errors_sns_topic_arn = string
  })
}

variable "kms_key_arn" {
  type = string
}