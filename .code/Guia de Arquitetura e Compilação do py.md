# Guia de Arquitetura e Compilação do py4pd

Este documento serve como um guia de referência completo para a arquitetura, funcionamento e processo de compilação do `py4pd`. O objetivo é fornecer uma visão clara e organizada do projeto em seu estado atual, facilitando tanto o uso quanto o desenvolvimento futuro.

## 1. Introdução: Python dentro do Pure Data

O `py4pd` é um "external" (uma extensão) para o Pure Data (Pd) que cria uma ponte poderosa entre o ambiente de programação visual do Pd e a versatilidade da linguagem Python.

Para um músico, artista ou desenvolvedor trabalhando no Pd, isso significa que você pode:

*   **Executar Scripts Python:** Carregar e rodar seus próprios scripts `.py` diretamente de um patch.
*   **Usar Bibliotecas Python:** Acessar o vasto ecossistema de bibliotecas Python (como NumPy, SciPy, etc.) para tarefas complexas como análise de dados, machine learning ou manipulação avançada de estruturas de dados.
*   **Criar Objetos Customizados:** Transformar uma função Python em um objeto Pd funcional, com inlets e outlets, sem precisar escrever uma única linha de C.

Em resumo, `py4pd` encapsula a complexidade da integração para que você possa focar em escrever a lógica em Python, enquanto interage com ela de forma nativa no Pd.

## 2. A Visão do Usuário no Pure Data

A interação com `py4pd` dentro de um patch do Pd é dividida em dois tipos principais de objetos:

1.  **O Objeto Gerenciador `[py4pd]`**: Este é o cérebro da operação. Ele é responsável por iniciar e gerenciar o interpretador Python. Você geralmente cria apenas um `[py4pd]` em seu patch. Ele aceita mensagens para configurar o ambiente:
    *   `[import <nome_do_modulo>(`: Carrega um módulo Python. Análogo a `import <nome_do_modulo>` em Python.
    *   `[from <modulo> import <objeto>[`: Importa um objeto específico (função, classe) de um módulo.
    *   `[path-append <caminho>[`: Adiciona um diretório ao `sys.path` do Python. Essencial para que o `py4pd` encontre seus scripts.
    *   `[path-remove <caminho>[`: Remove um diretório do `sys.path`.

2.  **Os Objetos de Script `[py.<funcao_python>]`**: Uma vez que seu módulo e suas funções foram importados usando o objeto `[py4pd]`, você pode instanciar qualquer função Python como um objeto Pd. Se seu script tem uma função chamada `process_list`, você pode criá-la no Pd como `[py.process_list]`.
    *   **Inlets**: Recebem mensagens do Pd (bangs, floats, listas).
    *   **Processamento**: A mensagem recebida é passada como argumento para sua função Python.
    *   **Outlets**: O valor retornado pela sua função Python é enviado para as saídas (outlets) do objeto, pronto para ser conectado a outros objetos Pd.

## 3. Arquitetura Interna: A Ponte em C

Embora a experiência do usuário seja em Python, o `py4pd` é, fundamentalmente, um external escrito em C. Ele atua como um tradutor entre as APIs do Pure Data e do Python.

### 3.1. Interação com a API do Pure Data (`m_pd.h`)

O `py4pd` utiliza funções padrão da API do Pd para se registrar e operar dentro do ambiente. As mais importantes são:

*   **`py4pd_setup()`** (definida em `Sources/py4pd_setup.c`): Esta é a função de inicialização que o Pd chama quando o external é carregado. É aqui que o `py4pd` se apresenta ao Pd.
    *   **`class_new()`**: Usada em `py4pd_setup()` para registrar as "classes" de objetos que o `py4pd` fornecerá: a classe principal `py4pd` e uma classe genérica `py` que serve de modelo para todos os objetos de script (`py.*`).
    *   **`class_addmethod()`**: Usada extensivamente em `py4pd_setup()` para mapear mensagens (seletores) para funções C. Quando você envia a mensagem `[import meu_script]` para o objeto `[py4pd]`, o Pd sabe que deve chamar a função C `py4pd_import()` (definida em `Sources/py4pd_python.c`) porque este mapeamento foi feito no setup.
    *   **`class_addbang()`, `class_addfloat()`, `class_addlist()`**: Funções especializadas usadas para registrar como o objeto deve reagir aos tipos de dados básicos do Pd. Elas direcionam os dados dos inlets para as funções C de despacho apropriadas (ex: `py_bang()` em `Sources/py4pd_dispatch.c`).

