data "aws_route53_zone" "harnessio-fed" {
  name = "harnessio-fed.com"
}

resource "aws_acm_certificate" "riley-sa_harnessio-fed" {
  domain_name       = "*.riley-sa.${data.aws_route53_zone.harnessio-fed.name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_route53_record" "riley-sa_harnessio-fed" {
#   for_each = {
#     for dvo in aws_acm_certificate.riley-sa_harnessio-fed.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.harnessio-fed.zone_id
# }

# resource "aws_acm_certificate_validation" "riley-sa_harnessio-fed" {
#   certificate_arn         = aws_acm_certificate.riley-sa_harnessio-fed.arn
#   validation_record_fqdns = [for record in aws_route53_record.riley-sa_harnessio-fed : record.fqdn]
# }
