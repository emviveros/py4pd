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
# 10. Verifica e extrai todos os arquivos essenciais do SDK do Pure Data,
#     incluindo m_pd.h e g_canvas.h, garantindo que estejam presentes em pd_sdk/include.
#     Se qualquer arquivo estiver faltando, o ZIP é extraído e os cabeçalhos são copiados.
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
# Define uv do bundle
$uvExe = Join-Path $repoRoot "Resources\uv\uv-windows.exe"
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

# --- Definição dos Caminhos do SDK do Pure Data ---
$pdSdkDir = Join-Path $repoRoot "pd_sdk"
$pdIncludeDir = Join-Path $pdSdkDir "include"

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
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
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

# --- Etapa 5: Usando uv embutido no bundle ---
Write-Host "[INFO] Etapa 5: Usando 'uv' embutido do bundle..." -ForegroundColor Green

if (-not (Test-Path $uvExe)) {
    Write-Host "[ERRO] uv embutido não encontrado em '$uvExe'. Certifique-se que o bundle está completo." -ForegroundColor Red
    exit 1
}

try {
    & $uvExe --version | Out-Null
    Write-Host "[INFO] 'uv' embutido encontrado e funcional em '$uvExe'."
} catch {
    Write-Host "[ERRO] 'uv' embutido não está funcional. Verifique o bundle." -ForegroundColor Red
    exit 1
}

# --- Etapa 6: Configurar Ambiente Python com 'uv' ---
Write-Host "[INFO] Etapa 6: Configurando ambiente Python com 'uv'..." -ForegroundColor Green
# Multi-venv para múltiplas versões de Python
$PY_VERSIONS = @("3.11", "3.12")
$pyprojectFile = Join-Path $repoRoot "pyproject.toml"
$lockFile = Join-Path $repoRoot "uv.lock"
$envVarsBat = Join-Path $repoRoot "scripts\env_vars.bat"

# Detecta arquitetura para nomear diretórios de Python
$archShort = switch ($arch) {
    "x86_64" { "x64" }
    "aarch64" { "arm64" }
    default { $arch }
}

Write-Host "[DEBUG] Arquitetura detectada: arch='$arch', archShort='$archShort'" -ForegroundColor Magenta

# --- Preparação do env_vars.bat ---
Write-Host "[INFO] Inicializando 'scripts\env_vars.bat' para o script de build..." -ForegroundColor Cyan
if (Test-Path $envVarsBat) { Remove-Item $envVarsBat }
Set-Content -Path $envVarsBat -Value "@echo off"
Add-Content -Path $envVarsBat -Value "echo [INFO] Variáveis de ambiente para build configuradas por setup_dev_env.ps1"

# Adiciona MinGW ao PATH do script de build
$gccPath = (Get-Command gcc.exe -ErrorAction SilentlyContinue).Source
if ($gccPath) {
    $mingwDir = Split-Path $gccPath -Parent
    Add-Content -Path $envVarsBat -Value "set PATH=$mingwDir;%PATH%"
}