*   **`py4pd_new()`** (definida em `Sources/py4pd_new.c`): A função "construtora", chamada sempre que você cria um objeto `[py4pd]` ou `[py.*]` no patch. Ela aloca a memória necessária e cria os inlets e outlets do objeto usando `inlet_new()` e `outlet_new()`.

*   **Funções de Comunicação**:
    *   **`post()`**: Usada em várias partes do código para imprimir mensagens de log, depuração e erro na console do Pd.
    *   **`outlet_float()`, `outlet_symbol()`, `outlet_list()`, `outlet_bang()`**: Quando uma função Python retorna um resultado, o código C em `Sources/py4pd_dispatch.c` o converte de volta para um tipo de dado do Pd e o envia para o outlet correspondente usando uma dessas funções.

### 3.2. Interação com a API C do Python

Do outro lado da ponte, o código C do `py4pd` usa a API C do Python para:

*   **Inicializar o Interpretador**: `Py_Initialize()` e `Py_Finalize()` (chamadas em `Sources/py4pd_python.c`) são usados para iniciar e parar o ambiente Python.
*   **Converter Tipos de Dados**: Funções como `PyFloat_FromDouble()`, `PyList_New()`, `PyUnicode_FromString()` são usadas em `Sources/py4pd_dispatch.c` para converter dados vindos do Pd em objetos Python. Na direção oposta, `PyFloat_AsDouble()`, `PyList_GetItem()`, etc., são usados para converter os resultados de volta para tipos que o C e o Pd entendam.
*   **Chamar Funções Python**: O núcleo da operação, localizado em `Sources/py4pd_dispatch.c`, envolve obter uma referência à função Python do usuário (`PyObject_GetAttrString`) e chamá-la com os argumentos convertidos (`PyObject_CallObject`).

## 4. Preparando o Ambiente de Desenvolvimento Padronizado (Automatizado)


Antes de compilar, é fundamental garantir que todos os desenvolvedores usem as mesmas versões das ferramentas. Para simplificar radicalmente este processo, a abordagem recomendada é usar um script de setup que automatiza a preparação do ambiente, cuidando da instalação do `uv` e das versões do Python necessárias.

### 4.1. O Script de Setup Automatizado
\
A ideia é ter um único script, localizado na pasta `scripts/`, que qualquer desenvolvedor possa executar para ter seu ambiente 100% pronto para a compilação. Este script irá:
1.  Verificar se `uv` está instalado no sistema. Se não estiver, irá baixá-lo e instalá-lo automaticamente.
2.  Usar `uv` para verificar se as versões do Python necessárias para o projeto (ex: 3.11, 3.12) estão instaladas. Se não estiverem, irá baixá-las.

Isso elimina a necessidade de seguir passos manuais e garante consistência total entre todos os ambientes de desenvolvimento.

#### Exemplo de Script `scripts/setup_dev_env.sh` (Linux/macOS)

```bash
#!/bin/bash
set -e # Encerra se qualquer comando falhar

# --- Configuração ---
PYTHON_VERSIONS_TO_INSTALL=("3.11" "3.12")
# --------------------

# Verifica se o comando 'uv' existe
if ! command -v uv &> /dev/null
then
    echo "--- 'uv' não encontrado. Instalando uv... ---"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # Adiciona uv ao PATH da sessão atual para uso imediato
    source "$HOME/.cargo/env"
    echo "--- 'uv' instalado com sucesso. ---"
else
    echo "--- 'uv' já está instalado. ---"
fi

echo ""
echo "--- Verificando e instalando versões do Python... ---"
for VERSION in "${PYTHON_VERSIONS_TO_INSTALL[@]}"; do
  # O comando 'install' do uv é idempotente, então ele só instala se for necessário.
  echo "Garantindo que Python ${VERSION} esteja instalado..."
  uv python install "${VERSION}"
done

echo ""
echo "✅ Ambiente de desenvolvimento pronto!"
echo "As versões necessárias do Python foram instaladas via uv."
echo "Agora você pode executar o script de compilação (ex: build_all.sh)."
```


