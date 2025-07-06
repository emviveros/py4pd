# tech.md

Quais tecnologias e frameworks serão utilizados?
- External em C (loader leve: `py4pd.dll`/`.pd_linux`/`.pd_darwin`) para Pure Data.
- Binários reais do py4pd para cada versão de Python suportada.
- Script de bootstrap (`py4pd-bootstrap.sh`) para configuração automática do ambiente.
- Gerenciador de ambientes Python: `uv` (instalação de Python, criação de `.venv`, instalação de pacotes).
- Distribuição via Deken (ecossistema Pure Data).
- Pure Data (Pd) como ambiente de execução.

Existem restrições técnicas ou requisitos de ambiente?
- O usuário deve instalar o pacote py4pd via Deken.
- Não é necessário conhecimento prévio de Python para uso básico.
- O loader não depende diretamente de Python instalado no sistema.
- O script de bootstrap gerencia ambientes Python de forma isolada e portátil.
- Binários são distribuídos por plataforma (Windows-x64, macOS-arm64, etc.).
- Segurança: apenas binários distribuídos via Deken são executados.

Quais dependências externas são necessárias?
- `uv` (baixado automaticamente pelo bootstrap, se necessário).
- Binários do Python (baixados e gerenciados pelo `uv`).
- Pacotes Python necessários para cada projeto/patch (instalados via `uv pip install`).
- Pure Data instalado.

Como será o fluxo de desenvolvimento?
1. O desenvolvedor mantém o bundle py4pd para cada plataforma, contendo loader, binários e script de bootstrap.
2. O usuário instala o pacote via Deken.
3. Ao criar `[py4pd]` em um patch, o loader verifica e configura o ambiente Python usando o bootstrap e o `uv`.
4. O usuário pode customizar o ambiente enviando mensagens ao `[py4pd]` (ex: `[packages /caminho/para/venv]`).
5. O ambiente Python é criado/selecionado conforme prioridades: configuração explícita, busca por `.venv` no projeto, criação local.
6. O loader ativa o binário correto e repassa mensagens entre Pd e Python.
7. O fluxo é transparente para iniciantes, mas permite controle avançado para usuários experientes.