# --- Loop de Criação dos Ambientes Python usando uv no padrão global ---
foreach ($V in $PY_VERSIONS) {
    $venvDir = Join-Path $repoRoot ".venv-$V"

    # Remove ambiente antigo se existir
    if (Test-Path $venvDir) {
        Write-Host "[INFO] Removendo ambiente virtual antigo '$venvDir'..." -ForegroundColor Yellow
        Remove-Item $venvDir -Recurse -Force
    }

    Write-Host "[INFO] Instalando Python $V via uv (cache global)..." -ForegroundColor Cyan
    & $uvExe python install $V

    Write-Host "[INFO] Criando ambiente virtual para Python $V em '$venvDir'..." -ForegroundColor Cyan
    & $uvExe venv -p $V $venvDir

    if (-not (Test-Path (Join-Path $venvDir "pyvenv.cfg"))) {
        Write-Host "[ERRO] Falha ao criar ambiente para Python $V." -ForegroundColor Red
        exit 1
    }
    Write-Host "[INFO] Ambiente virtual para Python $V criado com sucesso."

    # Define VIRTUAL_ENV para que o uv global saiba onde instalar
    $oldVirtualEnv = $env:VIRTUAL_ENV
    $env:VIRTUAL_ENV = $venvDir

    try {
        if (Test-Path $lockFile) {
            Write-Host "[INFO] Instalando dependências de 'uv.lock' para Python $V..." -ForegroundColor Cyan
            & $uvExe pip sync $lockFile
        } elseif (Test-Path $pyprojectFile) {
            Write-Host "[INFO] Instalando dependências de 'pyproject.toml' para Python $V..." -ForegroundColor Cyan
            & $uvExe pip install -r $pyprojectFile
        } else {
            Write-Host "[AVISO] Nenhum arquivo de dependência (uv.lock, pyproject.toml) encontrado." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[ERRO] Falha ao instalar dependências para Python $V. Detalhes: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        $env:VIRTUAL_ENV = $oldVirtualEnv
    }

    # Descobre o Python home real a partir do pyvenv.cfg
    $pyvenvCfgPath = Join-Path $venvDir "pyvenv.cfg"
    $pythonHomeDir = $null
    if (Test-Path $pyvenvCfgPath) {
        try {
            $pythonHomeDir = Get-Content $pyvenvCfgPath | Where-Object { $_ -match "^home\s*=\s*(.*)" } | ForEach-Object { $matches[1].Trim() }
        } catch {
            Write-Warning "[AVISO] Não foi possível ler o pyvenv.cfg para a versão $V."
        }
    }

    $pythonExe = Join-Path $venvDir "Scripts\python.exe"
    $pyIncludeDir = if ($pythonHomeDir) { Join-Path $pythonHomeDir "Include" } else { "" }
    $pyLibDir = if ($pythonHomeDir) { Join-Path $pythonHomeDir "libs" } else { "" }
    $pyLibFile = if ($pyLibDir -ne "") { Get-ChildItem -Path $pyLibDir -Filter "python$($V.Replace('.',''))*.lib" -ErrorAction SilentlyContinue | Select-Object -First 1 } else { $null }

    # === DEBUG: Log de todas as variáveis antes da geração ===
    # Write-Host "[DEBUG] === Variáveis para Python $V ===" -ForegroundColor Magenta
    # Write-Host "[DEBUG] V = '$V'" -ForegroundColor Magenta
    # Write-Host "[DEBUG] arch = '$arch'" -ForegroundColor Magenta
    # Write-Host "[DEBUG] archShort = '$archShort'" -ForegroundColor Magenta
    # Write-Host "[DEBUG] pythonExe = '$pythonExe'" -ForegroundColor Magenta
    # Write-Host "[DEBUG] pythonHomeDir = '$pythonHomeDir'" -ForegroundColor Magenta
    # Write-Host "[DEBUG] pyIncludeDir = '$pyIncludeDir'" -ForegroundColor Magenta
    # Write-Host "[DEBUG] pyLibDir = '$pyLibDir'" -ForegroundColor Magenta
    # Write-Host "[DEBUG] pyLibFile = '$($pyLibFile.FullName)'" -ForegroundColor Magenta
    # Write-Host "[DEBUG] envVarsBat = '$envVarsBat'" -ForegroundColor Magenta
    
    # Testa interpolação de strings para debug
    $testVarName = "PYTHON${V.Replace('.','')}_${archShort}_EXE"
    Write-Host "[DEBUG] Nome da variável seria: '$testVarName'" -ForegroundColor Magenta

    # Exporta variáveis específicas por versão (ex: PYTHON311_x64_EXE)
    $versionSuffix = $V.Replace('.', '')
    $varPrefix = "PYTHON$versionSuffix" + "_$archShort"
    
    Add-Content -Path $envVarsBat -Value "set ${varPrefix}_EXE=$pythonExe"
    Add-Content -Path $envVarsBat -Value "set ${varPrefix}_ROOT=$pythonHomeDir"
    Add-Content -Path $envVarsBat -Value "set ${varPrefix}_INCLUDE=$pyIncludeDir"
    if ($pyLibFile) {
        Add-Content -Path $envVarsBat -Value "set ${varPrefix}_LIB=$($pyLibFile.FullName)"
    } else {
        Add-Content -Path $envVarsBat -Value "set ${varPrefix}_LIB="
        Write-Warning "[AVISO] Biblioteca .lib não encontrada para Python $V em $pyLibDir"
    }

    # Nota: Removemos a geração de variáveis genéricas PYTHON_x64_* pois causavam sobrescrita.
    # O script de build agora usa apenas as variáveis específicas por versão (PYTHON311_x64_*, PYTHON312_x64_*, etc.)
    Write-Host "[INFO] Variáveis de ambiente para Python $V ($archShort) adicionadas a env_vars.bat" -ForegroundColor Green
}

# --- Copiar includes do Python (Python.h) para pd_sdk/include/<versao> ---
Write-Host "[INFO] Copiando headers do Python para o SDK do Pure Data..." -ForegroundColor Green
foreach ($V in $PY_VERSIONS) {
    $venvDir = Join-Path $repoRoot ".venv-$V"
    $pyvenvCfgPath = Join-Path $venvDir "pyvenv.cfg"
    $pythonHomeDir = $null

    if (Test-Path $pyvenvCfgPath) {
        try {
            # Extrai o caminho 'home' do pyvenv.cfg para encontrar a instalação real do Python
            $pythonHomeDir = Get-Content $pyvenvCfgPath | Where-Object { $_ -match "^home\s*=\s*(.*)" } | ForEach-Object { $matches[1].Trim() }
        } catch {
            Write-Warning "[AVISO] Não foi possível ler o pyvenv.cfg para a versão $V."
        }
    }

    if ($pythonHomeDir) {
        $pythonIncludeDir = Join-Path $pythonHomeDir "Include"
        $pyIncludeVersionDir = Join-Path $pdIncludeDir "python$V"
    
        if (Test-Path $pythonIncludeDir) {
            # Garante que o diretório de destino exista
            if (-not (Test-Path $pyIncludeVersionDir)) {
                New-Item -ItemType Directory -Path $pyIncludeVersionDir -Force | Out-Null
            }
    
            # Copia os arquivos .h
            $files = Get-ChildItem -Path $pythonIncludeDir -Filter "*.h" -File
            foreach ($file in $files) {
                Copy-Item $file.FullName $pyIncludeVersionDir -Force
            }
            Write-Host "[INFO] Headers do Python ($V) copiados de '$pythonIncludeDir' para '$pyIncludeVersionDir'"
        } else {
            Write-Warning "[AVISO] Diretório de includes do Python não encontrado na instalação base para a versão $V em '$pythonIncludeDir'."
        }
    } else {
        Write-Warning "[AVISO] Não foi possível determinar o diretório 'home' do Python para a versão $V. Os headers não serão copiados."
    }
}

# --- Etapa 7: Automação Pure Data SDK (x64/x86) ---
Write-Host "[INFO] Etapa 7: Baixando e organizando SDK do Pure Data..." -ForegroundColor Green

$pdLibDir_x64 = Join-Path $pdSdkDir "lib\x64"
$pdLibDir_x86 = Join-Path $pdSdkDir "lib\x86"

# Adiciona caminhos do SDK do Pd ao env_vars.bat
Add-Content -Path $envVarsBat -Value "set PD_SDK_INCLUDE_DIR=$pdIncludeDir"
Add-Content -Path $envVarsBat -Value "set PD_SDK_LIB_DIR_X64=$pdLibDir_x64"
Add-Content -Path $envVarsBat -Value "set PD_SDK_LIB_DIR_X86=$pdLibDir_x86"

foreach ($dir in @($pdSdkDir, $pdIncludeDir, $pdLibDir_x64, $pdLibDir_x86)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

# Baixar binários do Pure Data diretamente do site oficial (UCSD) - versão dinâmica
$baseUrl = "https://msp.ucsd.edu/Software"

Write-Host "[INFO] Buscando versão estável mais recente do Pure Data..." -ForegroundColor Cyan
try {
    $html = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing
    $links = $html.Links | Where-Object { $_.href -match "\.msw\.zip$" -and $_.href -notmatch "test" }
    $files = $links | ForEach-Object { $_.href }

    # Extrai versões e filtra nomes válidos
    $versionRegex = "pd-(\d+\.\d+-\d+)"
    $versions = @()
    foreach ($file in $files) {
        if ($file -match $versionRegex) {
            $ver = $matches[1]
            $versions += [PSCustomObject]@{ File = $file; Version = $ver }
        }
    }

    # Ordena por versão (maior primeiro)
    # Ordena as versões convertendo para [System.Version] (substitui '-' por '.')
    foreach ($v in $versions) {
        $v | Add-Member -MemberType NoteProperty -Name VersionObj -Value ([System.Version]($v.Version -replace '-', '.'))
    }
    $latest = $versions | Sort-Object -Property VersionObj -Descending | Select-Object -First 1

    if (-not $latest) {
        throw "Nenhuma versão estável encontrada."
    }

    $latestVersion = $latest.Version
    Write-Host "[INFO] Versão mais recente detectada: $latestVersion" -ForegroundColor Green

    # Monta nomes dos arquivos
    $zipNames = @{
        "x64" = "pd-$latestVersion.msw.zip"
        "x86" = "pd-$latestVersion-i386.msw.zip"
    }

    foreach ($archKey in $zipNames.Keys) {
        $zipName = $zipNames[$archKey]
        $zipUrl = "$baseUrl/$zipName"
        $zipPath = Join-Path $pdSdkDir $zipName

        if (-not (Test-Path $zipPath)) {
            Write-Host "[INFO] Baixando $zipName de $zipUrl ..." -ForegroundColor Cyan
            try {
                Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -ErrorAction Stop
                Write-Host "[INFO] Download de $zipName concluído." -ForegroundColor Green
            } catch {
                Write-Host "[ERRO] Falha ao baixar $zipName de $zipUrl. Detalhes: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "[DICA] Baixe manualmente o arquivo em: $zipUrl" -ForegroundColor Yellow
                continue
            }
        } else {
            Write-Host "[INFO] $zipName já existe. Pulando download."
        }

        # Só extrai se algum dos arquivos binários ou cabeçalho estiver faltando E o zip existe
        $dllDest = if ($archKey -eq "x64") { Join-Path $pdLibDir_x64 "pd.dll" } else { Join-Path $pdLibDir_x86 "pd.dll" }
        $libDest = if ($archKey -eq "x64") { Join-Path $pdLibDir_x64 "pd.lib" } else { Join-Path $pdLibDir_x86 "pd.lib" }
        $headerNames = @(
            "g_all_guis.h",
            "g_canvas.h",
            "g_undo.h",
            "m_imp.h",
            "m_pd.h",
            "sched.h",
            "semaphore.h",
            "s_net.h",
            "s_stuff.h",
            "x_vexp.h"
        )
        $headerDests = $headerNames | ForEach-Object { Join-Path $pdIncludeDir $_ }

        $needExtract = $false
        if (-not (Test-Path $dllDest)) { $needExtract = $true }
        if (-not (Test-Path $libDest)) { $needExtract = $true }
        foreach ($dest in $headerDests) {
            if (-not (Test-Path $dest)) { $needExtract = $true }
        }

        if ($needExtract -and (Test-Path $zipPath)) {
            Write-Host "[INFO] Extraindo $zipName pois um ou mais arquivos do SDK estão faltando..." -ForegroundColor Cyan
            $extractDir = Join-Path $pdSdkDir "tmp_$archKey"
            if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
            Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

            # Copiar pd.dll e pd.lib
            $dllSrc = Get-ChildItem -Path $extractDir -Recurse -Filter "pd.dll" | Select-Object -First 1
            $libSrc = Get-ChildItem -Path $extractDir -Recurse -Filter "pd.lib" | Select-Object -First 1

            if ($dllSrc -and (-not (Test-Path $dllDest))) {
                Copy-Item $dllSrc.FullName $dllDest -Force
                Write-Host "[INFO] pd.dll copiado para $dllDest"
            }
            if ($libSrc -and (-not (Test-Path $libDest))) {
                Copy-Item $libSrc.FullName $libDest -Force
                Write-Host "[INFO] pd.lib copiado para $libDest"
            }
            
            # Função auxiliar para copiar cabeçalhos para a pasta include
            function Copy-HeaderFile {
                param(
                    [string]$HeaderName,
                    [string]$SourceDir,
                    [string]$DestDir
                )
                $headerDest = Join-Path $DestDir $HeaderName
                if (-not (Test-Path $headerDest)) {
                    $headerSrc = Get-ChildItem -Path $SourceDir -Recurse -Filter $HeaderName | Select-Object -First 1
                    if ($headerSrc) {
                        Copy-Item $headerSrc.FullName $headerDest -Force
                        Write-Host "[INFO] '$HeaderName' copiado para '$DestDir'."
                    }
                }
            }

            # Copiar cabeçalhos se não existirem
            foreach ($header in $headerNames) {
                Copy-HeaderFile -HeaderName $header -SourceDir $extractDir -DestDir $pdIncludeDir
            }

            # Remover temporários
            Remove-Item $extractDir -Recurse -Force
        } else {
            Write-Host "[INFO] Todos os arquivos do SDK já presentes para $archKey. Pulando extração de $zipName."
        }
    }
} catch {
    Write-Host "[ERRO] Falha ao buscar ou baixar Pure Data. Detalhes: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[DICA] Verifique sua conexão ou baixe manualmente os binários em $baseUrl" -ForegroundColor Yellow
}

# --- Etapa Final: Conclusão ---
Write-Host "--------------------------------------------------" -ForegroundColor Yellow
Write-Host "[SUCESSO] Script de setup concluído!" -ForegroundColor Green
Write-Host "Ambientes Python (3.11, 3.12) e SDK do Pure Data (x64, x86) estão prontos."
Write-Host "O arquivo 'scripts\env_vars.bat' foi gerado para o build."
Write-Host ""
Write-Host "Próximo passo:" -ForegroundColor Cyan
Write-Host "Execute o script de build: .\scripts\build_all.bat"
Write-Host "--------------------------------------------------" -ForegroundColor Yellow

exit 0