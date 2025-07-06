# Guia Definitivo para a Distribuição de Externals em Pure Data: Dominando a Compilação Moderna, Automação e Implantação via Deken

## Secção 1: O Panorama Moderno da Distribuição de Externals para Pd

A distribuição de software compilado sempre apresentou um desafio fundamental: a fragmentação de plataformas. Para os desenvolvedores de externals para Pure Data (Pd), este desafio manifesta-se na necessidade de suportar uma matriz diversificada de sistemas operativos (Windows, macOS, Linux) e arquiteturas de CPU (Intel `x86_64`, Apple Silicon `arm64`, e várias versões ARM para dispositivos embarcados como o Raspberry Pi). A abordagem tradicional, que dependia da compilação manual em cada máquina alvo e da configuração de caminhos por parte do utilizador, tornou-se insustentável e propensa a erros num ecossistema de software moderno. Este relatório apresenta a tese de que a solução definitiva para este problema reside na adoção de práticas de desenvolvimento contemporâneas, especificamente sistemas de compilação automatizados e pipelines de Integração Contínua/Entrega Contínua (CI/CD).  

Pure Data, uma linguagem de programação visual multiplataforma desenvolvida por Miller Puckette, deve grande parte da sua flexibilidade e poder à sua arquitetura extensível. O seu núcleo de funcionalidades pode ser expandido através de "externals", que são bibliotecas de código compilado (tipicamente em C ou C++) carregadas dinamicamente em tempo de execução. Estes externals fornecem novos objetos que os utilizadores podem instanciar nos seus patches, abrindo possibilidades ilimitadas para síntese de áudio, processamento de sinais, controlo e muito mais.  

Para gerir a distribuição desta crescente coleção de extensões de terceiros, a comunidade Pd convergiu para o Deken, um sistema de gestão de pacotes integrado diretamente no Pd através do `deken-plugin`, acessível no menu "Help -> Find Externals". A função do Deken não é compilar código, mas sim servir como um repositório centralizado que entrega pacotes binários pré-compilados aos utilizadores, com base na sua plataforma específica. Quando um utilizador procura um external, o Deken compara o sistema operativo e a arquitetura do utilizador com os metadados codificados nos nomes dos ficheiros dos pacotes disponíveis e apresenta a correspondência correta.  

A simplicidade do Deken do ponto de vista do utilizador esconde a complexidade que os desenvolvedores enfrentam. Embora o mecanismo do Deken seja direto, a abordagem profissional para o alimentar com pacotes envolve uma sofisticada cadeia de ferramentas automatizadas. A evolução do ecossistema de desenvolvimento do Pd reflete uma transição clara de um modelo artesanal para um modelo de engenharia de software mais profissional. As discussões iniciais em fóruns e a documentação mais antiga focavam-se em compilação manual e na configuração de caminhos de pesquisa , representando a "velha maneira". O surgimento de ferramentas como o  

`pd-lib-builder` e, mais tarde, o  

`pd.cmake` , sinalizou um movimento em direção à padronização do processo de compilação, uma característica de projetos de software maduros. A integração explícita de soluções de CI/CD, como Travis CI e GitHub Actions, na documentação destas ferramentas representa o passo final, espelhando as práticas da indústria de software em geral.  

Esta mudança de paradigma é fundamental: a questão deixou de ser "Como compilo isto na minha máquina?" para passar a ser "Como defino um processo reprodutível que compila isto em _todas_ as máquinas automaticamente?". Este guia irá orientar o desenvolvedor através da construção dessa cadeia de ferramentas moderna, utilizando a biblioteca `else` como um estudo de caso central para ilustrar as melhores práticas atuais.

## Secção 2: O Ecossistema Deken: Princípios e Práticas

Para distribuir externals de forma eficaz, um desenvolvedor deve primeiro dominar as mecânicas do ecossistema Deken. Este sistema opera com base num contrato claro entre o desenvolvedor e a plataforma, regido principalmente por uma convenção de nomenclatura de ficheiros rigorosa e pela utilização de uma ferramenta de linha de comandos dedicada. Compreender estes princípios é o primeiro passo para automatizar o processo de distribuição.

### A Convenção de Nomenclatura de Ficheiros do Deken

O coração do sistema Deken é a sua convenção de nomenclatura de ficheiros. É através do nome do ficheiro que o Deken identifica a biblioteca, a sua versão e, mais importante, as arquiteturas para as quais foi compilada. O formato é estritamente definido como `LIBNAME{(ARCH)}.dek`.  

- **`LIBNAME`**: O nome canónico da biblioteca (por exemplo, `else`, `cyclone`, `freeverb~`). Este deve ser consistente em todas as versões e plataformas.
    
- **``**: Uma string de versão opcional, mas fortemente recomendada. Deve começar com `[v` e terminar com `]`, sem conter parênteses retos ou curvos no seu interior (por exemplo, `[v1.0-rc13]`). Fornecer uma versão é crucial para que os utilizadores possam identificar e instalar atualizações ou versões específicas.  
    