#### Exemplo de Script `scripts/setup_dev_env.bat` (Windows)

```batch
@echo off
setlocal

:: --- Configuração ---
set PYTHON_VERSIONS_TO_INSTALL=3.11 3.12
:: --------------------

:: Verifica se o comando 'uv' existe
where uv >nul 2>nul
if %errorlevel% neq 0 (
    echo --- 'uv' nao encontrado. Instalando uv... ---
    powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
    echo --- 'uv' instalado com sucesso. ---
) else (
    echo --- 'uv' ja esta instalado. ---
)

echo.
echo --- Verificando e instalando versoes do Python... ---
for %%V in (%PYTHON_VERSIONS_TO_INSTALL%) do (
    echo Garantindo que Python %%V esteja instalado...
    uv python install %%V
)

echo.
echo == Ambiente de desenvolvimento pronto! ==
echo As versoes necessarias do Python foram instaladas via uv.
echo Agora voce pode executar o script de compilacao (ex: build_all.bat).
endlocal
```

### 4.2. Obtendo as Dependências do Pure Data

A compilação de um external requer os arquivos de cabeçalho do Pd (como `m_pd.h`).

*   **`m_pd.h` e Cabeçalhos**: O `CMakeLists.txt` do projeto já utiliza o `pd.cmake`, que por sua vez, baixa automaticamente uma versão compatível dos cabeçalhos do `libpd`. Isso já automatiza a parte mais importante.
*   **(Apenas Windows) Binários do Pd**: Para a linkagem no Windows, é necessário ter acesso ao `pd.lib`. A forma mais robusta de automatizar isso seria através de um script que baixa uma versão específica do Pure Data e a extrai para um diretório conhecido (ex: `pd-sdk/`). O `CMakeLists.txt` poderia então ser instruído a procurar por essa pasta.

## 5. Compilação Automatizada e Multi-Versão

Com o ambiente de desenvolvimento preparado pela execução do script `scripts/setup_dev_env.sh`, podemos usar os scripts de compilação (localizados em `scripts/build_all.sh`). Eles foram projetados para serem robustos e organizados, seguindo estes passos:

1.  **Limpeza Automática:** Antes de iniciar, o script remove os diretórios `build` e `dist` da raiz do projeto para garantir que cada nova compilação seja totalmente limpa.
2.  **Estrutura Organizada:** Ele cria um diretório `build` principal na raiz e, dentro dele, subdiretórios para cada versão do Python (ex: `build/py3.11`, `build/py3.12`).
3.  **Ambientes Virtuais Isolados:** Para cada versão do Python, um ambiente virtual (`.venv-pyX.Y`) na raiz do projeto é criado e ativado. Isso garante que a compilação use a versão correta do Python e suas bibliotecas, de forma totalmente isolada.
4.  **Compilação e Agregação:** Após compilar o projeto para cada versão, o binário final é renomeado e copiado para o diretório `dist` na raiz, que conterá todos os artefatos prontos para uso.

#### Exemplo de Script de Build para Windows (`scripts/build_all.bat`)

