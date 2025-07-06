# architecture.md

Qual arquitetura geral será adotada?
- Arquitetura híbrida: external em C para Pure Data (Pd) chamado `[py4pd]`, que atua como ponte entre Pd e scripts Python. O external gerencia roteamento de mensagens, inicialização do interpretador Python, integração com arrays, clocks e métodos nativos, além de permitir extensão dinâmica via arquivos `.pd_py`.

Quais os principais componentes e suas relações?
- Loader C (`py4pd.dll`, `.pd_linux`, `.pd_darwin`): único objeto Pd criado no patch, recebe todas as mensagens e inicializa o ambiente Python.
- Binários py4pd específicos por versão de Python (ex: `py4pd-py3.11.dll`): executam a lógica Python integrada ao Pd.
- Scripts `.pd_py`: implementam métodos customizados e funcionalidades extras. Exemplo: `py.pip.pd_py` define o método para tratar a mensagem `pip`.
- Loader de arquivos `.pd_py`: ao receber uma mensagem, o py4pd verifica se existe método Python correspondente carregado a partir dos scripts `.pd_py`.
- Interpretador Python embutido: executa scripts Python e métodos customizados.
- Proxy de inlets: roteia mensagens de Pd para métodos Python.
- Módulos de integração (arrays, clocks): permitem manipulação de dados e agendamento de funções.
- Scripts de setup e build: automatizam instalação de dependências, criação de ambientes Python reprodutíveis e build multiplataforma.
- Documentação e exemplos: fornecem suporte ao usuário e validam o funcionamento.

Fluxo de uso dos arquivos `.pd_py`:
1. O usuário instancia o objeto `[py4pd]` no patch Pd.
2. Mensagens como `pip install PACKAGE` são enviadas para `[py4pd]`.
3. O py4pd roteia a mensagem para um método Python correspondente, definido em um arquivo `.pd_py` (ex: `py.pip.pd_py`).
4. Se o método existir, ele é executado; se não, um aviso é mostrado.

Fluxo de build e distribuição:
- Scripts multiplataforma (`setup_dev_env.sh`, `setup_dev_env.bat`, `build_all.sh`, `build_all.bat`) garantem automação total do setup, build e distribuição.
- Suporte explícito a múltiplas versões de Python, com geração de binários nomeados por versão.
- Estrutura de distribuição moderna com placeholders e documentação automática no bundle.
- Build determinístico, multiplataforma e reprodutível, pronto para integração contínua (CI/CD).

Decisões técnicas já tomadas:
- Uso de externals em C para máxima integração e performance.
- Roteamento universal de mensagens: qualquer mensagem é aceita e roteada para Python.
- Métodos nativos implementados em C para funções essenciais (reload, tabread, tabwrite, logpost, error, out, new_clock).
- Suporte a métodos customizados via convenção `in_1_<mensagem>` no Python e via arquivos `.pd_py`.
- Inicialização automática do interpretador Python e configuração do ambiente.
- Carregamento dinâmico de scripts `.pd_py` para extensão de funcionalidades sem recompilar o external.
- Build e setup totalmente automatizados, multiplataforma e idempotentes.

Onde fica o código-fonte principal?
- Código-fonte principal em `Sources/py4pd.c`, com funcionalidades complementares em `Sources/module.c`, `Sources/proxyinlets.c`, `Sources/clock.c` e scripts de exemplo em `Sources/py4pd/`.
- Scripts de setup e build em `scripts/`.
- Exemplos integrados em `Documentation/examples/`.