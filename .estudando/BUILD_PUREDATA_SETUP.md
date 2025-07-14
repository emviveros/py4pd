# Plano Arquitetural: Automação do Download e Organização dos Arquivos Pure Data para o Build do py4pd

## Objetivo

Automatizar o download, organização e configuração dos arquivos essenciais do Pure Data necessários para o build do py4pd, sem qualquer intervenção manual, via script de setup multiplataforma.

---

## Arquivos Essenciais

- **Cabeçalho do Pure Data**
  - `m_pd.h`
  - Fonte: [Pure Data GitHub](https://github.com/pure-data/pure-data/blob/master/src/m_pd.h)
  - Destino: `Resources/puredata/m_pd.h`

- **Binários do Pure Data (Windows)**
  - `pd.dll` ou `pd64.dll`
  - Fonte: [Pure Data Releases](https://github.com/pure-data/pure-data/releases)
  - Destino: `Resources/puredata/pd.dll` ou `Resources/puredata/pd64.dll`

- **Arquivos de ajuda (.pd)**
  - Exemplos: `py4pd-help.pd`, `*-help.pd`
  - Fonte: Repositório local ou URLs oficiais
  - Destino: `Resources/puredata/`

---

## Estratégia de Automação

1. **Download Automático**
   - Baixar `m_pd.h` e binários do Pure Data das fontes oficiais.
   - Validar integridade (checksum, tamanho mínimo, etc).
   - Não baixar novamente se o arquivo já existir e estiver íntegro.

2. **Organização dos Arquivos**
   - Criar diretório `Resources/puredata` se não existir.
   - Copiar arquivos de ajuda `.pd` do repositório para este diretório.

3. **Configuração das Variáveis de Ambiente**
   - Definir no script:
     - `PD_SOURCES_PATH=Resources/puredata/m_pd.h`
     - `PDBINDIR=Resources/puredata/pd.dll` ou `pd64.dll`
     - `PDLIBDIR=Resources/puredata/`
   - Exportar/definir para uso no build (CMake/Makefile).

4. **Logs e Idempotência**
   - Registrar logs claros de cada etapa.
   - Garantir que o processo seja idempotente.

5. **Atualização do .gitignore**
   - Adicionar `Resources/puredata/*` para evitar versionamento dos arquivos baixados.

---

## Observações

- O plano deve ser seguido integralmente na implementação do bloco correspondente no script de setup (`setup_dev_env.ps1` e variantes).
- Não incluir etapas manuais ou instruções para o usuário.
- O processo deve ser multiplataforma, mas priorizar PowerShell para Windows.

---

## Diagrama de Fluxo (Mermaid)

```mermaid
flowchart TD
    A[Início do Script] --> B{Arquivos já existem e íntegros?}
    B -- Sim --> F[Configura variáveis de ambiente]
    B -- Não --> C[Baixa arquivos de fontes oficiais]
    C --> D[Valida integridade]
    D --> E[Organiza em Resources/puredata]
    E --> F
    F --> G[Atualiza .gitignore]
    G --> H[Fim]