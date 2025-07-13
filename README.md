<p align="center">
  <a href="https://charlesneimog.github.io/py4pd/">
    <img src="https://raw.githubusercontent.com/charlesneimog/py4pd/master/Documentation/assets/py4pd.svg" alt="Logo" width=100 height=58>
  </a>
  <h1 align="center">py4pd</h1>
  <h4 align="center">Python in the PureData environment.</h4>
</p>
<p align="center">
    <a href="https://github.com/charlesneimog/py4pd/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-GPL--v3-blue.svg" alt="License"></a>
    <a href="https://github.com/charlesneimog/py4pd/releases/latest"><img src="https://img.shields.io/github/release/charlesneimog/py4pd.svg?include_prereleases" alt="Release"></a>
    <a href="https://doi.org/10.5281/zenodo.10247117"><img src="https://zenodo.org/badge/DOI/10.5281/zenodo.10247117.svg" alt="DOI"></a>
</p>
    
<p align="center">
  <a href="https://github.com/charlesneimog/py4pd/actions/workflows/Builder.yml"><img src="https://github.com/charlesneimog/py4pd/actions/workflows/Builder.yml/badge.svg?branch=master"></a>
</p>

> [!IMPORTANT]  
> `py4pd` will be updated to a more maintainable and simplified version. You can check it out on the `py4pd-1.0.0` branch, with some examples available at https://github.com/charlesneimog/py4pd/issues/98#issuecomment-2745326771.
> 
py4pd allows write PureData Objects using Python instead of C/C++. The main goal is to allow easy IA, Scores, Graphics, and bring to Pd possibilities with array, list and others types. With Python, you can:
* Use scores inside PureData;
* Use svg/draws as scores;
* OpenMusic functions in libraries like `om_py`, `music21`, `neoscore`, and others;
* Sound analisys with `magenta`, `librosa`, and `pyAudioAnalaysis`;

## Wiki | How to install and Use

* Go to [Docs](https://charlesneimog.github.io/py4pd).

## For Developers

Just one thing, the development of this object occurs in de `develop` branch, the main branch corresponds to the last release available in `Deken`.

### New Pd Object using Python

``` py
import pd

def mylistsum(x, y):
    x_sum = sum(x)
    y_sum = sum(y)
    return x_sum + y_sum

def mylib_setup():
    pd.add_object(mylistsum, "py.listsum")
``` 

## Building from Source

### Pré-requisitos Automatizados
* Execute o script de setup correspondente ao seu sistema operacional:
  ```sh
  # Linux/macOS
  ./scripts/setup_dev_env.sh
  
  # Windows
  scripts\setup_dev_env.bat
  ```

### Compilação
```sh
# Configurar o build (exemplo com flags)
cmake -B build -DPD_INSTALL_DIR=/caminho/para/pure-data -DPY4PD_PYTHON_VERSION=3.11

# Compilar
cmake --build build

# Instalar no diretório de externals do Pd
cmake --install build
```

### Opções de Build
| Flag CMake               | Descrição                          | Padrão   |
|--------------------------|------------------------------------|----------|
| `PD_INSTALL_DIR`         | Caminho para instalação do Pure Data | Requerido|
| `PY4PD_PYTHON_VERSION`   | Versão do Python (3.10+)           | 3.11     |
| `PY4PD_USE_UV`           | Usar `uv` para ambientes Python    | ON       |

### Boas Práticas
* O script de setup configura automaticamente:
  - Ambientes Python isolados via `uv`
  - Dependências de compilação
  - Estrutura de build multiplataforma
* Consulte [Documentação Técnica](.estudando/Guia de Arquitetura e Compilação do py.md) para detalhes avançados


