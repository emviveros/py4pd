# uv: O Guia Completo do Gerenciador Moderno para Python

## 1\. Visão Geral

`uv` é uma ferramenta revolucionária para o ecossistema Python, desenvolvida em Rust pela Astral (a mesma equipe por trás do linter de alta performance **Ruff**). Ele foi projetado para ser um substituto ultrarrápido e coeso para um conjunto de ferramentas que tradicionalmente eram separadas, como `pip`, `venv`, `pip-tools` e `pyenv`.

O objetivo do `uv` é fornecer uma experiência de desenvolvimento unificada e de alta performance, resolvendo três grandes desafios com uma **única ferramenta**:

1.  **Gerenciamento de Versões do Python:** Instalar e alternar entre diferentes versões do interpretador.
2.  **Gerenciamento de Dependências e Ambientes:** Criar ambientes virtuais e gerenciar dependências de forma robusta e reprodutível.
3.  **Consistência e Facilidade de Setup:** Garantir que todos os desenvolvedores e sistemas de automação (CI/CD) usem exatamente as mesmas ferramentas e dependências com o mínimo de esforço.

-----

## 2\. Capacidades Fundamentais

`uv` centraliza múltiplas funcionalidades essenciais em um único binário.

### 2.1. Gerenciamento de Versões do Python

`uv` elimina a necessidade de ferramentas externas como o `pyenv` para gerenciar as instalações do próprio Python.

  * **Como Funciona:** Ele baixa e gerencia versões autônomas (standalone) do Python, armazenando-as localmente sem interferir com o Python do seu sistema operacional.
  * **Comandos Principais:**
      * **Instalar uma ou mais versões:**
        ```bash
        # Instala a versão mais recente do patch 3.12
        uv python install 3.12

        # Instala múltiplas versões simultaneamente
        uv python install 3.10 3.11
        ```
      * **Listar versões disponíveis e instaladas:**
        ```bash
        uv python list
        ```

### 2.2. Gerenciamento de Dependências Inteligente

`uv` oferece uma solução robusta para o "inferno das dependências" através de um resolvedor de alta performance e um fluxo de trabalho de "locking".

  * **Resolvedor Rápido:** Escrito em Rust, seu resolvedor de dependências é ordens de magnitude mais rápido que o do `pip`, utilizando um cache global para evitar downloads repetidos.

  * **Workflow de `compile` e `sync` para Builds Reprodutíveis:**

    1.  **Definição (em `pyproject.toml`):** Você declara as dependências diretas do seu projeto.

        ```toml
        [project]
        name = "meu-projeto-moderno"
        version = "1.0.0"
        dependencies = [
          "fastapi>=0.110",
          "pydantic>2.0",
        ]
        ```

    2.  **Compilação (`uv pip compile`):** `uv` analisa as dependências, resolve toda a árvore de sub-dependências e gera um "plano de instalação" exato.

        ```bash
        uv pip compile pyproject.toml -o requirements.lock
        ```

        O arquivo `requirements.lock` resultante contém a lista completa de todos os pacotes com suas versões exatas e hashes de segurança.

    3.  **Sincronização (`uv pip sync`):** Este comando garante que o ambiente virtual seja um **espelho exato** do arquivo de lock. Pacotes não listados são removidos, garantindo um ambiente limpo.

        ```bash
        uv pip sync -r requirements.lock
        ```

### 2.3. Gerenciamento de Ambientes Virtuais

`uv` cria e gerencia ambientes virtuais padrão, sendo totalmente compatível com o ecossistema existente.

  * **Criação Simplificada:**
    ```bash
    # Cria um ambiente virtual chamado .venv
    uv venv
    ```
  * **Integração com o Gerenciador de Python:** A grande vantagem é poder especificar qual versão do Python (gerenciada pelo próprio `uv`) usar.
    ```bash
    # Cria um ambiente .venv usando o interpretador Python 3.12
    uv venv --python 3.12
    ```

-----

## 3\. Padrão Avançado: Embarcando `uv` para Configuração de Dependência Zero

Para maximizar a consistência e simplificar o onboarding de novos desenvolvedores, `uv` pode ser "embarcado" em um projeto através de um script wrapper.

