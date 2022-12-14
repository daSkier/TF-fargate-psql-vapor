# domain management
data "aws_route53_zone" "hosted_zone" {
  name         = var.hosted_zone_name
  private_zone = false
}

resource "aws_route53_record" "subdomain" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "${var.environment_name}.${var.hosted_zone_name}"
  type    = "A"
  # ttl     = "60" # 60 is the default/required value for alias records

  alias {
    name                   = aws_lb.vapor_server_alb.dns_name
    zone_id                = aws_lb.vapor_server_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "new_vapor_cert" {
  domain_name       = "${var.environment_name}.${var.hosted_zone_name}"
  validation_method = "DNS"

  tags = {
    Environment = "${var.environment_name}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validations" {
  for_each = {
    for dvo in aws_acm_certificate.new_vapor_cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.hosted_zone.zone_id
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.new_vapor_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validations : record.fqdn]
}

