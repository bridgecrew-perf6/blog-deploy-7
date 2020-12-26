data "aws_route53_zone" "public" {
  name = var.domain_name
}

resource "aws_route53_record" "blog" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "blog.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [var.blog_eip_address]
}
