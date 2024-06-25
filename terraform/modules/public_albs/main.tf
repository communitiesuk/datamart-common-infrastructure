# All public ALBs.
# We need to give DLUHC the CloudFront distributions to create DNS records, and CloudFront distributions need an origin,
# so we have these as a separate module and then each app can define its own listeners and targets.

# These are sent by CloudFront in the X-Cloudfront-Key header and verified by the ALB listeners
resource "random_password" "cloudfront_keys" {
  for_each = toset(["delta", "api", "auth", "cpm", "jaspersoft"])
  length   = 24
  special  = false
}

moved {
  from = random_password.cloudfront_keys["keycloak"]
  to   = random_password.cloudfront_keys["auth"]
}

module "delta_alb" {
  source = "../public_alb"

  vpc                    = var.vpc
  subnet_ids             = var.subnet_ids
  prefix                 = "${var.environment}-delta-site-"
  s3_log_expiration_days = var.alb_s3_log_expiration_days
  apply_aws_shield       = var.apply_aws_shield_to_delta_alb
}

output "delta" {
  value = {
    arn               = module.delta_alb.arn
    arn_suffix        = module.delta_alb.arn_suffix
    dns_name          = module.delta_alb.dns_name
    security_group_id = module.delta_alb.security_group_id
    cloudfront_key    = random_password.cloudfront_keys["delta"].result
    certificate_arn   = var.certificates["delta"].arn
    primary_hostname  = var.certificates["delta"].primary_domain
  }
}

module "delta_api_alb" {
  source = "../public_alb"

  vpc                    = var.vpc
  subnet_ids             = var.subnet_ids
  prefix                 = "${var.environment}-delta-api-"
  s3_log_expiration_days = var.alb_s3_log_expiration_days
}

output "delta_api" {
  value = {
    arn               = module.delta_api_alb.arn
    arn_suffix        = module.delta_api_alb.arn_suffix
    dns_name          = module.delta_api_alb.dns_name
    security_group_id = module.delta_api_alb.security_group_id
    cloudfront_key    = random_password.cloudfront_keys["api"].result
    certificate_arn   = var.certificates["api"].arn
    primary_hostname  = var.certificates["api"].primary_domain
  }
}

module "auth_alb" {
  source = "../public_alb"

  vpc                    = var.vpc
  subnet_ids             = var.subnet_ids
  prefix                 = "${var.environment}-keycloak-"
  s3_log_expiration_days = var.alb_s3_log_expiration_days
}

moved {
  from = module.keycloak_alb
  to   = module.auth_alb
}

output "auth" {
  value = {
    arn               = module.auth_alb.arn
    arn_suffix        = module.auth_alb.arn_suffix
    dns_name          = module.auth_alb.dns_name
    security_group_id = module.auth_alb.security_group_id
    cloudfront_key    = random_password.cloudfront_keys["auth"].result
    certificate_arn   = var.certificates["keycloak"].arn
    primary_hostname  = var.certificates["keycloak"].primary_domain
    listener_arn      = aws_lb_listener.auth.arn
  }
}

module "cpm_alb" {
  source = "../public_alb"

  vpc                    = var.vpc
  subnet_ids             = var.subnet_ids
  prefix                 = "${var.environment}-cpm-"
  s3_log_expiration_days = var.alb_s3_log_expiration_days
}

output "cpm" {
  value = {
    arn               = module.cpm_alb.arn
    arn_suffix        = module.cpm_alb.arn_suffix
    dns_name          = module.cpm_alb.dns_name
    security_group_id = module.cpm_alb.security_group_id
    cloudfront_key    = random_password.cloudfront_keys["cpm"].result
    certificate_arn   = var.certificates["cpm"].arn
    primary_hostname  = var.certificates["cpm"].primary_domain
  }
}
