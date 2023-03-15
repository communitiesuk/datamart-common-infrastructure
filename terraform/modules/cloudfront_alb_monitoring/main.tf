# Note that the MarkLogic dashboard is at terraform/modules/marklogic/monitoring_dashboard.tf

module "website_cloudfront_alb_monitoring" {
  source                      = "../cloudfront_alb_monitoring_instance"
  alb_arn_suffix              = var.delta_website.alb_arn_suffix
  cloudfront_distribution_id  = var.delta_website.cloudfront_distribution_id
  instance_metric_namespace   = var.delta_website.instance_metric_namespace
  alarms_sns_topic_arn        = var.alarms_sns_topic_arn
  alarms_sns_topic_global_arn = var.alarms_sns_topic_global_arn
  prefix                      = "delta-website-${var.environment}"
}

module "api_cloudfront_alb_monitoring" {
  source                      = "../cloudfront_alb_monitoring_instance"
  alb_arn_suffix              = var.delta_api.alb_arn_suffix
  cloudfront_distribution_id  = var.delta_api.cloudfront_distribution_id
  instance_metric_namespace   = var.delta_api.instance_metric_namespace
  alarms_sns_topic_arn        = var.alarms_sns_topic_arn
  alarms_sns_topic_global_arn = var.alarms_sns_topic_global_arn
  prefix                      = "delta-api-${var.environment}"
}

module "keycloak_cloudfront_alb_monitoring" {
  source                      = "../cloudfront_alb_monitoring_instance"
  alb_arn_suffix              = var.keycloak.alb_arn_suffix
  cloudfront_distribution_id  = var.keycloak.cloudfront_distribution_id
  instance_metric_namespace   = var.keycloak.instance_metric_namespace
  alarms_sns_topic_arn        = var.alarms_sns_topic_arn
  alarms_sns_topic_global_arn = var.alarms_sns_topic_global_arn
  prefix                      = "keycloak-${var.environment}"
}

module "cpm_cloudfront_alb_monitoring" {
  source                      = "../cloudfront_alb_monitoring_instance"
  alb_arn_suffix              = var.cpm.alb_arn_suffix
  cloudfront_distribution_id  = var.cpm.cloudfront_distribution_id
  instance_metric_namespace   = var.cpm.instance_metric_namespace
  alarms_sns_topic_arn        = var.alarms_sns_topic_arn
  alarms_sns_topic_global_arn = var.alarms_sns_topic_global_arn
  prefix                      = "cpm-${var.environment}"
}

module "jaspersoft_cloudfront_alb_monitoring" {
  source                      = "../cloudfront_alb_monitoring_instance"
  alb_arn_suffix              = var.jaspersoft.alb_arn_suffix
  cloudfront_distribution_id  = var.jaspersoft.cloudfront_distribution_id
  instance_metric_namespace   = var.jaspersoft.instance_metric_namespace
  alarms_sns_topic_arn        = var.alarms_sns_topic_arn
  alarms_sns_topic_global_arn = var.alarms_sns_topic_global_arn
  prefix                      = "jaspersoft-${var.environment}"
}

