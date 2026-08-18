locals {
  route_53_record_name = var.route_53_record_name
  route_53_zone_name   = var.route_53_zone_name
  lb_dns_name          = var.lb_dns_name
  lb_zone_id           = var.lb_zone_id
}

data "aws_route53_zone" "public" {
  name         = "${local.route_53_zone_name}."
  private_zone = false
}

resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = local.route_53_record_name
  type    = "A"

  alias {
    name                   = local.lb_dns_name
    zone_id                = local.lb_zone_id
    evaluate_target_health = true
  }
}
