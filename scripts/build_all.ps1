# build_all.ps1 - Build multiplataforma real do py4pd (Windows, PowerShell)
# Gera binários reais para todas as versões de Python suportadas.
# Idempotente e pronto para automação local/CI.

$ErrorActionPreference = "Stop"

# Carrega variáveis de ambiente do env_vars.bat
$envVarsBat = "$PSScriptRoot\env_vars.bat"
if (Test-Path $envVarsBat) {
    Write-Host "==> Carregando variáveis de ambiente de env_vars.bat"
    cmd /c "call `"$envVarsBat`" && set" | ForEach-Object {
        if ($_ -match "^(.*?)=(.*)$") {
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
$PD_SDK_LIBDIR = $env:PD_SDK_LIBDIR
$PD_SDK_INCLUDEDIR = $env:PD_SDK_INCLUDEDIR

Write-Host "==> Limpando diretórios build\ e dist\"
if (Test-Path $BUILD_DIR) { Remove-Item $BUILD_DIR -Recurse -Force }
if (Test-Path $DIST_DIR) { Remove-Item $DIST_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $DIST_DIR | Out-Null

foreach ($V in $PY_VERSIONS) {
    $BUILD_SUBDIR = "$BUILD_DIR\py$V"
    Write-Host "==> Compilando para Python $V"
    New-Item -ItemType Directory -Path $BUILD_SUBDIR -Force | Out-Null

Write-Host "==> Executável cmake detectado em: $(Get-Command cmake | Select-Object -ExpandProperty Source)"
if (-not ($(Get-Command cmake | Select-Object -ExpandProperty Source) -match "cmake")) {
        Write-Host "ERRO: O executável 'cmake' não está correto no PATH. Ajuste o PATH para priorizar o CMake real."
        exit 1
    }
    Write-Host "==> PATH atual: $env:PATH"
    # Usa o executável Python correto para cada versão (exportado pelo setup)
    $pythonExe = ${env:PYTHON$($V.Replace('.',''))_EXE}
    Write-Host "==> Usando Python para build: $pythonExe ($V)"
    cmake -B $BUILD_SUBDIR -DPYVERSION="$V" -DPYTHON_EXECUTABLE="$pythonExe" -DPD_SDK_LIBDIR=$PD_SDK_LIBDIR -DPD_SDK_INCLUDEDIR=$PD_SDK_INCLUDEDIR
    cmake --build $BUILD_SUBDIR

    $bins = Get-ChildItem "$BUILD_SUBDIR\py4pd.*" -ErrorAction SilentlyContinue
    if ($bins.Count -eq 0) {
        Write-Host "   !! Binário não encontrado para Python $V"
        exit 1
    }
    foreach ($bin in $bins) {
        $dest = "$DIST_DIR\py4pd-$V$($bin.Extension)"
        Copy-Item $bin.FullName $dest
        Write-Host "   -> Binário copiado para $dest"
    }
}

Write-Host "==> Build finalizado com sucesso!"