#!/usr/bin/env bash
set -e
echo "==[ Limpando ambiente de desenvolvimento py4pd ]=="

# Remove o ambiente virtual local
if [ -d ".venv" ]; then
    echo "-> Removendo ambiente virtual .venv..."
    rm -rf .venv
fi

# Remove a pasta de build
if [ -d "build" ]; then
    echo "-> Removendo pasta de build..."
    rm -rf build
fi

# Remove o cache global do uv
if [ -d "$HOME/.uv" ]; then
    echo "-> Removendo cache global do uv ($HOME/.uv)..."
    rm -rf "$HOME/.uv"
fi

# Remove o binário do uv
if [ -f "$HOME/.local/bin/uv" ]; then
    echo "-> Removendo binário do uv..."
    rm -f "$HOME/.local/bin/uv"
fi

echo ""
echo "✅ Ambiente limpo com sucesso!"
echo "Agora você pode executar o script de setup novamente."