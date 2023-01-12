module "access_logs_bucket" {
  source          = "../cloudfront_access_logs_bucket"
  environment     = var.environment
  expiration_days = 180
}

module "default_waf" {
  source            = "../waf"
  log_group_suffix  = "default-${var.environment}"
  prefix            = "${var.environment}-default-"
  per_ip_rate_limit = var.waf_per_ip_rate_limit
}

module "delta_website_waf" {
  source            = "../waf"
  prefix            = "${var.environment}-delta-website-"
  log_group_suffix  = "delta-website-${var.environment}"
  per_ip_rate_limit = var.waf_per_ip_rate_limit
  # Orbeon triggers this rule
  excluded_rules = ["CrossSiteScripting_BODY"]
}

module "cpm_waf" {
  source            = "../waf"
  prefix            = "${var.environment}-cpm-"
  log_group_suffix  = "cpm-${var.environment}"
  per_ip_rate_limit = var.waf_per_ip_rate_limit
  # At least some e-claims POST requests trigger this rule
  excluded_rules = ["CrossSiteScripting_BODY"]
  ip_allowlist   = var.enable_ip_allowlists ? local.cpm_ip_allowlist : null
}

module "api_auth_waf" {
  source            = "../waf"
  prefix            = "${var.environment}-delta-api-"
  log_group_suffix  = "delta-api-${var.environment}"
  per_ip_rate_limit = var.waf_per_ip_rate_limit
  # XSS not issue for API
  excluded_rules = ["CrossSiteScripting_BODY", "CrossSiteScripting_COOKIE", "CrossSiteScripting_QUERYARGUMENTS", "CrossSiteScripting_URIPATH"]
  ip_allowlist   = var.enable_ip_allowlists ? local.delta_api_allowlist : null
}

module "delta_cloudfront" {
  source                         = "../cloudfront_distribution"
  prefix                         = "delta-${var.environment}-"
  access_logs_bucket_domain_name = module.access_logs_bucket.bucket_domain_name
  access_logs_prefix             = "delta"
  waf_acl_arn                    = module.delta_website_waf.acl_arn
  cloudfront_key                 = var.delta.alb.cloudfront_key
  origin_domain                  = var.delta.alb.dns_name
  cloudfront_domain              = var.delta.domain
  geo_restriction_enabled        = var.delta.disable_geo_restriction != true
}

module "api_cloudfront" {
  source                         = "../cloudfront_distribution"
  prefix                         = "delta-api-${var.environment}-"
  access_logs_bucket_domain_name = module.access_logs_bucket.bucket_domain_name
  access_logs_prefix             = "delta-api"
  waf_acl_arn                    = module.api_auth_waf.acl_arn
  cloudfront_key                 = var.api.alb.cloudfront_key
  cloudfront_domain              = var.api.domain
  is_ipv6_enabled                = !var.enable_ip_allowlists
  geo_restriction_enabled        = var.api.disable_geo_restriction != true
  origins = [
    {
      origin_domain = var.api.alb.dns_name
      path          = "rest-api/*"
    },
    {
      origin_domain = module.swagger_bucket.bucket_domain_name
      path          = "" # TODO DT-131 what paths did we want here
    }
  ]
  cloudfront_domain = var.api.domain
}

module "keycloak_cloudfront" {
  source                         = "../cloudfront_distribution"
  prefix                         = "keycloak-${var.environment}-"
  access_logs_bucket_domain_name = module.access_logs_bucket.bucket_domain_name
  access_logs_prefix             = "keycloak"
  waf_acl_arn                    = module.api_auth_waf.acl_arn
  cloudfront_key                 = var.keycloak.alb.cloudfront_key
  origin_domain                  = var.keycloak.alb.dns_name
  cloudfront_domain              = var.keycloak.domain
  is_ipv6_enabled                = !var.enable_ip_allowlists
  geo_restriction_enabled        = var.keycloak.disable_geo_restriction != true
}

module "cpm_cloudfront" {
  source                         = "../cloudfront_distribution"
  prefix                         = "cpm-${var.environment}-"
  access_logs_bucket_domain_name = module.access_logs_bucket.bucket_domain_name
  access_logs_prefix             = "cpm"
  waf_acl_arn                    = module.cpm_waf.acl_arn
  cloudfront_key                 = var.cpm.alb.cloudfront_key
  origin_domain                  = var.cpm.alb.dns_name
  cloudfront_domain              = var.cpm.domain
  is_ipv6_enabled                = !var.enable_ip_allowlists
  geo_restriction_enabled        = var.cpm.disable_geo_restriction != true
}

module "jaspersoft_cloudfront" {
  source                         = "../cloudfront_distribution"
  prefix                         = "jaspersoft-${var.environment}-"
  access_logs_bucket_domain_name = module.access_logs_bucket.bucket_domain_name
  access_logs_prefix             = "jaspersoft"
  waf_acl_arn                    = module.default_waf.acl_arn
  cloudfront_key                 = var.jaspersoft.alb.cloudfront_key
  origin_domain                  = var.jaspersoft.alb.dns_name
  cloudfront_domain              = var.jaspersoft.domain
  geo_restriction_enabled        = var.jaspersoft.disable_geo_restriction != true
}

module "swagger_bucket" {
  source = "../s3_bucket"

  bucket_name                        = "dluhc-delta-api-swagger-${var.environment}"
  access_log_bucket_name             = "dluhc-delta-api-swagger-access-logs-${var.environment}"
  force_destroy                      = true # TODO DT-131 what do we think of this, it's from backup_buckets.tf

  # TODO DT-131 these two are not found in the dap_export_s3.tf bucket, do we need them here? guessing no
  kms_key_arn                        = aws_kms_key.ml_backup_bucket_key.arn
  noncurrent_version_expiration_days = 60
}
