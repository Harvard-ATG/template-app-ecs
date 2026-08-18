output "record_name" {
  description = "Name of the Route53 record"
  value       = aws_route53_record.main.name
}
output "record_type" {
  description = "Type of the Route53 record"
  value       = aws_route53_record.main.type
}
output "record_fqdn" {
  description = "Fully qualified domain name of the Route53 record"
  value       = aws_route53_record.main.fqdn
}
output "record_zone_id" {
  description = "Zone ID of the Route53 record"
  value       = aws_route53_record.main.zone_id
}
