# brief.md

Este arquivo orienta a preparação do ambiente e o fluxo de compilação do py4pd, com foco em automação total e reprodutibilidade: todo o setup é realizado por scripts multiplataforma, sem etapas manuais, garantindo builds portáveis e integração direta ao Pure Data.

**Como usar este arquivo:**
1. Execute o script de setup correspondente ao seu sistema operacional (`./scripts/setup.sh` para Linux/macOS ou `scripts\setup.ps1` para Windows). O script cuidará de toda a configuração do ambiente, instalação de dependências e preparação do build.
2. Após rodar o script, siga as instruções dos tópicos para compilar, validar e distribuir o py4pd.
3. Use este guia para padronizar o onboarding de novos desenvolvedores e automatizar o build local e em CI/CD.

## Tópicos obrigatórios

**Objetivo principal do projeto:**
Permitir a compilação, distribuição e uso do py4pd como external cross-plataforma para Pure Data, com ambiente Python reprodutível via `uv` e build automatizado pelo `pd.cmake`.

**Público-alvo:**
Desenvolvedores, mantenedores e colaboradores do py4pd, especialmente quem precisa compilar, distribuir ou validar o external em diferentes sistemas operacionais.

**Requisitos e metas principais:**
- Utilizar o `pd.cmake` para build cross-plataforma, facilitando a geração de binários portáveis (.dll, .pd_linux, .pd_darwin).
- Definir e documentar variáveis essenciais do build: `PD_INSTALL_DIR`, `PY4PD_PYTHON_VERSION`, `PY4PD_USE_UV`, entre outras.
- Integrar o external ao Pure Data, garantindo compatibilidade e instalação via Deken.
- Usar o `uv` para criar ambientes Python isolados e reprodutíveis, evitando conflitos de dependências.
- Garantir que o processo de build seja automatizável (ex: via GitHub Actions) e documentado para onboarding rápido de novos desenvolvedores.
- Adotar boas práticas para builds determinísticos, versionamento e testes automatizados.

**Pré-requisitos e configuração do ambiente:**
- Basta rodar o script de setup adequado ao seu sistema operacional. Ele irá:
  - Detectar o SO e instalar automaticamente CMake (>=3.15), compilador C (GCC, Clang ou MSVC), Pure Data, `uv` e demais dependências.
  - Clonar o repositório (se necessário) e garantir acesso ao subdiretório `Sources/`.
  - Configurar variáveis de ambiente e preparar todos os arquivos essenciais (`CMakeLists.txt`, `Makefile`, scripts auxiliares).
  - Criar o ambiente Python reprodutível e instalar dependências.
- Não é necessário realizar etapas manuais de instalação ou configuração.

**Comandos essenciais e fluxo de build:**
- Após rodar o script de setup, utilize:
  ```sh
  cmake -B build -DPD_INSTALL_DIR=/caminho/para/pure-data
  cmake --build build
  ```
- Para build customizado (exemplo):
  ```sh
  cmake -B build -DPY4PD_PYTHON_VERSION=3.11 -DPY4PD_USE_UV=ON
  cmake --build build
  ```
- Para instalar no diretório de externals do Pd:
  ```sh
  cmake --install build
  ```
- O ambiente Python reprodutível já estará criado pelo script de setup.
- Consulte `.estudando/Guia de Arquitetura e Compilação do py.md` e `.estudando/infos/pd.cmake README.md` para detalhes de flags, troubleshooting e exemplos de uso.

**Boas práticas e recomendações:**
- Sempre utilize o script de setup para garantir ambiente padronizado e reprodutível.
- Scripts devem ser idempotentes e multiplataforma, podendo ser usados tanto localmente quanto em CI/CD (ex: GitHub Actions).
- Documente e versiona scripts e configurações de ambiente.
- Use o `uv` para garantir ambientes Python idênticos em todos os desenvolvedores e pipelines.
- Teste o external no Pure Data após cada build, validando integração e funcionamento.
- Mantenha scripts e instruções sempre atualizados para facilitar o onboarding.

**Escopo inicial:**
Inclui:
- Configuração do ambiente de build e Python reprodutível.
- Compilação, instalação e testes do external em múltiplos sistemas.
- Documentação de variáveis, comandos e troubleshooting do build.
Não inclui:
- Implementação de novas funcionalidades no py4pd.
- Tradução para outros idiomas além do português.
- Documentação de integrações externas não presentes no repositório.

> Use este arquivo como referência central para garantir builds confiáveis, portáveis e reprodutíveis do py4pd.