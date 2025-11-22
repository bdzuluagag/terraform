# ============================================
# INFRAESTRUCTURA AWS THREE-TIER ARCHITECTURE
# ============================================
# Esta es una arquitectura de 3 niveles (capas) que separa:
# - Web Tier: Donde los usuarios acceden (público)
# - App Tier: Donde corre la lógica de negocio (privado)
# - DB Tier: Donde se almacenan los datos (privado y protegido)
#
# Alta disponibilidad: Todo está duplicado en 2 zonas diferentes
# para que si una falla, la otra siga funcionando.
# ============================================

# ------------------------------------
# CONFIGURACIÓN DE TERRAFORM
# ------------------------------------
# Terraform es como un "constructor automático" que lee este código
# y crea toda la infraestructura en AWS por nosotros.
# Aquí le decimos qué versión usar y que trabaje con AWS.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Versión 5.x del proveedor de AWS
    }
  }
  required_version = ">= 1.0"  # Necesitamos Terraform 1.0 o superior
}

# ------------------------------------
# PROVEEDOR AWS
# ------------------------------------
# Le decimos a Terraform que vamos a crear recursos en AWS.
# La región (us-east-1) se lee de las variables de entorno.
# Las credenciales las toma automáticamente del archivo .env

provider "aws" {
  region = var.aws_region  # Variable que definimos en variables.tf
  
  # Estos tags se aplican automáticamente a TODOS los recursos
  # para poder identificarlos fácilmente en AWS
  default_tags {
    tags = {
      Project = var.project_name  # Etiqueta con el nombre del proyecto
    }
  }
}

# ============================================
# DATA SOURCES - Consultando información de AWS
# ============================================
# Los "data sources" son como "consultas" a AWS para obtener
# información que necesitamos pero que NO vamos a crear.
# Son dinámicos: si AWS cambia algo, Terraform lo detecta automáticamente.
# ============================================

# ------------------------------------
# Consulta 1: ¿Qué zonas de disponibilidad hay disponibles?
# ------------------------------------
# Una Zona de Disponibilidad (AZ) es como un "centro de datos" independiente.
# En lugar de escribir "us-east-1a" y "us-east-1b" manualmente,
# le preguntamos a AWS: "¿cuáles están disponibles ahora mismo?"
# Así el código funciona en cualquier región sin cambios.

data "aws_availability_zones" "available" {
  state = "available"  # Solo las que estén operativas
}

# ------------------------------------
# Consulta 2: ¿Cuál es la imagen de Amazon Linux 2 más reciente?
# ------------------------------------
# Una AMI (Amazon Machine Image) es como una "plantilla" para crear servidores.
# En lugar de buscar manualmente el ID de la AMI (que cambia cada mes),
# le pedimos a AWS: "dame la AMI de Amazon Linux 2 más actualizada".
# Así siempre usamos la versión más reciente con parches de seguridad.

data "aws_ami" "amazon_linux_2" {
  most_recent = true      # La más reciente
  owners      = ["amazon"]  # Solo las oficiales de Amazon

  # Filtro 1: El nombre debe contener "amzn2" (Amazon Linux 2)
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  # Filtro 2: Debe ser una máquina virtual completa (HVM)
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================
# VPC - Virtual Private Cloud (Nuestra Red Privada)
# ============================================
# La VPC es como tu "oficina virtual" en AWS: un espacio de red
# completamente aislado y privado donde pondremos todos nuestros recursos.
# Nadie de fuera puede entrar a menos que abramos una puerta (como el Internet Gateway).
#
# CIDR 10.0.0.0/16 significa:
# - Tenemos 65,536 direcciones IP disponibles (10.0.0.0 hasta 10.0.255.255)
# - Las vamos a dividir en "habitaciones" (subnets) más pequeñas
# ============================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr  # Rango de IPs: 10.0.0.0/16
  enable_dns_hostnames = true  # Permite nombres como "ec2-xyz.amazonaws.com"
  enable_dns_support   = true  # Permite resolver nombres DNS dentro de la VPC

  tags = {
    Name = "${var.project_name}-vpc"  # Nombre: threetierlab-vpc
  }
}

