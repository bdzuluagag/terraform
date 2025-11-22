# ============================================
# OUTPUTS - Información de los recursos creados
# ============================================

# VPC
output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR de la VPC"
  value       = aws_vpc.main.cidr_block
}

# Zonas de Disponibilidad
output "availability_zones" {
  description = "Zonas de disponibilidad utilizadas"
  value       = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
}

# Subnets Públicas
output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

# Subnets Privadas - App
output "private_app_subnet_ids" {
  description = "IDs de las subnets privadas de Application Tier"
  value       = [aws_subnet.private_app_a.id, aws_subnet.private_app_b.id]
}

# Subnets Privadas - DB
output "private_db_subnet_ids" {
  description = "IDs de las subnets privadas de Database Tier"
  value       = [aws_subnet.private_db_a.id, aws_subnet.private_db_b.id]
}

# NAT Gateways (Alta Disponibilidad - uno por AZ)
output "nat_gateway_a_ip" {
  description = "IP pública del NAT Gateway en AZ A"
  value       = aws_eip.nat_a.public_ip
}

output "nat_gateway_b_ip" {
  description = "IP pública del NAT Gateway en AZ B"
  value       = aws_eip.nat_b.public_ip
}

# Security Groups
output "web_security_group_id" {
  description = "ID del Security Group del Web Tier"
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "ID del Security Group del Application Tier"
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "ID del Security Group del Database Tier"
  value       = aws_security_group.db.id
}

# RDS Aurora Cluster
output "rds_cluster_endpoint" {
  description = "Endpoint del cluster RDS Aurora (escritura)"
  value       = aws_rds_cluster.main.endpoint
}

output "rds_cluster_reader_endpoint" {
  description = "Endpoint de lectura del cluster RDS Aurora"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "rds_cluster_port" {
  description = "Puerto del cluster RDS Aurora"
  value       = aws_rds_cluster.main.port
}

output "rds_cluster_database_name" {
  description = "Nombre de la base de datos"
  value       = aws_rds_cluster.main.database_name
}

# EC2 Instance - App Tier
output "app_instance_id" {
  description = "ID de la instancia EC2 del Application Tier"
  value       = aws_instance.app.id
}

output "app_instance_private_ip" {
  description = "IP privada de la instancia EC2 del Application Tier"
  value       = aws_instance.app.private_ip
}

output "app_instance_ami" {
  description = "AMI utilizada para la instancia del Application Tier"
  value       = aws_instance.app.ami
}

# Información de conexión
output "connection_info" {
  description = "Información para conectarse a los recursos"
  value = {
    database_endpoint = aws_rds_cluster.main.endpoint
    database_name     = var.db_name
    database_user     = var.db_username
    app_instance_ip   = aws_instance.app.private_ip
  }
  sensitive = true
}

# Application Load Balancers
output "web_alb_dns" {
  description = "DNS del ALB público (Web Tier)"
  value       = aws_lb.web.dns_name
}

output "app_alb_dns" {
  description = "DNS del ALB interno (App Tier)"
  value       = aws_lb.app.dns_name
}

output "web_url" {
  description = "URL para acceder al ALB Web"
  value       = "http://${aws_lb.web.dns_name}"
}
