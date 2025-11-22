# 🚀 AWS Three-Tier Infrastructure con Terraform

Infraestructura de tres capas en AWS con **alta disponibilidad en 2 zonas**, desplegada usando Terraform como Infraestructura como Código (IaC).

## 🏗️ Arquitectura

```
                         INTERNET
                            │
                            │ HTTP:80
                            ▼
              ┌─────────────────────────┐
              │   Web ALB (Público)     │
              └─────────────────────────┘
                     │            │
         ┌───────────┴────────────┴───────────┐
         │   PUBLIC SUBNETS (2 AZs)           │
         │   10.0.1.0/24 - 10.0.2.0/24        │
         └────────────────────────────────────┘
                │                    │
         NAT Gateway A         NAT Gateway B
         (us-east-1a)         (us-east-1b)
                │                    │
         ════════════════════════════════════════
                  WEB TIER → APP TIER
         ════════════════════════════════════════
                │                    │
         ┌──────┴────────────────────┴──────┐
         │    App ALB (Interno)             │
         └──────────────────────────────────┘
                │                    │
         ┌──────┴────────────────────┴──────┐
         │ PRIVATE APP SUBNETS (2 AZs)      │
         │ 10.0.10.0/24 - 10.0.11.0/24      │
         │       EC2 Instances              │
         └──────────────────────────────────┘
                │                    │
         ════════════════════════════════════════
                  APP TIER → DB TIER
         ════════════════════════════════════════
                │                    │
         ┌──────┴────────────────────┴──────┐
         │ PRIVATE DB SUBNETS (2 AZs)       │
         │ 10.0.20.0/24 - 10.0.21.0/24      │
         │   RDS Aurora MySQL (Multi-AZ)    │
         └──────────────────────────────────┘
```

## ✨ Características

- ✅ **Alta disponibilidad** con recursos en 2 Zonas de Disponibilidad
- ✅ **2 NAT Gateways** independientes (uno por AZ) para redundancia
- ✅ **RDS Aurora MySQL** con failover automático < 30 segundos
- ✅ **Security Groups encadenados** (Web → App → DB)
- ✅ **Infraestructura como Código** versionada y reproducible
- ✅ **Variables de entorno** para colaboración segura

## 📦 Recursos Creados (37 en total)

### Networking (20 recursos)
- 1 VPC con DNS habilitado
- 6 Subnets (2 públicas + 2 privadas app + 2 privadas db)
- 1 Internet Gateway
- **2 NAT Gateways** (⭐ **crítico para alta disponibilidad**)
- 2 Elastic IPs
- 3 Route Tables
- 6 Route Table Associations

### Seguridad (3 recursos)
- Web Security Group (HTTP desde Internet)
- App Security Group (puerto 8080 solo desde Web)
- DB Security Group (MySQL solo desde App)

### Base de Datos (4 recursos)
- RDS Aurora MySQL Cluster (Multi-AZ)
- 2 Instancias (primaria + réplica)
- 1 DB Subnet Group

### Cómputo (1 recurso)
- 1 Instancia EC2 con Node.js LTS

### Load Balancers (7 recursos)
- 2 Application Load Balancers
- 2 Target Groups
- 2 Listeners
- 1 Target Attachment

---

## 🚀 Inicio Rápido

### 1. Requisitos Previos

```powershell
# Instalar Terraform
winget install -e --id Hashicorp.Terraform

# Instalar AWS CLI
winget install -e --id Amazon.AWSCLI

# Clonar el repositorio
git clone https://github.com/bdzuluagag/terraform.git
cd terraform
```

### 2. Configurar Credenciales

```powershell
# Copiar el archivo de ejemplo
Copy-Item .env.example .env

# Editar con tus credenciales de AWS Academy
notepad .env
```

**Obtener credenciales:**
1. Ve a AWS Academy → Tu Laboratorio
2. Clic en **"AWS Details"** → **"Show"** (AWS CLI)
3. Copia las 3 líneas de credenciales
4. Pégalas en el archivo `.env`

### 3. Desplegar Infraestructura

```powershell
# Cargar variables de entorno
.\load-env.ps1

# Inicializar Terraform
terraform init

# Ver qué se va a crear
terraform plan

# Crear la infraestructura (~10 minutos)
terraform apply -auto-approve
```

### 4. Ver Recursos Creados

```powershell
# Ver todos los outputs
terraform output

# URL del Web ALB
terraform output web_url

# Endpoint de la base de datos
terraform output rds_cluster_endpoint
```

---

## 🛡️ Alta Disponibilidad

### ¿Por qué 2 NAT Gateways?

Esta es una de las decisiones arquitectónicas más importantes:

| Configuración | Costo/mes | Disponibilidad | Qué pasa si falla una AZ |
|---------------|-----------|----------------|--------------------------|
| **1 NAT Gateway** | ~$32 | ❌ Baja | 💥 **Toda** la infraestructura privada pierde Internet |
| **2 NAT Gateways** | ~$64 | ✅ Alta | ✅ Solo la AZ afectada pierde Internet, la otra sigue funcionando |

### Enrutamiento por AZ

```
Subnets Privadas AZ A  →  Route Table A  →  NAT Gateway A  →  Internet
Subnets Privadas AZ B  →  Route Table B  →  NAT Gateway B  →  Internet
```

