@echo off
setlocal

echo ==[ py4pd :: Setup do ambiente de desenvolvimento (Windows) ]==

where uv >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo -> 'uv' não encontrado. Instalando via script oficial...
    curl -Ls https://astral.sh/uv/install.ps1 -o "%TEMP%\uv_install.ps1"
    powershell -ExecutionPolicy Bypass -File "%TEMP%\uv_install.ps1"
    set PATH=%USERPROFILE%\.local\bin;%PATH%
) else (
    echo -> 'uv' já está instalado.
)

uv pip --python 3.11 --version >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo -> Python 3.11 já disponível via uv.
) else (
    echo -> Instalando Python 3.11 via uv...
    uv pip --python 3.11 --version >nul
)

uv pip --python 3.12 --version >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo -> Python 3.12 já disponível via uv.
) else (
    echo -> Instalando Python 3.12 via uv...
    uv pip --python 3.12 --version >nul
)

echo ==[ Ambiente de desenvolvimento pronto! ]==
endlocal