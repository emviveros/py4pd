#!/usr/bin/env bash
set -e

echo "==[ py4pd :: Setup do ambiente de desenvolvimento (Linux/macOS) ]=="

# Checa se o uv está instalado
if ! command -v uv &>/dev/null; then
  echo "-> 'uv' não encontrado. Instalando via script oficial..."
  curl -Ls https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
else
  echo "-> 'uv' já está instalado."
fi

# Instala Python 3.11
if uv pip --python 3.11 --version &>/dev/null; then
  echo "-> Python 3.11 já disponível via uv."
else
  echo "-> Instalando Python 3.11 via uv..."
  uv pip --python 3.11 --version >/dev/null
fi

# Instala Python 3.12
if uv pip --python 3.12 --version &>/dev/null; then
  echo "-> Python 3.12 já disponível via uv."
else
  echo "-> Instalando Python 3.12 via uv..."
  uv pip --python 3.12 --version >/dev/null
fi

echo "==[ Ambiente de desenvolvimento pronto! ]=="