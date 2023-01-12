locals {
  cloudfront_key_header = "X-Cloudfront-Key"
}

resource "aws_cloudfront_response_headers_policy" "main" {
  name    = "${var.prefix}cloudfront-policy"
  comment = "Default security headers for responses"

  security_headers_config {
    frame_options {
      frame_option = "SAMEORIGIN"
      override     = false
    }

    referrer_policy {
      referrer_policy = "no-referrer"
      override        = false
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = false
    }
  }

  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      value    = "geolocation=(), interest-cohort=()"
      override = false
    }
  }
}

resource "aws_cloudfront_distribution" "main" {

  aliases = var.cloudfront_domain == null ? [] : var.cloudfront_domain.aliases

  wait_for_deployment = false

  dynamic "origin" {
    for_each = var.origin_domain == null ? [] : [var.origin_domain]

    content {
      domain_name = origin.value
      origin_id   = "primary"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = var.cloudfront_domain == null ? "http-only" : "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
        origin_read_timeout    = 60
      }

      custom_header {
        name  = local.cloudfront_key_header
        value = var.cloudfront_key
      }
    }
  }

  dynamic "origin" {
    for_each = var.origins

    content {
      domain_name = origin.value["origin_domain"]
      origin_id   = origin.value["origin_domain"]

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = var.cloudfront_domain == null ? "http-only" : "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
        origin_read_timeout    = 60
      }

      custom_header {
        name  = local.cloudfront_key_header
        value = var.cloudfront_key
      }
    }
  }

  dynamic "ordered_cache_behaviour" {
    for_each = var.origins

    content {
      target_origin_id = ordered_cache_behaviour.value["origin_domain"]
      path_pattern     = ordered_cache_behaviour.value["path_pattern"]
    }
  }

  enabled         = true
  is_ipv6_enabled = var.is_ipv6_enabled

  default_cache_behavior {
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "primary"

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }

      headers = ["*"]
    }

    viewer_protocol_policy     = "redirect-to-https"
    min_ttl                    = 0
    default_ttl                = 0
    max_ttl                    = 86400
    response_headers_policy_id = aws_cloudfront_response_headers_policy.main.id
  }

  price_class = "PriceClass_100"
  web_acl_id  = var.waf_acl_arn

  logging_config {
    bucket          = var.access_logs_bucket_domain_name
    include_cookies = false
    prefix          = "${var.access_logs_prefix}/"
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_enabled ? "whitelist" : "none"
      locations        = var.geo_restriction_enabled ? ["GB", "IE"] : []
    }
  }

  tags = {
    Name = "${var.prefix}cloudfront"
  }

  viewer_certificate {
    cloudfront_default_certificate = var.cloudfront_domain == null ? true : false
    acm_certificate_arn            = var.cloudfront_domain == null ? null : aws_acm_certificate_validation.cloudfront_domains[0].certificate_arn
    minimum_protocol_version       = var.cloudfront_domain == null ? "TLSv1" : "TLSv1.2_2021"
    ssl_support_method             = var.cloudfront_domain == null ? null : "sni-only"
  }

  # The DNS records we ask DLUHC to create CNAME to these distributions, so we shouldn't delete them
  retain_on_delete = true
  lifecycle {
    prevent_destroy = true
  }
}