### 3.1. Os Benefícios do Padrão Wrapper

  * **Setup de Dependência Zero:** Um contribuidor precisa apenas do `git` e de um shell. O script cuida de baixar a versão correta do `uv`.
  * **Versão Consistente da Ferramenta:** Garante que todos na equipe e no CI/CD usem a mesma versão do `uv`, eliminando uma fonte de inconsistência.
  * **Simplicidade para CI/CD:** O pipeline de automação se torna mais simples e robusto.

### 3.2. Implementando o Script Wrapper

Cria-se um script (`scripts/setup.sh`) que é versionado no Git. Este script baixa o binário do `uv` em um diretório local (`.tools/`, que é ignorado pelo Git) e o utiliza para configurar o projeto.

**Exemplo de Script (`scripts/setup.sh`):**

```bash
#!/usr/bin/env bash
set -e # Encerra se qualquer comando falhar

# --- Configuração da Versão do uv e Python ---
UV_VERSION="0.1.43"
PYTHON_VERSION="3.12"
# ---------------------------------------------

TOOLS_DIR="$(pwd)/.tools"
UV_PATH="$TOOLS_DIR/uv"

# Baixa o uv se não existir localmente
if [ ! -f "$UV_PATH" ]; then
    echo "--- Baixando uv v$UV_VERSION... ---"
    mkdir -p "$TOOLS_DIR"
    OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
    ARCH="$(uname -m)"
    TARGET_OS=""
    case "$OS" in
        linux) TARGET_OS="unknown-linux";;
        darwin) TARGET_OS="apple-darwin";;
        *) echo "ERRO: SO '$OS' não suportado."; exit 1;;
    esac
    TARGET_ARCH=""
    case "$ARCH" in
        x86_64) TARGET_ARCH="x86_64";;
        arm64 | aarch64) TARGET_ARCH="aarch64";;
        *) echo "ERRO: Arquitetura '$ARCH' não suportada."; exit 1;;
    esac
    FILENAME="uv-$TARGET_ARCH-$TARGET_OS.tar.gz"
    DOWNLOAD_URL="https://github.com/astral-sh/uv/releases/download/$UV_VERSION/$FILENAME"
    curl --silent --show-error --location "$DOWNLOAD_URL" | tar --strip-components=1 -xz -C "$TOOLS_DIR"
    chmod +x "$UV_PATH"
    echo "--- uv instalado com sucesso em '$UV_PATH' ---"
fi

# Usa o uv local para configurar o ambiente
echo "--- Configurando ambiente com Python $PYTHON_VERSION ---"
"$UV_PATH" venv --python "$PYTHON_VERSION"

# Ativa o ambiente para os próximos passos do script
source .venv/bin/activate

echo "--- Sincronizando dependências de requirements.lock ---"
"$UV_PATH" pip sync -r requirements.lock

echo ""
echo "✅ Ambiente pronto! Para ativá-lo no seu terminal, execute: source .venv/bin/activate"
```

-----

## 4\. Workflow Completo Unificado

Este é um exemplo de ponta a ponta para iniciar um novo projeto usando todos os conceitos abordados.

1.  **Crie a Estrutura Inicial do Projeto:**

      * Crie a pasta do projeto (`meu-projeto`).
      * Dentro dela, crie a pasta `scripts` e adicione o `setup.sh` acima.
      * Crie um arquivo `pyproject.toml` para definir as dependências.
      * Adicione `.venv/` e `.tools/` ao seu arquivo `.gitignore`.

2.  **Execute o Bootstrap:** Um novo desenvolvedor clona o repositório e executa um único comando.

    ```bash
    git clone https://github.com/seu-usuario/meu-projeto.git
    cd meu-projeto
    sh ./scripts/setup.sh
    ```

    O script irá baixar o `uv` e o Python, criar o ambiente e instalar as dependências.

3.  **Desenvolva:**

      * **Ative o ambiente:** `source .venv/bin/activate`
      * **Adicione uma nova dependência:**
        1.  Adicione o pacote em `pyproject.toml`.
        2.  Recompile o lock: `uv pip compile pyproject.toml -o requirements.lock`
        3.  Sincronize o ambiente: `uv pip sync -r requirements.lock`

## 5\. Conclusão

`uv` representa um salto significativo na experiência de desenvolvimento em Python. Ao consolidar o gerenciamento de versões, ambientes e dependências em um único binário de alta performance, ele oferece um fluxo de trabalho mais rápido, simples e, acima de tudo, mais confiável e reprodutível.