:: Criação dinâmica dos placeholders do bundle moderno do py4pd (Windows)
:: ATENÇÃO: Build para arm64 NÃO é suportado no Windows. Apenas x64/x86.
if not exist dist mkdir dist
type nul > dist\py4pd.dll
type nul > dist\py4pd.pd_linux
type nul > dist\py4pd.pd_darwin
type nul > dist\py4pd-py3.11.dll
type nul > dist\py4pd-py3.12.dll
type nul > dist\py4pd-bootstrap.sh
(
echo # py4pd - Estrutura do Bundle Moderno (placeholders)
echo.
echo Este diretório contém arquivos gerados dinamicamente para o bundle moderno do py4pd.
echo Todos os arquivos abaixo são placeholders (vazios) e servem apenas para ilustrar a estrutura de distribuição.
echo.
echo - py4pd.dll           Loader C para Pure Data no Windows
echo - py4pd.pd_linux      Loader C para Pure Data no Linux
echo - py4pd.pd_darwin     Loader C para Pure Data no macOS
echo - py4pd-py3.11.dll    Binário real do py4pd para Python 3.11
echo - py4pd-py3.12.dll    Binário real do py4pd para Python 3.12
echo - py4pd-bootstrap.sh  Script de bootstrap multiplataforma
echo.
echo Estes arquivos são placeholders e não possuem implementação funcional.
) > dist\README.txt
@echo off
setlocal enabledelayedexpansion
call "%~dp0env_vars.bat"
set PY_VERSIONS=3.11 3.12
set ROOT_DIR=%~dp0..
cd /d %ROOT_DIR%

echo ==^> Limpando diretórios build\ e dist\
rmdir /s /q build 2>nul
rmdir /s /q dist 2>nul
mkdir dist

for %%V in (%PY_VERSIONS%) do (
    set "BUILD_DIR=build\py%%V"
    echo ==^> Compilando para Python %%V
    mkdir "!BUILD_DIR!" 2>nul
    cmake -B "!BUILD_DIR!" -DPY4PD_PYTHON_VERSION=%%V -DPD_SDK_LIBDIR=%PD_SDK_LIBDIR% -DPD_SDK_INCLUDEDIR=%PD_SDK_INCLUDEDIR%
    cmake --build "!BUILD_DIR!"
    set "FOUND="
    for %%F in (!BUILD_DIR!\py4pd.*) do (
        copy "%%F" "dist\py4pd-%%V%%~xF" >nul
        echo   -> Binário copiado para dist\py4pd-%%V%%~xF
        set "FOUND=1"
        goto :found
    )
    if not defined FOUND (
        echo   !! Binário não encontrado para Python %%V
        exit /b 1
    )
    :found
)

echo ==^> Build finalizado com sucesso!
endlocal