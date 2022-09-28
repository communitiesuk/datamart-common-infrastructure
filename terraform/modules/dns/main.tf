# Temporarily removed from terraform state so it doesn't get destroyed
# resource "aws_route53_delegation_set" "main" {
#   reference_name = "${var.prefix}main"
# }

data "aws_route53_delegation_set" "main" {
  id = "N00840011JQMVT3XEAYQT"
}

resource "aws_route53_zone" "delegated_zone" {
  name              = var.delegated_domain
  delegation_set_id = data.aws_route53_delegation_set.main.id
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cloudfront_domains_wildcard" {
  provider = aws.us-east-1

  domain_name               = "*.${var.primary_domain}"
  subject_alternative_names = ["*.${var.primary_domain}", "*.${var.delegated_domain}"]
  validation_method         = "DNS"
}

# In practice both of these lists should have length one
locals {
  delegated_validations     = [for v in aws_acm_certificate.cloudfront_domains_wildcard.domain_validation_options : v if v.domain_name == "*.${var.delegated_domain}"]
  non_delegated_validations = [for v in aws_acm_certificate.cloudfront_domains_wildcard.domain_validation_options : v if v.domain_name != "*.${var.delegated_domain}"]
}

resource "aws_route53_record" "delgated_validation_records" {
  for_each = {
    for dvo in local.delegated_validations : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.delegated_zone.zone_id
}
