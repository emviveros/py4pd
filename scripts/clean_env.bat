@echo off
echo ==[ Limpando ambiente de desenvolvimento py4pd ]==

REM Remove o ambiente virtual local
if exist .venv rmdir /s /q .venv

REM Remove a pasta de build
if exist build rmdir /s /q build

REM Remove o cache global do uv (Python e pacotes)
if exist "%USERPROFILE%\.uv" rmdir /s /q "%USERPROFILE%\.uv"

REM Remove o binário do uv
if exist "%USERPROFILE%\.local\bin\uv.exe" del "%USERPROFILE%\.local\bin\uv.exe"

REM Remove MinGW-w64 instalado via Chocolatey
REM Remove o diretório padrão do pacote Chocolatey
if exist "C:\ProgramData\chocolatey\lib\mingw" rmdir /s /q "C:\ProgramData\chocolatey\lib\mingw"
REM Remove o diretório padrão do MinGW-w64 do pacote
if exist "C:\ProgramData\mingw64" rmdir /s /q "C:\ProgramData\mingw64"

REM Remove CMake instalado via winget
where cmake >nul 2>nul
if not errorlevel 1 (
    echo Desinstalando CMake via winget...
    winget uninstall --id Kitware.CMake -e --silent
    REM Remove diretórios residuais do CMake
    if exist "%ProgramFiles%\CMake" rmdir /s /q "%ProgramFiles%\CMake"
    if exist "%ProgramFiles(x86)%\CMake" rmdir /s /q "%ProgramFiles(x86)%\CMake"
)

REM Remove Chocolatey (opcional, pois pode ser usado por outros projetos)
REM Para limpeza total, desinstale via powershell:
where choco >nul 2>nul
if not errorlevel 1 (
    echo Desinstalando Chocolatey...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Remove-Item -Recurse -Force 'C:\ProgramData\chocolatey'"
)

echo.
echo ✅ Ambiente limpo com sucesso!
echo Agora você pode executar o script de setup novamente.

exit /b