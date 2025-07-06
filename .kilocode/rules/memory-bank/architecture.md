# architecture.md

Qual arquitetura geral será adotada?
- O sistema utiliza uma arquitetura híbrida, composta por um external em C para Pure Data (Pd) chamado `[py4pd]`, que atua como ponte entre o ambiente Pd e scripts Python. O external gerencia o roteamento de mensagens, inicialização do interpretador Python, integração com arrays, clocks e métodos nativos, além de permitir a extensão dinâmica via arquivos `.pd_py`.

Quais os principais componentes e suas relações?
- External em C (`py4pd`): único objeto Pd criado no patch, recebe todas as mensagens.
- Arquivos `.pd_py`: scripts Python que implementam métodos customizados e funcionalidades extras. Exemplo: um arquivo `py.pip.pd_py` pode definir o método para tratar a mensagem `pip`.
- Loader de arquivos `.pd_py`: ao receber uma mensagem (ex: `pip install PACKAGE`), o py4pd verifica se existe um método Python correspondente carregado a partir dos scripts `.pd_py`.
- Interpretador Python embutido: executa scripts Python e métodos customizados.
- Proxy de inlets: roteia mensagens de Pd para métodos Python.
- Módulos de integração (arrays, clocks): permitem manipulação de dados e agendamento de funções.
- Documentação e exemplos: fornecem suporte ao usuário e validam o funcionamento.

Fluxo de uso dos arquivos `.pd_py`:
1. O usuário instancia o objeto `[py4pd]` no patch Pd.
2. Mensagens como `pip install PACKAGE` são enviadas para `[py4pd]`.
3. O py4pd roteia a mensagem para um método Python correspondente, que pode estar definido em um arquivo `.pd_py` (ex: `py.pip.pd_py`).
4. Se o método existir, ele é executado; se não, um aviso é mostrado.

Exemplo: Para usar pip, o usuário envia a mensagem `[pip install PACKAGE(` para `[py4pd]`. O método Python correspondente pode estar implementado em `py.pip.pd_py`.

Existem decisões técnicas já tomadas?
- Uso de Pure Data externals em C para máxima integração e performance.
- Roteamento universal de mensagens: qualquer mensagem é aceita e roteada para Python.
- Métodos nativos implementados em C para funções essenciais (reload, tabread, tabwrite, logpost, error, out, new_clock).
- Suporte a métodos customizados via convenção `in_1_<mensagem>` no Python e via arquivos `.pd_py`.
- Inicialização automática do interpretador Python e configuração do ambiente.
- Carregamento dinâmico de scripts `.pd_py` para extensão de funcionalidades sem recompilar o external.

Onde ficará o código-fonte principal?
- O código-fonte principal está em `Sources/py4pd.c`, com funcionalidades complementares em `Sources/module.c`, `Sources/proxyinlets.c`, `Sources/clock.c` e scripts de exemplo em `Sources/py4pd/`.