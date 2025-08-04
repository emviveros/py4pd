# build_all.ps1 - Build multiplataforma real do py4pd (Windows, PowerShell)
# Gera binários reais para todas as versões de Python suportadas.
# Idempotente e pronto para automação local/CI.

$ErrorActionPreference = "Stop"

# Carrega variáveis de ambiente do env_vars.bat
$envVarsBat = "$PSScriptRoot\env_vars.bat"
if (Test-Path $envVarsBat) {
    Write-Host "==> Carregando variáveis de ambiente de env_vars.bat"
    foreach ($line in & cmd /c "call `"$envVarsBat`" && set") {
        if ($line -match "^(.*?)=(.*)$") {
            $name = $matches[1]
            $value = $matches[2]
            # Importa todas as variáveis, incluindo PATH para garantir cmake disponível
            Set-Item -Path "Env:$name" -Value $value
        }
    }
} else {
    Write-Host "!! env_vars.bat não encontrado, usando variáveis do ambiente atual."
}

# Defina as versões de Python suportadas
$PY_VERSIONS = @("3.11", "3.12")

# Diretórios
$ROOT_DIR = Resolve-Path "$PSScriptRoot\.."
$BUILD_DIR = "$ROOT_DIR\build"
$DIST_DIR = "$ROOT_DIR\dist"

# Variáveis de ambiente do SDK do Pure Data (devem estar definidas antes)
$PD_SDK_LIBDIR = $env:PD_SDK_LIB_DIR_X64
$PD_SDK_INCLUDEDIR = $env:PD_SDK_INCLUDE_DIR

Write-Host "==> Limpando diretórios build\ e dist\"
if (Test-Path $BUILD_DIR) { Remove-Item $BUILD_DIR -Recurse -Force }
if (Test-Path $DIST_DIR) { Remove-Item $DIST_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $DIST_DIR | Out-Null

foreach ($V in $PY_VERSIONS) {
    $BUILD_SUBDIR = "$BUILD_DIR\py$V"
    Write-Host "==> Compilando para Python $V"
    New-Item -ItemType Directory -Path $BUILD_SUBDIR -Force | Out-Null

    # Detecta arquitetura
    $arch = switch ($env:PROCESSOR_ARCHITECTURE) {
        "AMD64" { "x64" }
        "x86" { "x86" }
        "ARM64" { "arm64" }
        default { $env:PROCESSOR_ARCHITECTURE }
    }

    # Monta prefixo das variáveis de ambiente
    $varPrefix = "PYTHON$($V.Replace('.',''))_$arch"
    $pythonExe = (Get-Item "Env:${varPrefix}_EXE").Value
    $pythonRoot = (Get-Item "Env:${varPrefix}_ROOT").Value
    $pythonInclude = (Get-Item "Env:${varPrefix}_INCLUDE").Value
    $pythonLib = (Get-Item "Env:${varPrefix}_LIB").Value

    Write-Host "==> Usando Python para build: $pythonExe ($V, $arch)"
    Write-Host "    - ROOT: $pythonRoot"
    Write-Host "    - INCLUDE: $pythonInclude"
    Write-Host "    - LIB: $pythonLib"

    # Verificar se os arquivos/diretórios existem antes do build
    if (-not (Test-Path $pythonExe)) {
        Write-Host "   [ERROR] Python executável não encontrado: $pythonExe" -ForegroundColor Red
        exit 1
    }
    if (-not (Test-Path $pythonInclude)) {
        Write-Host "   [ERROR] Diretório de headers Python não encontrado: $pythonInclude" -ForegroundColor Red
        exit 1
    }
    if (-not (Test-Path $pythonLib)) {
        Write-Host "   [ERROR] Biblioteca Python não encontrada: $pythonLib" -ForegroundColor Red
        exit 1
    }

    # Executar CMake com escape adequado para paths com espaços
    Write-Host "==> Configurando CMake para Python $V..."
    
    # Usar paths com barras normais para CMake (mais compatível)
    $pythonExeCMake = $pythonExe -replace '\\', '/'
    $pythonRootCMake = $pythonRoot -replace '\\', '/'
    $pythonIncludeCMake = $pythonInclude -replace '\\', '/'
    $pythonLibCMake = $pythonLib -replace '\\', '/'
    $pdSdkLibdirCMake = $PD_SDK_LIBDIR -replace '\\', '/'
    $pdSdkIncludedirCMake = $PD_SDK_INCLUDEDIR -replace '\\', '/'
    
    cmake -B "$BUILD_SUBDIR" `
        -DPYVERSION="$V" `
        -DPYTHON_EXECUTABLE="$pythonExeCMake" `
        -DPD_SDK_LIBDIR="$pdSdkLibdirCMake" `
        -DPD_SDK_INCLUDEDIR="$pdSdkIncludedirCMake"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   [ERROR] Falha na configuração CMake para Python $V" -ForegroundColor Red
        exit 1
    }

    # Build com configuração Release explícita
    Write-Host "==> Compilando binário para Python $V..."
    cmake --build "$BUILD_SUBDIR" --config Release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   [ERROR] Falha na compilação para Python $V" -ForegroundColor Red
        exit 1
    }

    # Buscar binários no local padrão (determinístico)
    $bins = Get-ChildItem "$BUILD_SUBDIR\py4pd.*" -ErrorAction SilentlyContinue
    if ($bins.Count -eq 0) {
        Write-Host "   [ERROR] Binario nao encontrado para Python $V" -ForegroundColor Red
        Write-Host "   [INFO] Verificado: $BUILD_SUBDIR\py4pd.*" -ForegroundColor Gray
        exit 1
    }
    
    Write-Host "   [OK] Encontrado(s) $($bins.Count) binario(s) para Python $V" -ForegroundColor Green
    foreach ($bin in $bins) {
        $dest = "$DIST_DIR\py4pd-$V$($bin.Extension)"
        Copy-Item $bin.FullName $dest
        Write-Host "   -> Binário copiado: $($bin.Name) para $dest" -ForegroundColor Cyan
    }
}

Write-Host "`n[SUCCESS] Build finalizado com sucesso para todas as versoes!" -ForegroundColor Green
Write-Host "[INFO] Verificar binarios em: $DIST_DIR" -ForegroundColor Cyan

# Mostrar resumo dos binários gerados
Write-Host "`n[SUMMARY] Resumo dos binarios gerados:" -ForegroundColor Yellow
$generatedBinaries = Get-ChildItem "$DIST_DIR\*.dll" -ErrorAction SilentlyContinue
if ($generatedBinaries) {
    foreach ($binary in $generatedBinaries) {
        $sizeKB = [math]::Round($binary.Length / 1KB, 1)
        Write-Host "  [FILE] $($binary.Name) ($sizeKB KB)" -ForegroundColor White
    }
} else {
    Write-Host "  [ERROR] Nenhum binario encontrado no diretorio de distribuicao!" -ForegroundColor Red
}