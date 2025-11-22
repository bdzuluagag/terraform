# ============================================
# SCRIPT PARA CARGAR VARIABLES DE ENTORNO
# ============================================
# 
# Este script carga las variables del archivo .env
# y las hace disponibles para Terraform y AWS CLI
#
# USO:
#   .\load-env.ps1
#
# ============================================

# Verificar si existe el archivo .env
if (-not (Test-Path ".env")) {
    Write-Host "❌ ERROR: No se encuentra el archivo .env" -ForegroundColor Red
    Write-Host ""
    Write-Host "📝 SOLUCIÓN:" -ForegroundColor Yellow
    Write-Host "1. Copia el archivo .env.example:" -ForegroundColor White
    Write-Host "   Copy-Item .env.example .env" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Edita el archivo .env con tus credenciales:" -ForegroundColor White
    Write-Host "   notepad .env" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Obtén las credenciales de AWS Academy:" -ForegroundColor White
    Write-Host "   AWS Academy → Tu laboratorio → AWS Details → Show (AWS CLI)" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host "🔄 Cargando variables de entorno desde .env..." -ForegroundColor Cyan

# Leer el archivo .env línea por línea
Get-Content .env | ForEach-Object {
    # Ignorar líneas vacías y comentarios
    if ($_ -match '^\s*$' -or $_ -match '^\s*#') {
        return
    }
    
    # Separar clave=valor
    if ($_ -match '^([^=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        
        # Establecer la variable de entorno
        [Environment]::SetEnvironmentVariable($key, $value, "Process")
        
        # Mostrar confirmación (ocultar valores sensibles)
        if ($key -like "*KEY*" -or $key -like "*SECRET*" -or $key -like "*TOKEN*" -or $key -like "*PASSWORD*") {
            Write-Host "  ✅ $key=***" -ForegroundColor Green
        } else {
            Write-Host "  ✅ $key=$value" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "✨ Variables cargadas exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Próximos pasos:" -ForegroundColor Yellow
Write-Host "  terraform init    # Inicializar Terraform" -ForegroundColor White
Write-Host "  terraform plan    # Ver qué se va a crear" -ForegroundColor White
Write-Host "  terraform apply   # Desplegar infraestructura" -ForegroundColor White
Write-Host ""

# Verificar credenciales de AWS
Write-Host "🔍 Verificando credenciales de AWS..." -ForegroundColor Cyan
try {
    $identity = aws sts get-caller-identity --output json 2>$null | ConvertFrom-Json
    if ($identity) {
        Write-Host "  ✅ Credenciales válidas" -ForegroundColor Green
        Write-Host "  👤 Usuario: $($identity.UserId)" -ForegroundColor White
        Write-Host "  🏢 Cuenta: $($identity.Account)" -ForegroundColor White
    }
} catch {
    Write-Host "  ⚠️ No se pudieron verificar las credenciales" -ForegroundColor Yellow
    Write-Host "  Asegúrate de que AWS CLI esté instalado y configurado" -ForegroundColor White
}
Write-Host ""