- **`(ARCH)`**: Um ou mais especificadores de arquitetura, cada um entre parênteses. Esta é a parte mais crítica do nome do ficheiro, pois permite ao Deken fazer a correspondência entre o pacote e o sistema do utilizador. Um único ficheiro `.dek` pode conter binários para múltiplas arquiteturas, resultando em múltiplos especificadores `(ARCH)` no nome do ficheiro, como visto em pacotes para a biblioteca `neuralnet`.  
    

A tabela seguinte fornece uma referência para os especificadores de arquitetura mais comuns. A sua utilização correta é essencial para garantir que os utilizadores recebam o binário apropriado para o seu sistema.

**Tabela 1: Referência de Especificadores de Arquitetura Deken**

|Sistema Operativo|Arquitetura da CPU|Tamanho da Palavra (bits)|Especificador Deken|Exemplo de Pacote|
|---|---|---|---|---|
|macOS|Intel 64-bit|64|`(Darwin-amd64-64)`|`ceammc[v0.9.3](Darwin-amd64-64).dek`|
|macOS|Apple Silicon 64-bit|64|`(Darwin-arm64-64)`|`neuralnet[v0.3](Darwin-arm64-64).dek`|
|Windows|Intel/AMD 64-bit|64|`(Windows-amd64-64)`|`ceammc[v0.9.3](Windows-amd64-64).dek`|
|Windows|Intel/AMD 32-bit|32|`(Windows-i386-32)`|`ceammc[v0.9.3](Windows-i386-32).dek`|
|Linux|Intel/AMD 64-bit|64|`(Linux-amd64-64)`|`neuralnet[v0.3](Linux-amd64-64).dek`|
|Linux|Raspberry Pi (ARMv7)|32|`(Linux-armv7-32)`|`neuralnet[v0.3](Linux-armv7-32).dek`|
|Código Fonte|N/A|N/A|`(Sources)`|`neuralnet[v0.3](Sources).dek`|

### A Ferramenta de Linha de Comandos `deken`

Para facilitar a criação e o upload destes pacotes nomeados corretamente, a comunidade Pd mantém a ferramenta de linha de comandos `deken`. Esta ferramenta requer Python 3 e pode ser instalada seguindo as instruções na sua documentação para desenvolvedores. As suas duas funções principais são  

`package` e `upload`.

- **Empacotamento com `deken package`**: Este comando pega num diretório que contém os ficheiros binários compilados de um external e cria um ficheiro `.dek` (que é essencialmente um arquivo `.zip` ou `.tgz` renomeado). A sua característica mais poderosa é que ele **inspeciona** os ficheiros binários para determinar automaticamente os especificadores de arquitetura corretos. Isto significa que um desenvolvedor pode compilar os seus externals numa máquina macOS, transferir a pasta resultante para uma máquina Linux e executar  
    
    `deken package` nessa máquina. A ferramenta irá detetar corretamente que os binários são para macOS e gerar um nome de ficheiro como `my_external[v1.0](Darwin-x86_64-64)(Darwin-arm64-64).dek`. Esta funcionalidade remove a necessidade de adivinhação e memorização dos especificadores de arquitetura.
    
- **Upload com `deken upload`**: Após a criação do pacote, o comando `deken upload` é usado para publicá-lo no servidor `puredata.info`, onde o plugin Deken do Pd o poderá encontrar. Este comando requer credenciais de login para o site. Durante o upload, a ferramenta também gera e carrega um ficheiro de checksum SHA256 (`.sha256`) para verificação de integridade e, se o GPG estiver configurado, um ficheiro de assinatura (`.asc`) para autenticidade.  
    

### A Pseudo-Arquitetura "(Sources)"

Uma convenção crucial no ecossistema Deken é a pseudo-arquitetura `(Sources)`. Este especificador é usado para distribuir o código fonte da biblioteca juntamente com os seus binários. Esta prática é de extrema importância por duas razões principais:  

1. **Conformidade de Licença**: Muitas bibliotecas de externals são lançadas sob licenças de código aberto, como a GNU General Public License (GPL), que exigem que o código fonte seja distribuído juntamente com os binários. O pacote `(Sources)` cumpre esta obrigação legal.
    
2. **Transparência e Manutenção Comunitária**: Fornecer o código fonte permite que outros utilizadores estudem, modifiquem e contribuam para o projeto, promovendo um ecossistema de código aberto saudável.
    

A ferramenta `deken` foi projetada com um profundo entendimento destas necessidades. O comando `deken package` tenta detetar automaticamente ficheiros de código fonte comuns (como `.c`, `.cpp`, `.h`) no diretório para criar um pacote `(Sources)`. Mais importante ainda, o comando  

`deken upload` irá abortar a operação se detetar que está a ser feito o upload de um pacote binário para uma nova versão de uma biblioteca sem que um pacote `(Sources)` correspondente também seja carregado. Esta imposição garante que os desenvolvedores cumpram as melhores práticas de código aberto.  

