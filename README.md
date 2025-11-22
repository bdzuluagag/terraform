# 🚀 Three-Tier AWS Infrastructure con Terraform

Infraestructura de tres capas en AWS con **alta disponibilidad**, desplegada usando Terraform como Infraestructura como Código (IaC).

## 📋 Tabla de Contenidos

- [Arquitectura](#-arquitectura)
- [Requisitos Previos](#-requisitos-previos)
- [Configuración Rápida](#-configuración-rápida)
- [Uso](#-uso)
- [Recursos Creados](#-recursos-creados)
- [Alta Disponibilidad](#-alta-disponibilidad)
- [Colaboración](#-colaboración)

### Red y Conectividad
- **1 VPC**: `10.0.0.0/16` en `us-east-1`
- **6 Subnets** distribuidas en 2 Availability Zones:
  - 2 Públicas (Web): `10.0.1.0/24`, `10.0.2.0/24`
  - 2 Privadas App: `10.0.10.0/24`, `10.0.11.0/24`
  - 2 Privadas DB: `10.0.20.0/24`, `10.0.21.0/24`
- **1 Internet Gateway** (acceso a Internet)
- **1 NAT Gateway** (salida para subnets privadas)
- **Tablas de Enrutamiento** configuradas

### Seguridad
- **3 Security Groups** con reglas encadenadas:
  - **Web SG**: HTTP (80) desde Internet
  - **App SG**: Puerto 8080 solo desde Web SG
  - **DB SG**: MySQL (3306) solo desde App SG

### Cómputo
- **1 Instancia EC2** (Amazon Linux 2, t2.micro)
  - Ubicación: Subnet privada App (AZ a)
  - Con Node.js LTS instalado automáticamente via user_data
  - Security Group: App

### Base de Datos
- **1 Cluster RDS Aurora MySQL** (Multi-AZ)
  - 2 instancias: Primary + Replica (db.t3.medium)
  - Engine: Aurora MySQL 8.0
  - Backup retention: 7 días

## 📋 Archivos del Proyecto

```
lab_terraform/
├── main.tf          # Configuración principal de la infraestructura
├── variables.tf     # Variables configurables
├── outputs.tf       # Outputs de recursos creados
├── README.md        # Este archivo
└── .terraform/      # Archivos de Terraform (auto-generado)
```

## 🚀 Uso

### 1. Configurar Credenciales AWS Academy

```powershell
# Crear directorio .aws
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.aws"

# Editar credenciales
notepad "$env:USERPROFILE\.aws\credentials"
```

Pegar las credenciales de AWS Academy (obtenidas de "AWS Details" → "Show"):
```
[default]
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=...
```

### 2. Inicializar Terraform

```powershell
cd c:\Users\zulua\Documents\cloud\lab_terraform
terraform init
```

### 3. Ver el Plan

```powershell
terraform plan
```

### 4. Aplicar la Infraestructura

```powershell
terraform apply
```

### 5. Ver los Outputs

```powershell
terraform output
```

## 📊 Información de Conexión

Después del despliegue, obtendrás:

- **VPC ID**
- **Subnet IDs** (públicas, privadas app, privadas db)
- **IP del NAT Gateway**
- **Endpoint RDS Aurora** (lectura/escritura)
- **IP privada de la instancia EC2**
- **Security Group IDs**

### Credenciales de Base de Datos

- **Endpoint**: Ver output `rds_cluster_endpoint`
- **Puerto**: 3306
- **Base de Datos**: `threetierdb`
- **Usuario**: `admin`
- **Contraseña**: `ThreeTier2025`

## 🗑️ Destruir la Infraestructura

**IMPORTANTE**: Ejecutar siempre al terminar para evitar costos.

```powershell
terraform destroy
```

Escribir `yes` cuando se solicite confirmación.

## ⚙️ Variables Configurables

Puedes modificar `variables.tf` o pasar valores en la línea de comandos:

```powershell
# Cambiar región
terraform apply -var="aws_region=us-west-2"

# Cambiar tipo de instancia
terraform apply -var="app_instance_type=t2.small"

# Cambiar contraseña de DB
terraform apply -var="db_password=MiNuevaPassword123"
```

## 📝 Notas Importantes

### AWS Academy Learner Lab
- Las credenciales **expiran** después de 3-4 horas
- Debes actualizarlas cada vez que reinicies el laboratorio
- NO se pueden crear usuarios IAM en AWS Academy

### Costos
Los siguientes recursos generan costos:
- **NAT Gateway**: ~$0.045/hora + tráfico
- **RDS Aurora**: ~$0.082/hora por instancia (db.t3.medium)
- **EC2**: Gratis en free tier (t2.micro)

### Tiempos de Creación
- VPC, Subnets, SGs: ~1 minuto
- NAT Gateway: ~2 minutos
- Instancia EC2: ~30 segundos
- RDS Aurora: **5-10 minutos por instancia**

## 🔧 Troubleshooting

### Error: "No credentials found"
```powershell
# Verificar credenciales
aws sts get-caller-identity
```

### Error: "ExpiredToken"
Las credenciales expiraron. Actualiza el archivo:
```powershell
notepad "$env:USERPROFILE\.aws\credentials"
```

### Ver recursos en AWS
```powershell
# Ver instancias EC2
aws ec2 describe-instances --region us-east-1

# Ver clusters RDS
aws rds describe-db-clusters --region us-east-1

# Ver VPCs
aws ec2 describe-vpcs --region us-east-1
```

## 📚 Arquitectura

```
Internet
   │
   ├─── Internet Gateway
   │
   ├─── Public Subnets (us-east-1a, us-east-1b)
   │         └─── NAT Gateway
   │
   ├─── Private App Subnets (us-east-1a, us-east-1b)
   │         └─── EC2 Instance (Node.js)
   │
   └─── Private DB Subnets (us-east-1a, us-east-1b)
             └─── RDS Aurora Cluster (Primary + Replica)
```

## 📄 Licencia

Proyecto educativo para AWS Academy Learner Lab.
