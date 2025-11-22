output "vpc_id" {
  description = "ID de la VPC principal"
  value       = aws_vpc.main.id
}

output "web_alb_dns" {
  description = "DNS público del Load Balancer Web"
  value       = aws_lb.web.dns_name
}

output "app_alb_dns" {
  description = "DNS interno del Load Balancer App"
  value       = aws_lb.app.dns_name
}

output "db_endpoint" {
  description = "Endpoint de escritura de la base de datos Aurora"
  value       = aws_rds_cluster.main.endpoint
}

output "db_reader_endpoint" {
  description = "Endpoint de lectura de la base de datos Aurora"
  value       = aws_rds_cluster.main.reader_endpoint
}