# ============================================
# INTERNET GATEWAY - La Puerta Principal
# ============================================
# El Internet Gateway es como la "puerta de entrada" de nuestra oficina virtual.
# Sin él, NADA en la VPC puede hablar con Internet.
# Solo las subnets "públicas" (Web Tier) usarán esta puerta directamente.
# ============================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # Se conecta a nuestra VPC

  tags = {
    Name = "${var.project_name}-igw"  # Nombre: threetierlab-igw
  }
}

# ============================================
# SUBNETS PÚBLICAS - Web Tier (Cara al público)
# ============================================
# Las subnets son como "habitaciones" dentro de nuestra oficina (VPC).
# Las PÚBLICAS son las que tienen "ventanas al exterior" (Internet).
# Aquí pondremos los Load Balancers y futuros servidores web.
#
# ¿Por qué dos subnets públicas?
# - Una en cada Zona de Disponibilidad (us-east-1a y us-east-1b)
# - Si una zona se cae (apagón, terremoto, etc), la otra sigue funcionando
# - Los Load Balancers REQUIEREN mínimo 2 AZs para funcionar
# ============================================

# Subnet Pública en la primera zona (us-east-1a)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"  # 256 IPs (10.0.1.0 a 10.0.1.255)
  availability_zone       = data.aws_availability_zones.available.names[0]  # Primera AZ disponible
  map_public_ip_on_launch = true  # IMPORTANTE: Asignar IP pública automáticamente

  tags = {
    Name = "${var.project_name}-public-subnet-a"
    Tier = "Web"  # Esta subnet es para la capa Web
  }
}

# Subnet Pública en la segunda zona (us-east-1b)
# Es idéntica a la primera, pero en otra ubicación física
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"  # 256 IPs (10.0.2.0 a 10.0.2.255)
  availability_zone       = data.aws_availability_zones.available.names[1]  # Segunda AZ disponible
  map_public_ip_on_launch = true  # IP pública automática

  tags = {
    Name = "${var.project_name}-public-subnet-b"
    Tier = "Web"
  }
}

# ============================================
# 🔒 SUBNETS PRIVADAS - Application Tier (Lógica de negocio)
# ============================================
# Las subnets PRIVADAS NO tienen acceso directo a Internet.
# Son como "habitaciones internas" sin ventanas al exterior.
# Aquí ponemos los servidores que hacen el trabajo pesado:
# - Procesan solicitudes
# - Ejecutan código de la aplicación
# - Se conectan a la base de datos
#
# ¿Cómo acceden a Internet entonces?
# - A través del NAT Gateway (como un "proxy")
# - Solo pueden SALIR a Internet (descargar actualizaciones)
# - Nadie de Internet puede ENTRAR directamente
#
# ¿Por qué dos subnets privadas?
# - Alta disponibilidad: una por cada zona
# - Si falla una zona, la aplicación sigue corriendo en la otra
# ============================================

# Subnet Privada App en la primera zona (us-east-1a)
resource "aws_subnet" "private_app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"  # 256 IPs (10.0.10.0 a 10.0.10.255)
  availability_zone = data.aws_availability_zones.available.names[0]
  # Nota: NO tiene map_public_ip_on_launch = true (es PRIVADA)

  tags = {
    Name = "${var.project_name}-private-app-subnet-a"
    Tier = "Application"
  }
}

# Subnet Privada App en la segunda zona (us-east-1b)
resource "aws_subnet" "private_app_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"  # 256 IPs (10.0.11.0 a 10.0.11.255)
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-private-app-subnet-b"
    Tier = "Application"
  }
}

