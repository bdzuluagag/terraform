# ============================================
# VARIABLES DE CONFIGURACIÓN - Laboratorio Three-Tier
# ============================================
# Este archivo define todas las variables que puedes personalizar
# para tu infraestructura AWS

# Región de AWS donde se creará toda la infraestructura
variable "aws_region" {
  description = "Región de AWS (por ejemplo: us-east-1, us-west-2)"
  type        = string
  default     = "us-east-1"
}

# Bloque CIDR para la red VPC (red principal donde vivirán todos los recursos)
variable "vpc_cidr" {
  description = "Rango de direcciones IP para la VPC (ejemplo: 10.0.0.0/16 da 65,536 IPs)"
  type        = string
  default     = "10.0.0.0/16"
}

# Nombre del proyecto (aparecerá en las etiquetas de todos los recursos)
variable "project_name" {
  description = "Nombre del proyecto (se usa para etiquetar recursos en AWS)"
  type        = string
  default     = "threetierapp"
}

# Tipo de instancia EC2 para el servidor de aplicaciones
# t2.micro = gratis en free tier, t2.small = más potente pero con costo
variable "app_instance_type" {
  description = "Tamaño de la máquina virtual EC2 (t2.micro, t2.small, etc.)"
  type        = string
  default     = "t2.micro"
}

# ============================================
# CONFIGURACIÓN DE BASE DE DATOS
# ============================================

# Usuario administrador de la base de datos Aurora MySQL
variable "db_username" {
  description = "Nombre de usuario para conectarse a la base de datos"
  type        = string
  default     = "admin"
  sensitive   = true # No se mostrará en los logs
}

# Contraseña de la base de datos (cámbiala en producción!)
variable "db_password" {
  description = "Contraseña del usuario de base de datos"
  type        = string
  default     = "ThreeTier2025"
  sensitive   = true # No se mostrará en los logs
}

# Nombre de la base de datos que se creará automáticamente
variable "db_name" {
  description = "Nombre de la base de datos inicial que se creará"
  type        = string
  default     = "threetierdb"
}

# Tamaño de las instancias de base de datos Aurora
# db.t3.medium = recomendado para desarrollo/pruebas
variable "db_instance_class" {
  description = "Tamaño de las instancias de base de datos (db.t3.small, db.t3.medium)"
  type        = string
  default     = "db.t3.medium"
}