Si falla **us-east-1a**:
- ❌ NAT Gateway A inaccesible
- ✅ NAT Gateway B sigue funcionando
- ✅ Aplicaciones en AZ B continúan operando

### Failover Automático

- **RDS Aurora**: < 30 segundos de failover
- **ALBs**: Redirigen tráfico a instancias saludables automáticamente
- **NAT Gateways**: 99.9% SLA por AWS

---

## 👥 Colaboración

### Para Contribuidores

Este proyecto usa **variables de entorno** para proteger credenciales:

```bash
# ✅ HACER: Cada persona tiene su propio .env (local, NO se sube a Git)
.env                  # ← Tu archivo local con TUS credenciales

# ✅ HACER: Compartir el archivo de ejemplo sin credenciales
.env.example          # ← Plantilla compartida en Git

# ❌ NUNCA: Subir credenciales a Git
git add .env          # ← ¡ESTO ESTÁ BLOQUEADO por .gitignore!
```

### Flujo de Trabajo

```powershell
# 1. Clonar el repo
git clone https://github.com/bdzuluagag/terraform.git
cd terraform

# 2. Configurar tus credenciales locales
Copy-Item .env.example .env
notepad .env  # Agregar TUS credenciales

# 3. Trabajar en una rama
git checkout -b feature/mi-mejora

# 4. Hacer cambios
# ... editar archivos ...

# 5. Commit y push
git add main.tf variables.tf  # ← Solo archivos de código
git commit -m "feat: agregar nueva funcionalidad"
git push origin feature/mi-mejora
```

### Variables de Terraform

Las variables con prefijo `TF_VAR_` se leen automáticamente:

```bash
# En .env
TF_VAR_project_name=miproyecto
TF_VAR_vpc_cidr=10.0.0.0/16
TF_VAR_db_password=MiPassword123
```

```hcl
# En variables.tf (NO necesitas hacer nada especial)
variable "project_name" {
  # Se lee automáticamente de TF_VAR_project_name
}
```

---

## 🔧 Mantenimiento

### Renovar Credenciales AWS Academy

Las credenciales expiran cada 3-4 horas:

```powershell
# 1. Obtener nuevas credenciales de AWS Academy
# 2. Actualizar .env
notepad .env

# 3. Recargar variables
.\load-env.ps1

# 4. Verificar
aws sts get-caller-identity
```

### Actualizar Infraestructura

```powershell
# Ver cambios pendientes
terraform plan

# Aplicar cambios
terraform apply

# Ver estado actual
terraform state list
```

### Destruir Todo

```powershell
# Ver qué se va a eliminar
terraform plan -destroy

# Eliminar todos los recursos
terraform destroy -auto-approve
```

---

## 📁 Estructura del Proyecto

```
terraform/
├── .env.example          # Plantilla de credenciales (compartido)
├── .env                  # Tus credenciales (local, NO en Git)
├── .gitignore            # Archivos ignorados por Git
├── load-env.ps1          # Script para cargar variables
├── main.tf               # Infraestructura principal
├── variables.tf          # Variables configurables
├── outputs.tf            # Outputs de recursos
├── README.md             # Esta documentación
├── GUIA_COMPLETA.md      # Documentación técnica detallada
└── CHECKLIST_VERIFICACION.md  # Lista de verificación
```

---

## 🐛 Troubleshooting

### Error: Credenciales expiradas

```
Error: error configuring Terraform AWS Provider
```

**Solución:**
```powershell
notepad .env           # Actualizar credenciales
.\load-env.ps1         # Recargar
```

### Error: NAT Gateway Limit Exceeded

```
Error: NatGatewayLimitExceeded
```

**Solución:**
- AWS Academy limita a 1-2 NAT Gateways por región
- Elimina NAT Gateways antiguos en otras VPCs
- O ejecuta `terraform destroy` para limpiar

### Web ALB responde 503

**Esto es NORMAL:**
- No hay instancias EC2 en el Web Target Group todavía
- El ALB está esperando servidores web

**Verificar:**
```powershell
aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups --names threetierlab-web-tg --query "TargetGroups[0].TargetGroupArn" --output text)
```

---

## 📚 Documentación Adicional

- [GUIA_COMPLETA.md](GUIA_COMPLETA.md) - Explicación detallada de cada componente
- [CHECKLIST_VERIFICACION.md](CHECKLIST_VERIFICACION.md) - Verificar que todo funcione
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 💰 Costos Estimados

| Recurso | Costo Mensual (aprox) |
|---------|----------------------|
| 2 NAT Gateways | ~$64 |
| RDS Aurora (2x db.t3.medium) | ~$118 |
| EC2 t2.micro | Gratis (Free Tier) |
| ALBs | ~$22 |
| **Total** | **~$204/mes** |

**En AWS Academy:** ✅ Gratis (usa créditos del laboratorio)

---

## 📄 Licencia

Este proyecto es de código abierto para uso educativo.

---

## 👤 Autor

**Proyecto Three-Tier AWS Infrastructure**

- GitHub: [@bdzuluagag](https://github.com/bdzuluagag)
- Repositorio: [terraform](https://github.com/bdzuluagag/terraform)

---

**Última actualización:** Noviembre 2025

**Versión:** 2.0 - Con alta disponibilidad completa (2 NAT Gateways)