# ============================================
#  SUBNETS PRIVADAS - Database Tier (El tesoro protegido)
# ============================================
# Estas son las subnets MÁS PRIVADAS y PROTEGIDAS de todas.
# Aquí vive la base de datos con la información crítica.
#
# Capas de seguridad:
# 1. NO tienen acceso directo a Internet (ni siquiera con NAT Gateway)
# 2. Solo el App Tier puede conectarse a ellas
# 3. Security Group bloquea todo excepto puerto 3306 desde App
#
# ¿Por qué dos subnets de base de datos?
# - RDS Aurora REQUIERE mínimo 2 subnets en diferentes AZs
# - Si una zona falla, Aurora hace "failover" automático a la otra
# - El failover tarda menos de 30 segundos
# ============================================

# Subnet Privada DB en la primera zona (us-east-1a)
resource "aws_subnet" "private_db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"  # 256 IPs (10.0.20.0 a 10.0.20.255)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-private-db-subnet-a"
    Tier = "Database"
  }
}

# Subnet Privada DB en la segunda zona (us-east-1b)
resource "aws_subnet" "private_db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"  # 256 IPs (10.0.21.0 a 10.0.21.255)
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-private-db-subnet-b"
    Tier = "Database"
  }
}

# ============================================
# ELASTIC IPs - Direcciones IP fijas para NAT Gateways
# ============================================
# Las Elastic IPs son direcciones IP públicas que NO cambian.
# Son como tener un "número de teléfono fijo" para tus NAT Gateways.
#
# ¿Por qué necesitamos IPs fijas?
# - Para configurar listas blancas (whitelisting) en servicios externos
# - Para poder identificar el tráfico que sale de nuestra VPC
# - Los NAT Gateways REQUIEREN una Elastic IP obligatoriamente
# ============================================

# EIP para NAT Gateway en Zona de Disponibilidad A
resource "aws_eip" "nat_a" {
  domain = "vpc"  # Esta IP es para uso dentro de una VPC

  tags = {
    Name = "${var.project_name}-nat-eip-a"
  }

  # Importante: Crear el Internet Gateway PRIMERO
  # Si no, la EIP no puede asignarse correctamente
  depends_on = [aws_internet_gateway.main]
}

# EIP para NAT Gateway en Zona de Disponibilidad B
resource "aws_eip" "nat_b" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-b"
  }

  depends_on = [aws_internet_gateway.main]
}

# ============================================
# 🚪 NAT GATEWAYS - Puerta de salida para subnets privadas
# ============================================
# Los NAT Gateways son como "puertas traseras" para las subnets privadas.
# Permiten que los servidores privados SALGAN a Internet,
# pero nadie de Internet puede ENTRAR.
#
# Analogía:
# - Internet Gateway = Puerta principal (bidireccional)
# - NAT Gateway = Puerta de emergencia (solo salida)
#
# ¿👉 POR QUÉ CREAR **DOS** NAT GATEWAYS? (ESTO ES CLAVE)
# ============================================
# Esta es una de las decisiones más importantes de la arquitectura.
#
# ❌ OPCIÓN ECONÓMICA (1 NAT Gateway):
# - Costo: ~$32/mes
# - Problema: Si falla la AZ donde está el NAT, TODA la infraestructura
#   privada (ambas zonas) pierde acceso a Internet.
#
# ✅ OPCIÓN RECOMENDADA (2 NAT Gateways - uno por AZ):
# - Costo: ~$64/mes
# - Beneficio: ALTA DISPONIBILIDAD
#   * Si falla AZ A → Solo AZ A pierde Internet, AZ B sigue funcionando
#   * Si falla AZ B → Solo AZ B pierde Internet, AZ A sigue funcionando
#   * Cada zona es independiente
#
# Enrutamiento específico:
# - Subnets privadas en AZ A → Usan NAT Gateway A
# - Subnets privadas en AZ B → Usan NAT Gateway B
# ============================================

# NAT Gateway en Zona de Disponibilidad A
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id  # Usa la EIP que creamos arriba
  subnet_id     = aws_subnet.public_a.id  # Se coloca en la subnet PÚBLICA

  tags = {
    Name = "${var.project_name}-nat-gateway-a"
  }

  # Importante: El Internet Gateway debe existir primero
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway en Zona de Disponibilidad B
# 🚨 Este segundo NAT Gateway es CRÍTICO para la alta disponibilidad
resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id  # Se coloca en la subnet pública B

  tags = {
    Name = "${var.project_name}-nat-gateway-b"
  }

  depends_on = [aws_internet_gateway.main]
}

