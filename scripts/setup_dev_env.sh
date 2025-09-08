#!/usr/bin/env bash
set -e

echo "==[ py4pd :: Setup do ambiente de desenvolvimento (Linux/macOS) ]=="

# Detecta SO e define UV_BIN do bundle
if [[ "$(uname)" == "Darwin" ]]; then
  UV_BIN="Resources/uv/uv-macos"
elif [[ "$(uname)" == "Linux" ]]; then
  UV_BIN="Resources/uv/uv-linux"
else
  echo "SO não suportado para este script."
  exit 1
fi

chmod +x "$UV_BIN"

# Instala Python 3.11 usando uv do bundle
if "$UV_BIN" pip --python 3.11 --version &>/dev/null; then
  echo "-> Python 3.11 já disponível via uv."
else
  echo "-> Instalando Python 3.11 via uv embutido..."
  "$UV_BIN" pip --python 3.11 --version >/dev/null
fi

# Instala Python 3.12 usando uv do bundle
if "$UV_BIN" pip --python 3.12 --version &>/dev/null; then
  echo "-> Python 3.12 já disponível via uv."
else
  echo "-> Instalando Python 3.12 via uv embutido..."
  "$UV_BIN" pip --python 3.12 --version >/dev/null
fi

echo "==[ Ambiente de desenvolvimento pronto! ]=="