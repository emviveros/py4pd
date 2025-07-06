# Arquitetura Moderna do `py4pd`: Portabilidade e Facilidade de Uso com `uv`

## 1. Visão Geral e Objetivos

A arquitetura proposta para a próxima grande versão do `py4pd` visa resolver desafios fundamentais de usabilidade, portabilidade e gerenciamento de dependências. Os objetivos principais são:

*   **Facilidade para Iniciantes:** O usuário de Pure Data não deve precisar de conhecimento prévio sobre ambientes Python. A experiência deve ser "plug-and-play".
*   **Poder para Avançados:** Oferecer controle granular para usuários experientes que desejam gerenciar ambientes complexos, reutilizar bibliotecas pesadas (ex: `tensorflow`, `pytorch`) e integrar `py4pd` em seus fluxos de trabalho existentes.
*   **Portabilidade e Reprodutibilidade:** Patches e projetos devem ser totalmente autocontidos e portáteis. Um usuário deve poder compartilhar seu projeto com outro, e ele deve funcionar perfeitamente, independentemente do sistema operacional ou das configurações locais de Python.
*   **Segurança:** A distribuição de binários executáveis deve seguir as melhores práticas, utilizando os canais de confiança do ecossistema Pure Data.

Para atingir esses objetivos, foi projetada uma **arquitetura híbrida** que utiliza o gerenciador de pacotes **Deken** para distribuição segura e a ferramenta **`uv`** como um motor de gerenciamento de ambientes Python nos bastidores.

---

## 2. A Arquitetura Híbrida

O sistema combina o melhor de dois mundos: a distribuição de binários via Deken e o gerenciamento dinâmico de ambientes com `uv`.

### 2.1. Distribuição Segura via Deken: O "Bundle" Único

Em vez de publicar múltiplos pacotes no Deken (um para cada versão de Python), será distribuído um **único "bundle" `py4pd`** por plataforma (Windows-x64, macOS-arm64, etc.). O Deken, como de costume, se encarregará de fornecer ao usuário o bundle correto para seu sistema.

Este bundle conterá:

1.  **O "Loader" Inteligente (`py4pd.dll` / `.pd_linux` / `.pd_darwin`):** Um external C leve, sem dependências diretas de Python. Este é o único binário que o Pure Data carrega inicialmente e serve como o ponto de entrada para toda a lógica.
2.  **Os Binários Reais do `py4pd`:** Os externals `py4pd` pré-compilados para cada versão de Python suportada (ex: `py4pd-py3.11.dll`, `py4pd-py3.12.dll`). Eles ficam inativos até serem chamados pelo Loader.
3.  **O Script de Bootstrap:** Um script (`py4pd-bootstrap.sh`) que contém toda a lógica para configurar o ambiente Python.

### 2.2. `uv`: O Motor do Gerenciamento de Ambientes

`uv` é a ferramenta de linha de comando que o script de bootstrap usará para:

*   **Instalar interpretadores Python:** Baixar e gerenciar versões específicas do Python (ex: 3.11, 3.12) de forma isolada.
*   **Criar Ambientes Virtuais:** Gerar ambientes `.venv` para isolar as dependências de cada projeto/patch.
*   **Instalar Pacotes Python:** Funcionar como um `pip` ultrarrápido para instalar as bibliotecas necessárias (ex: `numpy`, `neoscore`).

---

## 3. Fluxo de Trabalho e a "Mágica" nos Bastidores

1.  **Instalação:** O usuário instala o pacote `py4pd` do Deken.
2.  **Primeiro Uso:** O usuário cria um objeto `[py4pd]` em um patch.
3.  **Ativação do Loader:** O `py4pd.dll` (Loader) é ativado. Ele verifica se um ambiente já foi configurado para aquele patch (procurando por um arquivo `.py4pd/env_ready.flag`).
4.  **Execução do Bootstrap:** Se for a primeira vez, o Loader executa o `py4pd-bootstrap.sh`, passando dois argumentos cruciais:
    *   `$1`: O caminho para o diretório do patch **atual**.
    *   `$2`: O caminho para o diretório do patch **raiz do projeto** (o patch de nível superior que o usuário abriu).
5.  **Decisão do Ambiente:** O script de bootstrap segue uma **hierarquia de prioridades** para decidir qual ambiente Python usar.
6.  **Configuração do Ambiente:** Com base na decisão, o script usa `uv` para instalar Python e bibliotecas, se necessário.
7.  **Comunicação com o Loader:** O script imprime para a saída padrão as instruções para o Loader, como qual binário real carregar (`load_binary py4pd-py3.12`) e qual caminho de pacotes adicionar (`add_path .../site-packages`).
8.  **Ativação Final:** O Loader em C lê essas instruções, carrega dinamicamente o binário `py4pd` correto (ex: `py4pd-py3.12.dll`), adiciona os caminhos ao Pd e, a partir desse momento, atua como um proxy, repassando todas as mensagens para o `py4pd` real.