# ============================================
# ROUTE TABLES - Tablas de Enrutamiento
# ============================================

# Tabla de Enrutamiento Pública (con salida a Internet vía IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Tablas de Enrutamiento Privadas (una por AZ para alta disponibilidad)
# Cada AZ tiene su propia tabla que apunta a su propio NAT Gateway

# Tabla de Enrutamiento Privada para Zona A
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "${var.project_name}-private-rt-a"
  }
}

# Tabla de Enrutamiento Privada para Zona B
resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "${var.project_name}-private-rt-b"
  }
}

# ============================================
# ROUTE TABLE ASSOCIATIONS - Asociaciones
# ============================================

# Asociar Subnets Públicas con la Tabla de Enrutamiento Pública
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Asociar Subnets Privadas (App) con sus Tablas de Enrutamiento respectivas
resource "aws_route_table_association" "private_app_a" {
  subnet_id      = aws_subnet.private_app_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_app_b" {
  subnet_id      = aws_subnet.private_app_b.id
  route_table_id = aws_route_table.private_b.id
}

# Asociar Subnets Privadas (DB) con sus Tablas de Enrutamiento respectivas
resource "aws_route_table_association" "private_db_a" {
  subnet_id      = aws_subnet.private_db_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_db_b" {
  subnet_id      = aws_subnet.private_db_b.id
  route_table_id = aws_route_table.private_b.id
}

# ============================================
# SECURITY GROUPS - Grupos de Seguridad
# ============================================

# Security Group para Web Tier (Acceso público HTTP)
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group para Web Tier - Permite trafico HTTP desde Internet"
  vpc_id      = aws_vpc.main.id

  # Permitir tráfico HTTP entrante desde Internet
  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir todo el tráfico saliente
  egress {
    description = "Todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
    Tier = "Web"
  }
}

# Security Group para Application Tier (Solo desde Web Tier)
resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group para Application Tier - Solo acepta trafico desde Web Tier"
  vpc_id      = aws_vpc.main.id

  # Permitir tráfico en puerto 8080 solo desde Web Tier
  ingress {
    description     = "Puerto 8080 desde Web Tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  # Permitir todo el tráfico saliente
  egress {
    description = "Todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
    Tier = "Application"
  }
}

# Security Group para Database Tier (Solo desde App Tier)
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security group para Database Tier - Solo acepta trafico MySQL desde App Tier"
  vpc_id      = aws_vpc.main.id

  # Permitir tráfico MySQL (puerto 3306) solo desde App Tier
  ingress {
    description     = "MySQL desde App Tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Permitir todo el tráfico saliente
  egress {
    description = "Todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
    Tier = "Database"
  }
}

# ============================================
# DB SUBNET GROUP - Para RDS Aurora
# ============================================

