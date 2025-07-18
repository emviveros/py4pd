# Plano de Automação Abrangente para Setup do Ambiente Pure Data

Este documento detalha o plano para automatizar o download, extração e organização dos binários do Pure Data (Pd) para as arquiteturas de 32 e 64 bits no Windows. O objetivo é criar um ambiente de compilação para `py4pd` que seja totalmente automatizado, reprodutível e compatível com CI/CD.

## 1. Visão Geral e Estrutura de Diretórios

O script de automação irá buscar, baixar e organizar os arquivos do Pd em uma estrutura de diretórios padronizada dentro do repositório, como:

```
/py4pd
|-- /pd_sdk
|   |-- /include
|   |   `-- m_pd.h
|   |-- /lib
|   |   |-- /x64
|   |   |   |-- pd.dll
|   |   |   `-- pd.lib
|   |   `-- /x86
|   |       |-- pd.dll
|   |       `-- pd.lib
|-- /scripts
|   `-- setup_dev_env.ps1
`-- ... (outros arquivos do projeto)
```

-   **`pd_sdk/`**: Diretório raiz para os artefatos do Pure Data.
-   **`pd_sdk/include/`**: Contém o cabeçalho `m_pd.h`, que é comum a todas as arquiteturas.
-   **`pd_sdk/lib/x64/`**: Contém os binários (`.dll`, `.lib`) para a arquitetura de 64 bits.
-   **`pd_sdk/lib/x86/`**: Contém os binários (`.dll`, `.lib`) para a arquitetura de 32 bits.

## 2. Fluxo de Automação Detalhado

O script `scripts/setup_dev_env.ps1` executará o seguinte fluxo:

```mermaid
graph TD
    A[Iniciar Script de Setup] --> B{Verificar se /pd_sdk existe e está completo?};
    B -- Sim --> J[Finalizar];
    B -- Não --> C[Limpar diretório /pd_sdk existente];
    C --> D[Buscar Última Versão Estável do Pd];
    D --> E{Para cada arquitetura (x64, x86)};
    E -- x64 --> F_x64[Download e Extração da versão 64-bit];
    F_x64 --> G_x64[Copiar binários para pd_sdk/lib/x64 e m_pd.h para pd_sdk/include];
    G_x64 --> E;
    E -- x86 --> F_x86[Download e Extração da versão 32-bit];
    F_x86 --> G_x86[Copiar binários para pd_sdk/lib/x86];
    G_x86 --> H[Limpar arquivos temporários];
    H --> I[Configurar Variáveis de Ambiente/Build];
    I --> J;
```

### Passo 2.1: Lógica de Identificação de URL

O script identificará as URLs para todas as arquiteturas Windows suportadas:

- **Arquiteturas contempladas:**
  - x64 (64-bit): arquivos padrão `pd-VERSAO.msw.zip` (não contém `test`, não contém `i386`)
  - x86/i386 (32-bit): arquivos padrão `pd-VERSAO-i386.msw.zip` (não contém `test`, contém `i386`)
  - Outras variantes Windows: se surgirem novos padrões, devem ser incluídos conforme a lógica de filtragem por sufixo e prefixo.

-   **Lógica de seleção da versão mais recente:**
    - Listar todos os arquivos `.msw.zip` disponíveis.
    - Ignorar arquivos que contenham `test` no nome.
    - Para cada arquitetura, extrair o número da versão (`VERSAO`) e comparar para selecionar a maior versão disponível.
    - Garantir que, se houver mais de um padrão para Windows, todos sejam contemplados e organizados conforme a estrutura de diretórios.

### Passo 2.2: Extração e Organização

Após o download e a extração em um diretório temporário, o script irá:

1.  **Para a versão 64-bit:**
    -   Criar os diretórios `pd_sdk/include` e `pd_sdk/lib/x64`.
    -   Copiar `<temp_dir>/pd-<version>/src/m_pd.h` para `pd_sdk/include/m_pd.h` (apenas na primeira vez).
    -   Copiar `<temp_dir>/pd-<version>/bin/pd.dll` para `pd_sdk/lib/x64/pd.dll`.
    -   Copiar `<temp_dir>/pd-<version>/bin/pd.lib` para `pd_sdk/lib/x64/pd.lib`.
2.  **Para a versão 32-bit:**
    -   Criar o diretório `pd_sdk/lib/x86`.
    -   Copiar `<temp_dir>/pd-<version>/bin/pd.dll` para `pd_sdk/lib/x86/pd.dll`.
    -   Copiar `<temp_dir>/pd-<version>/bin/pd.lib` para `pd_sdk/lib/x86/pd.lib`.
3.  Remover os arquivos temporários de download e extração.

## 3. Configuração do Build com CMake

O `CMakeLists.txt` será ajustado para selecionar os binários corretos com base na arquitetura do build.

-   **Detecção da Arquitetura:** O CMake pode detectar a arquitetura do build (ex: através de `CMAKE_SIZEOF_VOID_P`).
-   **Seleção de Caminhos:**
    ```cmake
    # Define o diretório de include, que é comum
    set(PD_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/pd_sdk/include)
    
    # Define o diretório da biblioteca com base na arquitetura
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(PD_LIB_DIR ${CMAKE_SOURCE_DIR}/pd_sdk/lib/x64)
    else()
        set(PD_LIB_DIR ${CMAKE_SOURCE_DIR}/pd_sdk/lib/x86)
    endif()

    find_path(PD_INCLUDE_PATH m_pd.h PATHS ${PD_INCLUDE_DIR})
    find_library(PD_LIBRARY pd PATHS ${PD_LIB_DIR})

    if(NOT PD_INCLUDE_PATH OR NOT PD_LIBRARY)
        message(FATAL_ERROR "SDK do Pure Data não encontrado. Execute o script de setup.")
    endif()

    include_directories(${PD_INCLUDE_PATH})
    #...
    ```

## 4. Próximos Passos

1.  **Aprovação do Plano:** Revisar este documento para garantir que ele atenda a todos os requisitos.
2.  **Implementação:** Modificar o script `scripts/setup_dev_env.ps1` e o `CMakeLists.txt` para implementar a lógica descrita.
3.  **Validação:** Testar o script em um ambiente limpo para garantir que o setup seja totalmente automatizado e que a compilação para ambas as arquiteturas funcione corretamente.

Este plano abrangente garante que o ambiente de desenvolvimento seja robusto, portátil e totalmente automatizado, alinhado com as melhores práticas de CI/CD.