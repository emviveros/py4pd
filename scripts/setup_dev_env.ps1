# =============================================================================
#
# Script de Setup do Ambiente de Desenvolvimento para py4pd no Windows
#
# Objetivo: Automatizar completamente a configuração do ambiente de build
#           para C/C++ e Python, sem intervenção manual.
#
# O que ele faz:
# 1.  Verifica se está sendo executado como Administrador.
# 2.  Detecta a arquitetura do sistema (x64, x86, arm64).
# 3.  Instala o gerenciador de pacotes Chocolatey, se não estiver presente.
# 4.  Usa o Chocolatey para instalar as dependências de build:
#     - CMake (sistema de build)
#     - MinGW-w64 (compilador C/C++)
# 5.  Busca a versão mais recente do 'uv' (gerenciador de ambiente Python)
#     diretamente da API do GitHub.
# 6.  Baixa o binário 'uv.exe' correto para a arquitetura do sistema.
# 7.  Usa 'uv' para criar um ambiente Python virtual (.venv) com a versão
#     especificada (ex: Python 3.11).
# 8.  Instala as dependências Python listadas em 'requirements.txt'.
# 9.  Fornece logs claros em cada etapa do processo.
#
# Como usar:
# 1.  Abra o PowerShell como Administrador.
# 2.  Navegue até o diretório raiz do projeto py4pd.
# 3.  Execute o comando: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
# 4.  Execute o script: .\scripts\setup_dev_env.ps1
#
# =============================================================================

# --- Início do Script ---
Write-Host "[INFO] INICIANDO SCRIPT DE SETUP (PowerShell)" -ForegroundColor Green

# --- Etapa 1: Validação de Permissões ---
Write-Host "[INFO] Etapa 1: Verificando permissões de administrador..." -ForegroundColor Green
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERRO] Este script precisa ser executado com privilégios de Administrador." -ForegroundColor Red
    Write-Host "Por favor, abra um novo terminal PowerShell como Administrador e execute o script novamente."
    exit 1
}
Write-Host "[INFO] Permissões de administrador validadas."

# --- Etapa 2: Detectar Arquitetura e Definir Variáveis ---
Write-Host "[INFO] Etapa 2: Detectando arquitetura do sistema..." -ForegroundColor Green
$repoRoot = $PSScriptRoot | Split-Path -Parent
$uvDir = Join-Path $env:USERPROFILE ".local\bin"
$uvExe = Join-Path $uvDir "uv.exe"
$arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { "x86_64" }
    "x86" { "x86" }
    "ARM64" { "aarch64" } # GitHub usa 'aarch64' para ARM64
    default {
        Write-Host "[ERRO] Arquitetura não reconhecida: $($env:PROCESSOR_ARCHITECTURE)" -ForegroundColor Red
        exit 1
    }
}
Write-Host "[DEBUG] Arquitetura detectada: $arch"

# Trata o caso de Windows 32 bits (x86)
if ($arch -eq "x86") {
    Write-Host "[AVISO] A ferramenta 'uv' não oferece mais suporte oficial para Windows 32-bit (x86)." -ForegroundColor Yellow
    Write-Host "[INFO] O script tentará usar o Python instalado no sistema via winget como alternativa." -ForegroundColor Cyan
    # Instalar Python 3.11 via winget
    try {
        winget install --id Python.Python.3.11 -e --silent --accept-source-agreements --accept-package-agreements
        Write-Host "[INFO] Python 3.11 instalado. Criando ambiente virtual com 'venv'..." -ForegroundColor Green
        python -m venv (Join-Path $repoRoot ".venv")
        $pipExe = Join-Path $repoRoot ".venv\Scripts\pip.exe"
        & $pipExe install -r (Join-Path $repoRoot "Documentation\requirements.txt")
        Write-Host "[INFO] Ambiente configurado com sucesso usando Python do sistema." -ForegroundColor Green
        exit 0
    } catch {
        Write-Host "[ERRO] Falha ao configurar o ambiente para x86. Instale Python 3.11 manualmente." -ForegroundColor Red
        exit 1
    }
}

# --- Etapa 3: Instalar Chocolatey se necessário ---
Write-Host "[INFO] Etapa 3: Verificando e instalando Chocolatey..." -ForegroundColor Green
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] Chocolatey não encontrado. Instalando..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "[ERRO] Falha ao instalar o Chocolatey." -ForegroundColor Red
        exit 1
    }
    Write-Host "[INFO] Chocolatey instalado com sucesso." -ForegroundColor Green
} else {
    Write-Host "[INFO] Chocolatey já está instalado."
}