```batch
@echo off
setlocal

:: --- Configuração ---
set PYTHON_VERSIONS=3.11 3.12
set DIST_DIR=..\dist
set MAIN_BUILD_DIR=..\build
:: --------------------

:: 1. Limpa os diretórios de build e distribuição anteriores
echo.
echo --- Limpando builds anteriores... ---
if exist %DIST_DIR% rmdir /s /q %DIST_DIR%
if exist %MAIN_BUILD_DIR% rmdir /s /q %MAIN_BUILD_DIR%

:: 2. Recria os diretórios principais
mkdir %DIST_DIR%
mkdir %MAIN_BUILD_DIR%

echo.
echo Compilando py4pd para as versoes: %PYTHON_VERSIONS%
echo.

for %%V in (%PYTHON_VERSIONS%) do (
    echo.
    echo --- Compilando para Python %%V ---
    set VENV_DIR=..\.venv-py%%V
    set BUILD_DIR=%MAIN_BUILD_DIR%\py%%V

    rem 3. Cria e ativa um ambiente virtual isolado com uv
    echo Criando ambiente virtual em %VENV_DIR%...
    uv venv -p %%V %VENV_DIR%
    call %VENV_DIR%\Scripts\activate.bat
    
    rem 4. Configura o projeto com a versao correta do Python
    cmake .. -B %BUILD_DIR% -DPYVERSION=%%V
    if errorlevel 1 (
        echo *** Erro na configuracao do CMake para Python %%V ***
        call %VENV_DIR%\Scripts\deactivate.bat
        goto :eof
    )
    
    rem 5. Compila o projeto
    cmake --build %BUILD_DIR% --config Release
    if errorlevel 1 (
        echo *** Erro na compilacao para Python %%V ***
        call %VENV_DIR%\Scripts\deactivate.bat
        goto :eof
    )
    
    rem 6. Desativa o ambiente
    call %VENV_DIR%\Scripts\deactivate.bat

    rem 7. Renomeia e move o binario
    copy "%BUILD_DIR%\Release\py4pd.dll" "%DIST_DIR%\py4pd-py%%V.dll"
    echo Binario salvo em: %DIST_DIR%\py4pd-py%%V.dll
)

echo.
echo == Compilacao de todas as versoes concluida! ==
endlocal
```

#### Exemplo de Script de Build para Linux/macOS (`build_all.sh`)

```bash
#!/bin/bash

# Defina as versões do Python para as quais queremos compilar
PYTHON_VERSIONS=("3.11" "3.12")

# Diretório onde os binários finais serão armazenados
DIST_DIR="dist"
# Diretório principal de build
MAIN_BUILD_DIR="build"

mkdir -p "$DIST_DIR"
mkdir -p "$MAIN_BUILD_DIR"

echo "Compilando py4pd para as versões: ${PYTHON_VERSIONS[*]}"
echo

for VERSION in "${PYTHON_VERSIONS[@]}"; do
  echo "--- Preparando ambiente e compilando para Python ${VERSION} ---"
  BUILD_DIR="${MAIN_BUILD_DIR}/py${VERSION}"
  
  # 1. (O restante do script permanece o mesmo, apenas o BUILD_DIR foi alterado)
  cmake . -B "$BUILD_DIR" -DPYVERSION=$VERSION || { echo "*** Erro na configuração do CMake para Python ${VERSION} ***"; exit 1; }
  
  # 2. Compila o projeto
  cmake --build "$BUILD_DIR" || { echo "*** Erro na compilação para Python ${VERSION} ***"; exit 1; }
  
  # 3. Renomeia e move o binário (ajuste a extensão .pd_linux/.pd_darwin)
  # Exemplo para Linux:
  cp "${BUILD_DIR}/py4pd.pd_linux" "${DIST_DIR}/py4pd-py${VERSION}.pd_linux"
  echo "Binário salvo em: ${DIST_DIR}/py4pd-py${VERSION}.pd_linux"
  echo
done

echo "--- Compilação de todas as versões concluída! ---"
```

### 5.2. Como Usar

1.  Salve o script apropriado para seu sistema operacional na raiz do repositório `py4pd`.
2.  Abra um terminal e execute o script (`./build_all.sh` ou `build_all.bat`).
3.  Ao final, um diretório `dist` será criado contendo os binários do `py4pd` para cada versão do Python, prontos para serem usados ou distribuídos.