O design do Deken é deliberadamente simples no lado do servidor, funcionando como um anfitrião de ficheiros onde o cliente Pd faz a correspondência com base nos nomes dos ficheiros. A "inteligência" do sistema foi deslocada para a ferramenta do desenvolvedor, o CLI `deken`. Esta escolha de design estabelece a premissa para o resto deste guia: o sucesso na distribuição de externals não depende de esperar por um Deken diferente, mas sim de dominar e automatizar a criação dos múltiplos pacotes que o sistema espera.

## Secção 3: Dominando a Compilação Multiplataforma: Um Conto de Duas Ferramentas

Com uma compreensão sólida do que o Deken espera, o foco do desenvolvedor volta-se para a tarefa central: gerar os binários compilados para cada plataforma e arquitetura alvo. A comunidade Pure Data desenvolveu duas principais caixas de ferramentas para padronizar e simplificar este processo: `pd-lib-builder`, uma abordagem baseada em Makefiles, e `pd.cmake`, uma abordagem mais moderna baseada em CMake. A escolha entre estas duas ferramentas é uma decisão estratégica que influencia o fluxo de trabalho de desenvolvimento, a complexidade do projeto e a integração com ambientes de desenvolvimento.

### 3.1 A Abordagem Makefile com `pd-lib-builder`

`pd-lib-builder` é um Makefile auxiliar, escrito por Katja Vetter em 2015 e desde então mantido pela comunidade Pd. Foi inspirado em modelos anteriores e projetado para ser uma solução simples e robusta, aproveitando a ubiquidade da ferramenta `make` em ambientes de desenvolvimento Unix-like.  

**Filosofia e Uso Básico:** A filosofia do `pd-lib-builder` é a simplicidade e a configuração através de variáveis. Um desenvolvedor cria um `Makefile` simples no seu projeto, define algumas variáveis-chave e depois inclui o `Makefile.pdlibbuilder` no final.

Um `Makefile` mínimo para uma biblioteca chamada `mylib` seria assim :  

Makefile

```
# Makefile para mylib
lib.name = mylib
class.sources = myclass1.c myclass2.c
datafiles = mylib-help.pd README.txt

# Define o caminho para o pd-lib-builder (pode ser um submódulo git)
PDLIBBUILDER_DIR = pd-lib-builder
include $(PDLIBBUILDER_DIR)/Makefile.pdlibbuilder
```

**Configuração e Compilação Cruzada:** A configuração é gerida através de variáveis de Makefile. As mais importantes são `PDDIR`, `PDINCLUDEDIR` e `PDBINDIR`, que permitem ao desenvolvedor especificar a localização do código fonte do Pd e dos binários necessários para a ligação (linking), especialmente útil em configurações não padronizadas ou para compilação cruzada.  

Desde a versão 0.6.0, `pd-lib-builder` simplificou a compilação cruzada ao detetar a plataforma alvo a partir do próprio compilador, em vez de depender da máquina de compilação. Para um controlo explícito, um desenvolvedor pode definir a variável  

`PLATFORM` na linha de comandos. Por exemplo, para compilar para Windows de 32 bits a partir de uma máquina Linux com a toolchain MinGW instalada, o comando seria :  

`make PLATFORM=i686-w64-mingw32 PDDIR="/path/to/pd-win32"`

### 3.2 A Abordagem CMake com `pd.build` e `pd.cmake`

O `pd.cmake` é um sistema de compilação mais recente e oficialmente mantido, que parece ser o sucessor do `pd.build` de Pierre Guillot. Ele aproveita o CMake, um meta-sistema de compilação que gera ficheiros de projeto nativos para uma vasta gama de ambientes, como Makefiles Unix, projetos Xcode para macOS e soluções Visual Studio para Windows. Esta abordagem oferece uma flexibilidade e integração com IDEs muito superiores.  

**Filosofia e Uso Básico:** A filosofia do `pd.cmake` é fornecer uma camada de abstração sobre o CMake, com funções específicas para a compilação de externals de Pd. O desenvolvedor escreve um ficheiro `CMakeLists.txt`, que é um script que descreve o projeto.

Um `CMakeLists.txt` mínimo para uma biblioteca seria assim 1 :  