---

## 4. A Hierarquia de Seleção de Ambientes

Esta é a lógica central que oferece flexibilidade ao sistema. O script de bootstrap segue esta ordem para encontrar ou criar um ambiente:

### 4.1. Prioridade 1: Controle Explícito do Usuário

*   **Gatilho:** O usuário (avançado) envia uma mensagem ao `[py4pd]`, como `[packages /caminho/para/meu_ambiente/lib/python3.11/site-packages]`.
*   **Ação:** O Loader salva este caminho em um arquivo de configuração local ao patch (ex: `.py4pd/env.conf`). O script de bootstrap lê este arquivo e utiliza o ambiente especificado, sem realizar nenhuma outra configuração.
*   **Caso de Uso:** Reutilizar ambientes pesados (IA, análise de dados) em múltiplos projetos para economizar espaço e tempo de instalação.

### 4.2. Prioridade 2: Ambiente de Projeto (Busca Ascendente Contida)

*   **Gatilho:** Nenhuma configuração explícita (Prioridade 1) existe.
*   **Ação:** O script inicia uma busca por uma pasta `.venv` começando no diretório do patch atual e subindo na hierarquia de pastas. A busca **para** quando atinge o diretório raiz do projeto (o argumento `$2` passado pelo Loader).
*   **Resultado:** Se um `.venv` é encontrado, ele é adotado como o ambiente compartilhado para todo o projeto.
*   **Caso de Uso:** Organizar um projeto complexo (ex: uma instalação artística) com múltiplos subpatches e abstrações, todos compartilhando as mesmas dependências em um único ambiente na raiz do projeto.

### 4.3. Prioridade 3: Ambiente Local ao Patch (Padrão Autocontido)

*   **Gatilho:** A busca da Prioridade 2 não encontra nenhum `.venv` dentro dos limites do projeto.
*   **Ação:** O script retorna ao diretório do patch atual e usa `uv` para criar um novo ambiente `.venv` localmente. A versão do Python a ser instalada pode ser a padrão (ex: 3.12) ou especificada em um arquivo `py4pd.toml` local.
*   **Resultado:** Garante que patches simples e independentes sejam 100% autocontidos e portáteis por padrão. Este é o comportamento esperado para iniciantes.

---

## 5. Componentes Técnicos Detalhados

### 5.1. O Loader em C (`py4pd.dll`)

*   **Responsabilidades:**
    1.  Ser o único ponto de contato com o Pd no momento da criação do objeto.
    2.  Detectar o diretório do patch atual e o diretório do patch raiz do projeto.
    3.  Executar o script de bootstrap com os caminhos corretos como argumentos.
    4.  Capturar e interpretar a saída do script (`load_binary ...`, `add_path ...`).
    5.  Carregar dinamicamente (usando `dlopen` ou `LoadLibrary`) o binário `py4pd` real correspondente à versão do Python do ambiente.
    6.  Adicionar o caminho `site-packages` do ambiente aos caminhos de busca do Pd.
    7.  Atuar como um proxy transparente, repassando todas as mensagens e interações para o binário `py4pd` carregado.

### 5.2. O Script de Bootstrap (`py4pd-bootstrap.sh`)

*   **Responsabilidades:**
    1.  Garantir que uma cópia do `uv` esteja disponível (baixando-a para um cache do usuário, se necessário).
    2.  Implementar a lógica de hierarquia de ambientes (Prioridades 1, 2 e 3).
    3.  Interagir com `uv` para instalar Python e criar/gerenciar o `.venv`.
    4.  (Opcional) Analisar o patch para encontrar dependências e instalá-las com `uv pip install`.
    5.  Determinar a versão do Python do ambiente selecionado.
    6.  Imprimir as instruções formatadas para o Loader em C.
    7.  Criar o arquivo de "flag" (`.py4pd/env_ready.flag`) para evitar que a configuração seja executada novamente.

---

## 6. Vantagens da Arquitetura

*   **Segurança:** Nenhum binário executável é baixado da internet durante o uso. Todo o código executável é distribuído através do Deken, um canal confiável.
*   **Experiência do Usuário:** O sistema é transparente para iniciantes e poderoso para especialistas. A complexidade é gerenciada nos bastidores.
*   **Manutenção e Distribuição Centralizadas:** Esta arquitetura evita a fragmentação do `py4pd` no Deken em múltiplos pacotes (um para cada versão de Python). O desenvolvedor mantém um único "nome" de pacote (`py4pd`) por plataforma, e o usuário final sempre encontra uma única entrada para instalar. Adicionar suporte a uma nova versão do Python envolve atualizar este bundle.
*   **Flexibilidade e Portabilidade:** A hierarquia de ambientes atende a múltiplos casos de uso, desde patches simples e portáteis até a organização de grandes projetos e a reutilização de ambientes pesados.