# --- Etapa 4: Instalar CMake e MinGW ---
Write-Host "[INFO] Etapa 4: Instalando dependências de build (CMake, MinGW)..." -ForegroundColor Green
$packages = @(
    @{ Name = "CMake"; Command = "cmake" },
    @{ Name = "MinGW"; Command = "gcc" }
)

foreach ($pkg in $packages) {
    if (-not (Get-Command $pkg.Command -ErrorAction SilentlyContinue)) {
        Write-Host "[INFO] Instalando $($pkg.Name) via Chocolatey..." -ForegroundColor Cyan
        choco install $pkg.Name.ToLower() -y --no-progress
        
        # O Chocolatey pode não atualizar o PATH da sessão atual a tempo.
        # Em vez de usar 'refreshenv' (que pode falhar se 'wmic' não estiver disponível),
        # vamos localizar o executável e adicionar seu diretório ao PATH da sessão manualmente.
        # Após a instalação, o PATH pode não ser atualizado na sessão atual.
        # Abordagem final e mais robusta: busca exaustiva pelo executável.
        # Isso é mais lento, mas garante que o compilador seja encontrado
        # independentemente de onde o Chocolatey o instalou.
        Write-Host "[INFO] Nenhuma das abordagens padrão para localizar '$($pkg.Command)' funcionou. Iniciando busca exaustiva em C:\ ..." -ForegroundColor Yellow
        $foundPath = $null
        
        try {
            $executable = Get-ChildItem -Path "C:\" -Filter ($pkg.Command + ".exe") -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -First 1
            if ($executable) {
                $foundPath = $executable.DirectoryName
                Write-Host "[DEBUG] Executável encontrado em '$foundPath'."
                Write-Host "[INFO] Adicionando '$foundPath' ao PATH da sessão." -ForegroundColor Cyan
                $env:Path = "$foundPath;$($env:Path)"
            } else {
                Write-Warning "[AVISO] Busca exaustiva em C:\ não encontrou '$($pkg.Command)'. A verificação de comando subsequente provavelmente falhará."
            }
        } catch {
            Write-Error "[ERRO] Ocorreu um erro durante a busca exaustiva por '$($pkg.Command)'. Detalhes: $($_.Exception.Message)"
        }

        if (-not (Get-Command $pkg.Command -ErrorAction SilentlyContinue)) {
            Write-Host "[ERRO] Falha ao instalar ou encontrar o $($pkg.Name) após a instalação e a tentativa de atualização do PATH." -ForegroundColor Red
            Write-Host "[DICA] Verifique o log do Chocolatey: C:\ProgramData\chocolatey\logs\chocolatey.log. Tente fechar e reabrir o terminal."
            exit 1
        }
        Write-Host "[INFO] $($pkg.Name) instalado e verificado com sucesso." -ForegroundColor Green
    } else {
        Write-Host "[INFO] $($pkg.Name) já está instalado."
    }
}

# --- Etapa 5: Instalar 'uv' pelo instalador oficial ---
Write-Host "[INFO] Etapa 5: Instalando 'uv' via instalador oficial..." -ForegroundColor Green

# Verifica se o uv.exe já existe e está funcional
if (Test-Path $uvExe) {
    try {
        & $uvExe --version | Out-Null
        Write-Host "[INFO] 'uv' já está instalado em '$uvExe'."
    } catch {
        Write-Host "[AVISO] 'uv.exe' encontrado, mas não está funcional. Reinstalando..." -ForegroundColor Yellow
        Remove-Item $uvExe -Force
        powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    }
} else {
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
}

# Garante que o diretório do uv está no PATH
$env:PATH = "$uvDir;$($env:PATH)"
Write-Host "[DEBUG] Diretório '$uvDir' adicionado ao PATH da sessão."

# --- Etapa 6: Configurar Ambiente Python com 'uv' ---
Write-Host "[INFO] Etapa 6: Configurando ambiente Python com 'uv'..." -ForegroundColor Green
$pythonVersion = "3.11"
$venvDir = Join-Path $repoRoot ".venv"
$pyprojectFile = Join-Path $repoRoot "pyproject.toml"
$lockFile = Join-Path $repoRoot "uv.lock"

