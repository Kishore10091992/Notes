#creating route53 record in already created route53
#Integrating load balancer with route53 record

data "aws_lb" "nlb" {
  arn = <nlb_arn>
}
 
resource "aws_route53_record" "create_method" {
  zone_id = <route53_hosted_zone_id>
  name    = ""
  type    = "A"
 
  alias {
    name                   = data.aws_lb.nlb.dns_name
    zone_id                = data.aws_lb.nlb.zone_id
    evaluate_target_health = true
  }
}