[

pure-data/pd.cmake - GitHub

](https://github.com/pure-data/pd.cmake)

[

![Ícone da fonte](https://t1.gstatic.com/faviconV2?url=https://github.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

github.com/pure-data/pd.cmake

](https://github.com/pure-data/pd.cmake)

CMake

```
cmake_minimum_required(VERSION 3.18)
project(mylib)

# Inclui o pd.cmake (pode ser um submódulo git)
set(PDCMAKE_DIR pd.cmake/ CACHE PATH "Path to pd.cmake")
include(${PDCMAKE_DIR}/pd.cmake)

# Adiciona um external
pd_add_external(myclass1 SOURCES src/myclass1.c)
```

**Configuração e Geração de Projeto:** A configuração é feita através de variáveis CMake, como `PD_SOURCES_PATH` e `PDLIBDIR`. O processo de compilação é feito em duas etapas: primeiro, gerar os ficheiros de projeto nativos com  

`cmake -B build`, e depois, compilar com `cmake --build build`. Esta separação entre configuração e compilação é uma característica central do CMake.  

### 3.3 Análise Comparativa e Recomendações

A escolha entre `pd-lib-builder` e `pd.cmake` não é uma questão de qual é "melhor", mas sim qual se adapta melhor às necessidades do projeto e à familiaridade do desenvolvedor com as ferramentas subjacentes. A tabela seguinte resume as principais diferenças para ajudar na decisão.

**Tabela 2: Comparação de `pd-lib-builder` e `pd.cmake`**

|Característica|`pd-lib-builder`|`pd.cmake`|
|---|---|---|
|**Tecnologia Subjacente**|GNU Make|CMake|
|**Configuração**|Variáveis simples em `Makefile`|Script `CMakeLists.txt`|
|**Dependências**|`make`|`cmake` e um sistema de compilação (e.g., `make`, `ninja`)|
|**Integração com IDE**|Limitada/Manual|Geração nativa para Xcode, Visual Studio, etc.|
|**Curva de Aprendizagem**|Baixa (se familiarizado com `make`)|Moderada (requer aprendizagem da sintaxe CMake)|
|**Ideal Para**|Bibliotecas simples, configuração rápida, fluxos de trabalho centrados na linha de comandos.|Bibliotecas complexas, projetos que necessitam de suporte de IDE, desenvolvedores familiarizados com toolchains C++ modernas.|
|**Projetos de Exemplo**|`cyclone`, `zexy` (migrado)|`else`, `neuralnet`|

A existência destas duas ferramentas maduras e bem mantidas demonstra a saúde do ecossistema de desenvolvimento do Pd. `pd-lib-builder` oferece um caminho de menor resistência para desenvolvedores que preferem um ambiente de compilação tradicional ao estilo Unix. É rápido de configurar e eficaz para muitos projetos. Por outro lado, `pd.cmake` representa uma abordagem mais moderna e poderosa, alinhada com as práticas atuais de desenvolvimento C++. A sua capacidade de gerar projetos nativos para IDEs como Visual Studio ou Xcode é uma vantagem significativa, simplificando a depuração e a gestão de projetos mais complexos, especialmente em ambientes Windows e macOS. A escolha, portanto, deve ser informada pela complexidade do external, pelas plataformas alvo e, crucialmente, pelo fluxo de trabalho preferido do desenvolvedor.  

## Secção 4: O Binário Universal: Unificando o Ecossistema macOS

Um dos desafios mais prementes e recentes para os desenvolvedores de externals é a transição da Apple dos processadores Intel para a sua própria arquitetura Apple Silicon. Esta mudança criou a necessidade de distribuir aplicações que funcionem nativamente em ambas as plataformas para oferecer a melhor experiência ao utilizador. A solução para este problema é o "binário universal", e as modernas ferramentas de compilação do Pd tornaram a sua criação um processo surpreendentemente simples.

### O "Porquê": Apple Silicon e Rosetta 2

Em 2020, a Apple iniciou a transição dos seus computadores Mac de CPUs Intel (com a arquitetura `x86_64`) para os seus próprios processadores baseados em ARM (com a arquitetura `arm64`), conhecidos como Apple Silicon (M1, M2, etc.). Para garantir a compatibilidade com o vasto software existente, a Apple introduziu a camada de tradução Rosetta 2, que permite que aplicações compiladas apenas para Intel sejam executadas em máquinas Apple Silicon. No entanto, esta tradução acarreta uma sobrecarga de desempenho. As aplicações que correm nativamente em  

`arm64` são significativamente mais eficientes, pois o compilador pode otimizar o código especificamente para essa arquitetura. Para um ambiente de processamento de áudio em tempo real como o Pd, o desempenho nativo é altamente desejável.  

### O "Quê": Binários Gordos (Fat/Universal)

Um binário universal, também conhecido como "fat binary", é um único ficheiro executável que contém o código compilado para múltiplas arquiteturas. Quando um utilizador executa um binário universal em macOS, o sistema operativo deteta automaticamente a arquitetura do processador e carrega a "fatia" (  

`slice`) de código apropriada. Numa máquina Intel, ele executa a fatia `x86_64`; numa máquina Apple Silicon, ele executa a fatia `arm64`. Para o utilizador, o ficheiro parece e comporta-se como uma aplicação normal. A própria aplicação Pure Data é distribuída como um binário universal para macOS, estabelecendo um precedente para a comunidade.  

### O "Como": Abstração através de Sistemas de Compilação

A nível fundamental, a criação de um binário universal é um processo de duas fases: primeiro, compilar o código fonte separadamente para cada arquitetura alvo (uma vez para `x86_64` e outra para `arm64`); segundo, usar a ferramenta de linha de comandos da Apple, `lipo`, para fundir os dois binários resultantes num único ficheiro universal.  

Felizmente, os desenvolvedores de externals raramente precisam de invocar `lipo` manualmente. Os sistemas de compilação modernos do Pd abstraem esta complexidade, reduzindo-a a um único argumento de configuração.

**Com `pd-lib-builder`:** A maneira de criar um binário universal para macOS com `pd-lib-builder` é notavelmente concisa. O desenvolvedor simplesmente especifica as arquiteturas desejadas na variável `arch` ao invocar `make`. Esta informação crítica está documentada no ficheiro `tips-tricks.md` do projeto. O comando é:  

`make arch="x86_64 arm64"`

Este único comando instrui o `pd-lib-builder` a executar todo o processo nos bastidores: compilar para Intel de 64 bits, compilar para Apple Silicon de 64 bits e, em seguida, invocar `lipo` para combinar os resultados no ficheiro final `.pd_darwin`.

**Com `pd.cmake`:** A abordagem com CMake é igualmente poderosa, embora configurada de forma diferente. A variável `CMAKE_OSX_ARCHITECTURES` é usada para especificar as arquiteturas alvo. Esta variável pode ser definida no ficheiro `CMakeLists.txt` ou passada como um argumento na linha de comandos do CMake. O `README.md` do projeto `cyclone` fornece um exemplo prático desta utilização ao descrever as suas opções de compilação com CMake.  

Para configurar na linha de comandos ao gerar o projeto: `cmake -B build -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"`

A rápida e eficaz resposta da comunidade de desenvolvimento do Pd e dos seus mantenedores de ferramentas a uma mudança tão significativa na indústria como a transição para a Apple Silicon é notável. A complexidade de suportar duas arquiteturas distintas em macOS foi reduzida a um único e memorável argumento de linha de comandos. Isto não só demonstra a maturidade e a capacidade de resposta do ecossistema de ferramentas do Pd, mas também serve como um forte argumento para a adoção destas ferramentas modernas, que protegem os desenvolvedores da complexidade subjacente e garantem que os seus externals permaneçam acessíveis a toda a base de utilizadores.

## Secção 5: O Pipeline Automatizado: CI/CD com GitHub Actions

A culminação de um fluxo de trabalho de desenvolvimento moderno é a automação completa. Ao integrar os sistemas de compilação com uma plataforma de Integração Contínua/Entrega Contínua (CI/CD) como o GitHub Actions, é possível transformar todo o processo de compilação, teste e empacotamento num pipeline automatizado, acionado por um simples `git push`. Esta secção detalha como construir um pipeline deste tipo, que pega no código fonte de um external e produz um conjunto completo de pacotes `.dek` prontos para Deken, para todas as principais plataformas, sem intervenção manual.

### 5.1 Introdução a CI/CD e GitHub Actions

A Integração Contínua (CI) é a prática de automatizar a integração de alterações de código de múltiplos contribuidores num único projeto de software. A Entrega Contínua (CD) expande esta prática ao automatizar o lançamento de software para ambientes de teste ou produção. Juntas, estas práticas aumentam a fiabilidade e a velocidade do desenvolvimento de software.  

O GitHub Actions é uma plataforma de CI/CD integrada diretamente no GitHub. Os fluxos de trabalho (workflows) são definidos em ficheiros de texto no formato YAML, localizados no diretório `.github/workflows` de um repositório. Os conceitos centrais são:  

- **Workflow**: Um processo automatizado configurável.
    
- **Event**: Um gatilho que inicia um workflow, como um `push` para um branch ou a criação de uma `release`.
    
- **Job**: Um conjunto de passos que são executados num _runner_.
    
- **Runner**: Uma máquina virtual (fornecida pelo GitHub ou auto-hospedada) que executa um job. O GitHub oferece runners para Linux (`ubuntu-latest`), Windows (`windows-latest`) e macOS (`macos-latest`).
    
- **Step**: Uma tarefa individual, que pode ser um comando de shell ou uma _action_ (um script reutilizável).
    
- **Artifact**: Ficheiros gerados por um job (como binários compilados ou pacotes `.dek`) que podem ser guardados e partilhados entre jobs ou descarregados.
    

Tanto o `pd.cmake` como bibliotecas proeminentes como a `else` utilizam o GitHub Actions para automatizar as suas compilações, demonstrando que esta é a prática padrão na comunidade.  

### 5.2 Anatomia de um Workflow de Compilação para um External de Pd

A chave para resolver o problema da compilação multiplataforma com CI/CD é a utilização de uma matriz de compilação (`build matrix`). Uma matriz permite definir múltiplas configurações para um único job, e o GitHub Actions irá executar uma instância do job para cada combinação de configuração em paralelo.

**Tabela 3: Exemplo de Matriz de Compilação no GitHub Actions**

O seguinte trecho de YAML define uma matriz que irá gerar jobs para Windows, Linux e macOS.

YAML

```
jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        # Adicione outras variáveis de matriz se necessário, como versões do Pd
        # pd_version: ['0.54-1', '0.55-0']
    runs-on: ${{ matrix.os }}
    steps:
      #... passos de compilação aqui...
```

Um workflow típico para um external de Pd consistirá nos seguintes passos dentro de cada job da matriz:

1. **Checkout do Código**: Utilizar a ação `actions/checkout@v4` para obter o código fonte do repositório.  
    
2. **Configurar Dependências**: Instalar as ferramentas necessárias no runner, como `make`, `cmake`, compiladores C/C++, Python3 (para o Deken), etc.
    
3. **Compilar o External**: Executar o comando de compilação apropriado, seja `make` (para `pd-lib-builder`) ou `cmake --build` (para `pd.cmake`). Para o job de macOS, este passo incluiria os argumentos para criar um binário universal.
    
4. **Empacotar para o Deken**: Executar o comando `deken package` no diretório que contém os binários compilados para criar o ficheiro `.dek` corretamente nomeado.
    
5. **Upload do Artefacto**: Utilizar a ação `actions/upload-artifact@v4` para guardar o ficheiro `.dek` resultante. Isto permite que seja descarregado manualmente ou utilizado por um job subsequente.  
    

### 5.3 Estudo de Caso: Um Workflow Completo para um Projeto `pd.cmake`

Abaixo está um exemplo completo e comentado de um ficheiro `.github/workflows/main.yml`. Este workflow compila um external para Windows (64-bit), Linux (64-bit) e macOS (universal `x86_64` + `arm64`), e também cria um pacote de fontes.

YAML

```
name: Build and Package External

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  release:
    types: [ published ]

jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]

    runs-on: ${{ matrix.os }}
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      with:
        submodules: 'recursive' # Se usar pd.cmake ou pd-lib-builder como submódulo

    - name: Set up Python for Deken
      uses: actions/setup-python@v5
      with:
        python-version: '3.x'

    - name: Install Deken
      run: pip install deken

    - name: Configure CMake (Linux)
      if: runner.os == 'Linux'
      run: cmake -B build -S.

    - name: Configure CMake (Windows)
      if: runner.os == 'Windows'
      run: cmake -B build -S. -G "Visual Studio 17 2022" -A x64

    - name: Configure CMake (macOS Universal)
      if: runner.os == 'macOS'
      run: cmake -B build -S. -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"

    - name: Build with CMake
      run: cmake --build build --config Release

    - name: Package with Deken
      run: deken package build/MyLibName --version ${{ github.ref_name }}

    - name: Upload Artifact
      uses: actions/upload-artifact@v4
      with:
        name: deken-package-${{ runner.os }}
        path: "*.dek"

  create-source-package:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
    
    - name: Set up Python for Deken
      uses: actions/setup-python@v5
      with:
        python-version: '3.x'

    - name: Install Deken
      run: pip install deken
      
    - name: Package Sources with Deken
      run: deken package. --version ${{ github.ref_name }}

    - name: Upload Source Artifact
      uses: actions/upload-artifact@v4
      with:
        name: deken-package-Sources
        path: "*.dek"
```

### 5.4 Automatizando a Implantação no Deken (Avançado)

O passo final é automatizar o upload para o Deken. Esta é uma operação sensível, pois requer credenciais. A melhor prática é criar um job separado que só é executado quando uma `release` é criada no GitHub.

Este job de "deploy" iria:

1. Ser acionado `on: release: types: [published]`.
    
2. Descarregar todos os artefactos `.dek` dos jobs de compilação usando `actions/download-artifact`.
    
3. Executar `deken login` e `deken upload *.dek`. O nome de utilizador e a palavra-passe do Deken seriam armazenados de forma segura como **GitHub Secrets** no repositório e acedidos no workflow através de `${{ secrets.DEKEN_USERNAME }}` e `${{ secrets.DEKEN_PASSWORD }}`.
    

A adoção de CI/CD altera fundamentalmente a economia e a fiabilidade da manutenção de um external de Pd. Sem CI, um desenvolvedor precisa de acesso físico ou virtual a máquinas Windows, Mac e Linux para fazer um lançamento completo, uma barreira de custo e tempo significativa. Com CI, o desenvolvedor precisa apenas de um editor de texto e um navegador. O GitHub fornece a infraestrutura de compilação gratuitamente para repositórios públicos. Isto democratiza o desenvolvimento multiplataforma para a comunidade Pd, reduzindo drasticamente a barreira de entrada e garantindo que o processo de compilação, definido como código no ficheiro de workflow, seja idêntico e reprodutível a cada execução, eliminando os problemas de "funciona na minha máquina". O resultado é um ecossistema mais saudável, com mais externals, mais bem mantidos e compilados de forma mais fiável.  

## Secção 6: Um Guia Completo: Do Código Fonte ao Deken

As secções anteriores estabeleceram a teoria e os conceitos por trás de um fluxo de trabalho de distribuição moderno. Esta secção irá tornar esses conceitos concretos através de um tutorial prático e passo a passo. Iremos criar um external "helloworld" canónico, configurar um sistema de compilação para ele, e construir um pipeline de CI/CD no GitHub para o compilar e empacotar automaticamente para todas as plataformas.

### Passo 1: O Código Fonte

Primeiro, crie os ficheiros de código fonte para um external simples que imprime "Hello world!!" na consola do Pd quando recebe um bang. A estrutura e o código são baseados nos exemplos do `externals-howto` da comunidade Pd.  

Crie um ficheiro chamado `helloworld.c`:

C

```
#include "m_pd.h"

static t_class *helloworld_class;

typedef struct _helloworld {
    t_object x_obj;
} t_helloworld;

void helloworld_bang(t_helloworld *x) {
    post("Hello world!!");
}

void *helloworld_new(void) {
    t_helloworld *x = (t_helloworld *)pd_new(helloworld_class);
    return (void *)x;
}

void helloworld_setup(void) {
    helloworld_class = class_new(gensym("helloworld"),
        (t_newmethod)helloworld_new,
        0, sizeof(t_helloworld),
        CLASS_DEFAULT, 0);
    class_addbang(helloworld_class, helloworld_bang);
}
```

Crie também um ficheiro de ajuda, `helloworld-help.pd`, para que os utilizadores possam aprender a usar o seu objeto.

### Passo 2: Escolher e Configurar o Sistema de Compilação

Agora, escolha um sistema de compilação. Iremos fornecer a configuração para ambos, `pd-lib-builder` e `pd.cmake`. Escolha o que preferir e adicione o ficheiro correspondente ao seu projeto.

**Opção A: `pd-lib-builder`** Crie um ficheiro chamado `Makefile`:

Makefile

```
lib.name = helloworld
class.sources = helloworld.c
datafiles = helloworld-help.pd

# Assumindo que pd-lib-builder está num subdiretório
PDLIBBUILDER_DIR=pd-lib-builder
include $(PDLIBBUILDER_DIR)/Makefile.pdlibbuilder
```

**Opção B: `pd.cmake`** Crie um ficheiro chamado `CMakeLists.txt`:

CMake

```
cmake_minimum_required(VERSION 3.18)
project(helloworld)

# Assumindo que pd.cmake está num subdiretório
set(PDCMAKE_DIR pd.cmake/ CACHE PATH "Path to pd.cmake")
include(${PDCMAKE_DIR}/pd.cmake)

pd_add_external(helloworld SOURCES helloworld.c)
pd_add_datafile(helloworld-help.pd)
```

### Passo 3: Criar o Repositório GitHub

1. Crie um novo repositório público no GitHub.
    
2. Clone o repositório para a sua máquina local.
    
3. Adicione os seus ficheiros (`helloworld.c`, `helloworld-help.pd`, e o seu `Makefile` ou `CMakeLists.txt`) ao repositório.
    
4. Se estiver a usar `pd-lib-builder` ou `pd.cmake`, adicione-os como submódulos Git para uma gestão de dependências mais limpa:
    
    - Para `pd-lib-builder`: `git submodule add https://github.com/pure-data/pd-lib-builder.git`
        
    - Para `pd.cmake`: `git submodule add https://github.com/pure-data/pd.cmake.git`
        
5. Faça commit e push dos seus ficheiros para o GitHub.
    

### Passo 4: Escrever o Workflow do GitHub Actions

Crie a seguinte estrutura de diretórios no seu projeto: `.github/workflows/`. Dentro desse diretório, crie um ficheiro chamado `main.yml` e cole o conteúdo do workflow da Secção 5, adaptando o nome da biblioteca se necessário (por exemplo, `path: build/helloworld` no passo de empacotamento Deken se estiver a usar `pd.cmake`).

### Passo 5: Acionar a Compilação

Faça commit e push do seu ficheiro `main.yml` para o repositório. Isto irá acionar automaticamente o workflow. Navegue para o separador "Actions" no seu repositório GitHub para monitorizar o progresso. Verá os jobs para Linux, Windows e macOS a serem executados em paralelo. Se tudo correr bem, todos os jobs deverão terminar com um visto verde.

### Passo 6: Recuperar os Artefactos

Quando o workflow estiver concluído, clique na execução do workflow para ver a página de resumo. Na parte inferior, verá uma secção "Artifacts". Deverá haver um artefacto para cada job de compilação (por exemplo, `deken-package-ubuntu-latest`, `deken-package-windows-latest`, `deken-package-macos-latest`) e um para as fontes (`deken-package-Sources`). Descarregue cada um destes artefactos. Eles serão ficheiros `.zip` que contêm os seus pacotes `.dek`.

### Passo 7: Upload Manual para o Deken

Este último passo é executado localmente na sua máquina. Descomprima os artefactos que descarregou para ter todos os ficheiros `.dek` num único diretório. Abra um terminal nesse diretório e use a ferramenta `deken` para fazer o upload.

1. Faça login na sua conta `puredata.info` (só precisa de fazer isto uma vez): `deken login`
    
2. Faça o upload de todos os pacotes `.dek`: `deken upload *.dek`
    

A ferramenta irá pedir-lhe para confirmar o upload para cada ficheiro. Após a confirmação, os seus pacotes de externals estarão disponíveis para a comunidade Pd através do "Find Externals".

Ao seguir estes passos, transformou um processo manual e propenso a erros num pipeline de desenvolvimento robusto e automatizado. Este fluxo de trabalho não só poupa tempo e esforço, mas também aumenta drasticamente a qualidade e a acessibilidade dos seus externals, garantindo que utilizadores em todas as principais plataformas possam beneficiar do seu trabalho.

## Secção 7: Conclusão: Melhores Práticas e Perspetivas Futuras

A jornada desde o código fonte de um external de Pure Data até à sua distribuição global através do Deken evoluiu de um processo artesanal para uma disciplina de engenharia de software sofisticada. A adoção de ferramentas modernas e fluxos de trabalho automatizados não é apenas uma conveniência, mas uma necessidade para garantir a fiabilidade, manutenibilidade e alcance de um projeto no ecossistema atual. Este guia detalhou um caminho claro para alcançar este nível de profissionalismo.

### Resumo das Melhores Práticas

Para os desenvolvedores de externals que procuram modernizar o seu processo de distribuição, as seguintes práticas são fundamentais:

- **Adotar a Automação da Compilação**: Utilize um sistema de compilação padronizado como `pd-lib-builder` ou `pd.cmake`. Isto elimina a dependência de scripts de compilação específicos da plataforma e cria um processo de compilação único e reprodutível.
    
- **Automatizar o Fluxo de Trabalho com CI/CD**: Integre o seu sistema de compilação com um serviço de CI/CD como o GitHub Actions. Isto permite compilações e testes automáticos em todas as plataformas alvo a cada alteração de código, garantindo a deteção precoce de problemas.
    
- **Fornecer Sempre Binários Universais para macOS**: Dada a prevalência de máquinas Mac baseadas em Intel e Apple Silicon, a criação de binários universais (`x86_64` + `arm64`) é essencial. As ferramentas modernas tornam este processo trivial.
    
- **Distribuir Sempre o Código Fonte**: Faça sempre o upload de um pacote `(Sources)` para o Deken. Isto não só cumpre os requisitos de muitas licenças de código aberto, mas também fomenta a confiança e a colaboração dentro da comunidade.
    
- **Utilizar o CLI `deken`**: Confie na ferramenta de linha de comandos `deken` para empacotar e fazer o upload dos seus externals. A sua capacidade de inspecionar binários para gerar nomes de ficheiros corretos é uma funcionalidade crucial que previne erros.
    
- **Manter as Ferramentas Atualizadas**: O ecossistema de desenvolvimento está em constante evolução. Mantenha as suas dependências de compilação, como o `pd-lib-builder` ou o `pd.cmake` (idealmente geridos como submódulos Git), atualizadas para beneficiar de correções de bugs e suporte para novas plataformas.
    

### Perspetivas Futuras

O panorama da computação continua a mudar, e o ecossistema de desenvolvimento do Pd terá de se adaptar. Algumas tendências e desafios futuros incluem:

- **Novas Plataformas**: O surgimento do Windows em arquiteturas ARM (`arm64`) apresenta um novo alvo de compilação. Embora ainda não seja predominante, os sistemas de compilação e os pipelines de CI terão de incorporar suporte para esta plataforma para garantir uma cobertura completa.  
    
- **Automação Avançada**: O pipeline de CI/CD pode ser expandido para além da compilação e empacotamento. A automação pode ser usada para gerar documentação, criar notas de lançamento a partir de mensagens de commit, e até mesmo publicar anúncios em fóruns da comunidade ou redes sociais após um novo lançamento.
    
- **Segurança da Cadeia de Suprimentos**: À medida que o ecossistema amadurece, a segurança torna-se uma preocupação maior. A verificação de assinaturas GPG pelo cliente Deken, que atualmente é um processo manual , poderá ser automatizada no futuro, aumentando a confiança nos pacotes descarregados.  
    

Em última análise, a saúde e a vitalidade da comunidade Pure Data são um reflexo direto da força das suas ferramentas de código aberto e da dedicação dos seus desenvolvedores. Ao adotar as práticas modernas aqui delineadas, os criadores de externals não só simplificam as suas próprias vidas, mas também contribuem para um ecossistema mais robusto, acessível e dinâmico para todos os utilizadores de Pd. A capacidade de ir de uma linha de código a uma distribuição global e multiplataforma com um único `git push` é um testemunho poderoso do que esta comunidade construiu coletivamente.