# --- Detecção e encerramento de processos bloqueando .venv ---
if (Test-Path $venvDir) {
    Write-Host "[INFO] Ambiente virtual existente detectado em '$venvDir'. Verificando processos que possam estar bloqueando..." -ForegroundColor Yellow

    $processNames = @("python.exe", "uv.exe", "pip.exe")
    $blockedPids = @()
    $blockedProcs = @()

    # Tenta usar Sysinternals Handle se disponível para detecção precisa
    $handleExe = "handle.exe"
    $handleCmd = Get-Command $handleExe -ErrorAction SilentlyContinue
    if ($handleCmd) {
        $handlePath = $handleCmd.Source
        Write-Host "[DEBUG] Utilizando Sysinternals Handle para detecção de bloqueio..." -ForegroundColor Cyan
        $handleOutput = & $handleExe $venvDir 2>&1
        foreach ($line in $handleOutput) {
            if ($line -match "pid: (\d+)") {
                $pid = $matches[1]
                $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
                if ($proc -and $processNames -contains $proc.Name.ToLower() + ".exe") {
                    $blockedPids += $pid
                    $blockedProcs += $proc
                }
            }
        }
    } else {
        Write-Host "[DEBUG] Sysinternals Handle não encontrado. Usando fallback por caminho e nome de processo..." -ForegroundColor Yellow
        foreach ($proc in Get-Process | Where-Object { $processNames -contains ($_.Name.ToLower() + ".exe") }) {
            try {
                $procModules = $proc.Modules | Where-Object { $_.FileName -like "$venvDir*" }
                if ($procModules) {
                    $blockedPids += $proc.Id
                    $blockedProcs += $proc
                }
            } catch {}
        }
    }

    if ($blockedPids.Count -gt 0) {
        Write-Host "[AVISO] Encontrados processos bloqueando arquivos em .venv:" -ForegroundColor Yellow
        foreach ($proc in $blockedProcs) {
            Write-Host ("    - {0} (PID {1})" -f $proc.Name, $proc.Id) -ForegroundColor Magenta
            try {
                Stop-Process -Id $proc.Id -Force
                Write-Host ("    [OK] Processo encerrado: {0} (PID {1})" -f $proc.Name, $proc.Id) -ForegroundColor Green
            } catch {
                Write-Host ("    [ERRO] Falha ao encerrar {0} (PID {1}): {2}" -f $proc.Name, $proc.Id, $_.Exception.Message) -ForegroundColor Red
            }
        }
        Start-Sleep -Seconds 2
    } else {
        Write-Host "[INFO] Nenhum processo bloqueando arquivos em .venv detectado." -ForegroundColor Green
    }

    Write-Host "[INFO] Removendo .venv..." -ForegroundColor Yellow
    try {
        Remove-Item $venvDir -Recurse -Force -ErrorAction Stop
        Write-Host "[INFO] Ambiente virtual removido com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "[ERRO] Falha ao remover '$venvDir'. Detalhes: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[DICA] Verifique se algum processo está usando arquivos dentro de .venv e tente novamente." -ForegroundColor Yellow
        exit 1
    }
}

