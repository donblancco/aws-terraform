# CloudFront 用 ACM を発行するためのプロバイダ（us-east-1）
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_acm_certificate" "cert" {
  provider                  = aws.use1
  domain_name               = var.domain_name
  subject_alternative_names = var.certificate_subject_alternative_names
  validation_method         = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.use1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# CloudFront Alias レコードの作成

resource "aws_route53_record" "alias_root" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alias_www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.alternate_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}