resource "aws_db_subnet_group" "main" {
  name       = lower("${var.project_name}-db-subnet-group")
  subnet_ids = [aws_subnet.private_db_a.id, aws_subnet.private_db_b.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ============================================
# RDS AURORA CLUSTER - MySQL Multi-AZ
# ============================================

resource "aws_rds_cluster" "main" {
  cluster_identifier      = lower("${var.project_name}-aurora-cluster")
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.04.0"
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  skip_final_snapshot     = true
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"

  tags = {
    Name = "${var.project_name}-aurora-cluster"
  }
}

# Instancia Aurora en AZ 'a' (Primary)
resource "aws_rds_cluster_instance" "primary" {
  identifier           = lower("${var.project_name}-aurora-instance-a")
  cluster_identifier   = aws_rds_cluster.main.id
  instance_class       = var.db_instance_class
  engine               = aws_rds_cluster.main.engine
  engine_version       = aws_rds_cluster.main.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.main.name

  tags = {
    Name = "${var.project_name}-aurora-instance-a"
  }
}

# Instancia Aurora en AZ 'b' (Replica)
resource "aws_rds_cluster_instance" "replica" {
  identifier           = lower("${var.project_name}-aurora-instance-b")
  cluster_identifier   = aws_rds_cluster.main.id
  instance_class       = var.db_instance_class
  engine               = aws_rds_cluster.main.engine
  engine_version       = aws_rds_cluster.main.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.main.name

  tags = {
    Name = "${var.project_name}-aurora-instance-b"
  }
}

# ============================================
# EC2 INSTANCE - Application Tier con Node.js
# ============================================

# User Data Script para instalar NVM y Node.js LTS
locals {
  user_data = <<-EOF
              #!/bin/bash
              # Script de inicialización para Application Tier
              # Instala NVM y Node.js LTS
              
              # Actualizar el sistema
              yum update -y
              
              # Instalar dependencias necesarias
              yum install -y git curl
              
              # Definir variables
              NVM_VERSION="v0.39.7"
              NODE_VERSION="lts/*"
              
              # Instalar NVM como usuario ec2-user
              su - ec2-user -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash"
              
              # Cargar NVM en el perfil
              su - ec2-user -c "source ~/.nvm/nvm.sh && nvm install $NODE_VERSION && nvm use $NODE_VERSION && nvm alias default $NODE_VERSION"
              
              # Verificar instalación
              su - ec2-user -c "source ~/.nvm/nvm.sh && node --version && npm --version"
              
              # Crear un archivo de verificación
              echo "Node.js instalado correctamente" > /home/ec2-user/nodejs-installed.txt
              echo "Versión de Node.js:" >> /home/ec2-user/nodejs-installed.txt
              su - ec2-user -c "source ~/.nvm/nvm.sh && node --version" >> /home/ec2-user/nodejs-installed.txt
              echo "Versión de NPM:" >> /home/ec2-user/nodejs-installed.txt
              su - ec2-user -c "source ~/.nvm/nvm.sh && npm --version" >> /home/ec2-user/nodejs-installed.txt
              chown ec2-user:ec2-user /home/ec2-user/nodejs-installed.txt
              
              # Configurar .bashrc para cargar NVM automáticamente
              echo 'export NVM_DIR="$HOME/.nvm"' >> /home/ec2-user/.bashrc
              echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/ec2-user/.bashrc
              echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/ec2-user/.bashrc
              EOF
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.app_instance_type
  subnet_id              = aws_subnet.private_app_a.id
  vpc_security_group_ids = [aws_security_group.app.id]
  user_data              = local.user_data

  # Deshabilitar metadata service v2 requirement para mayor compatibilidad
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-app-instance"
    Tier = "Application"
  }
}

# ============================================
# APPLICATION LOAD BALANCERS
# ============================================

# Target Group para el ALB Público (Web Tier)
resource "aws_lb_target_group" "web" {
  name     = "${lower(var.project_name)}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
  }

  tags = {
    Name = "${var.project_name}-web-tg"
    Tier = "Web"
  }
}

# Target Group para el ALB Interno (App Tier)
resource "aws_lb_target_group" "app" {
  name     = "${lower(var.project_name)}-app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
  }

  tags = {
    Name = "${var.project_name}-app-tg"
    Tier = "Application"
  }
}

# Registrar la instancia EC2 en el Target Group de App
resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id
  port             = 8080
}

# ALB Público para Web Tier
resource "aws_lb" "web" {
  name               = "${lower(var.project_name)}-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "${var.project_name}-web-alb"
    Tier = "Web"
  }
}

# Listener para ALB Web (Puerto 80)
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ALB Interno para App Tier
resource "aws_lb" "app" {
  name               = "${lower(var.project_name)}-app-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app.id]
  subnets            = [aws_subnet.private_app_a.id, aws_subnet.private_app_b.id]

  tags = {
    Name = "${var.project_name}-app-alb"
    Tier = "Application"
  }
}

# Listener para ALB App (Puerto 8080)
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