try {
    Write-Host "[INFO] Criando ambiente virtual em '$venvDir' com Python $pythonVersion..." -ForegroundColor Cyan
    & $uvExe venv --python $pythonVersion $venvDir
    Write-Host "[INFO] Ambiente virtual criado." -ForegroundColor Green

    # Validar pyvenv.cfg
    $pyvenvCfg = Join-Path $venvDir "pyvenv.cfg"
    if (-not (Test-Path $pyvenvCfg)) {
        Write-Host "[ERRO] Ambiente virtual criado, mas 'pyvenv.cfg' está ausente. Ambiente corrompido." -ForegroundColor Red
        exit 1
    } else {
        Write-Host "[INFO] 'pyvenv.cfg' detectado. Ambiente virtual íntegro." -ForegroundColor Green
    }

    if (Test-Path $lockFile) {
        Write-Host "[INFO] Detectado uv.lock - sincronizando dependências..." -ForegroundColor Cyan
        & $uvExe pip sync $lockFile
        Write-Host "[INFO] Dependências sincronizadas com sucesso via uv.lock" -ForegroundColor Green
    } else {
        Write-Host "[INFO] uv.lock não encontrado - instalando dependências do pyproject.toml..." -ForegroundColor Cyan
        & $uvExe pip install --requirements $pyprojectFile
        Write-Host "[INFO] Dependências instaladas com sucesso via pyproject.toml" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERRO] Falha ao configurar o ambiente Python com 'uv'. Detalhes: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# --- Etapa 7: Automação Pure Data SDK (x64/x86) ---
Write-Host "[INFO] Etapa 7: Baixando e organizando SDK do Pure Data..." -ForegroundColor Green

$pdSdkDir = Join-Path $repoRoot "pd_sdk"
$pdIncludeDir = Join-Path $pdSdkDir "include"
$pdLibDir_x64 = Join-Path $pdSdkDir "lib\x64"
$pdLibDir_x86 = Join-Path $pdSdkDir "lib\x86"

foreach ($dir in @($pdSdkDir, $pdIncludeDir, $pdLibDir_x64, $pdLibDir_x86)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

# Obter última release estável do Pure Data
$releaseApi = "https://api.github.com/repos/pure-data/pure-data/releases/latest"
try {
    $releaseInfo = Invoke-RestMethod -Uri $releaseApi -ErrorAction Stop
    $assets = $releaseInfo.assets

    $archMap = @{
        "x64" = "windows-x64.msw.zip"
        "x86" = "windows.msw.zip"
    }

    foreach ($archKey in $archMap.Keys) {
        $zipName = $archMap[$archKey]
        $asset = $assets | Where-Object { $_.name -eq $zipName }
        if ($asset) {
            $zipPath = Join-Path $pdSdkDir $zipName
            if (-not (Test-Path $zipPath)) {
                Write-Host "[INFO] Baixando $zipName..." -ForegroundColor Cyan
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -ErrorAction Stop
            } else {
                Write-Host "[INFO] $zipName já existe. Pulando download."
            }

            # Extrair arquivos necessários
            $extractDir = Join-Path $pdSdkDir "tmp_$archKey"
            if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
            Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

            # Copiar pd.dll e pd.lib
            $dllSrc = Get-ChildItem -Path $extractDir -Recurse -Filter "pd.dll" | Select-Object -First 1
            $libSrc = Get-ChildItem -Path $extractDir -Recurse -Filter "pd.lib" | Select-Object -First 1
            $libDest = if ($archKey -eq "x64") { $pdLibDir_x64 } else { $pdLibDir_x86 }

            if ($dllSrc -and (-not (Test-Path (Join-Path $libDest "pd.dll")))) {
                Copy-Item $dllSrc.FullName (Join-Path $libDest "pd.dll") -Force
                Write-Host "[INFO] pd.dll copiado para $libDest"
            } else {
                Write-Host "[INFO] pd.dll já existe em $libDest. Pulando cópia."
            }
            if ($libSrc -and (-not (Test-Path (Join-Path $libDest "pd.lib")))) {
                Copy-Item $libSrc.FullName (Join-Path $libDest "pd.lib") -Force
                Write-Host "[INFO] pd.lib copiado para $libDest"
            } else {
                Write-Host "[INFO] pd.lib já existe em $libDest. Pulando cópia."
            }

            # Copiar m_pd.h para include (apenas uma vez, x64 tem prioridade)
            $hSrc = Get-ChildItem -Path $extractDir -Recurse -Filter "m_pd.h" | Select-Object -First 1
            if ($hSrc -and (-not (Test-Path (Join-Path $pdIncludeDir "m_pd.h")))) {
                Copy-Item $hSrc.FullName (Join-Path $pdIncludeDir "m_pd.h") -Force
                Write-Host "[INFO] m_pd.h copiado para $pdIncludeDir"
            } elseif (Test-Path (Join-Path $pdIncludeDir "m_pd.h")) {
                Write-Host "[INFO] m_pd.h já existe em $pdIncludeDir. Pulando cópia."
            }

            # Remover temporários
            Remove-Item $extractDir -Recurse -Force
        } else {
            Write-Host "[AVISO] Asset $zipName não encontrado na release. Baixe manualmente se necessário." -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "[ERRO] Falha ao acessar a API de releases do Pure Data: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[DICA] Baixe manualmente os arquivos .msw.zip da página de releases: https://github.com/pure-data/pure-data/releases/latest" -ForegroundColor Yellow
}

# Configurar variáveis de ambiente para build conforme arquitetura
if ($arch -eq "x86_64") {
    $env:PD_SDK_LIBDIR = $pdLibDir_x64
} elseif ($arch -eq "x86") {
    $env:PD_SDK_LIBDIR = $pdLibDir_x86
}
$env:PD_SDK_INCLUDEDIR = $pdIncludeDir

Write-Host "--------------------------------------------------" -ForegroundColor Yellow
Write-Host "[SUCESSO] SDK Pure Data baixado, extraído e organizado em pd_sdk/" -ForegroundColor Green
Write-Host "Arquiteturas: x64 e x86"
Write-Host "Include: $pdIncludeDir"
Write-Host "Lib x64: $pdLibDir_x64"
Write-Host "Lib x86: $pdLibDir_x86"
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Cyan
Write-Host "1. Compile usando as variáveis de ambiente PD_SDK_LIBDIR e PD_SDK_INCLUDEDIR."
Write-Host "2. Siga as instruções de build do projeto."
Write-Host "--------------------------------------------------" -ForegroundColor Yellow

exit 0