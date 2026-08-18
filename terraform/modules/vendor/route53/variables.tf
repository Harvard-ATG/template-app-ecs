variable "route_53_record_name" {
  type        = string
  description = "The record name for the Route53 record (e.g. catchpy)"
}
variable "route_53_zone_name" {
  type        = string
  description = "The zone domain name for the Route53 record (e.g. dev.example.com)"
}
variable "lb_dns_name" {
  type        = string
  description = "The DNS name of the load balancer"
}
variable "lb_zone_id" {
  type        = string
  description = "The zone ID of the load balancer"
}
