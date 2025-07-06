# Criação dinâmica dos placeholders do bundle moderno do py4pd
mkdir -p dist
touch dist/py4pd.dll
touch dist/py4pd.pd_linux
touch dist/py4pd.pd_darwin
touch dist/py4pd-py3.11.dll
touch dist/py4pd-py3.12.dll
touch dist/py4pd-bootstrap.sh
cat > dist/README.txt <<EOF
# py4pd - Estrutura do Bundle Moderno (placeholders)

Este diretório contém arquivos gerados dinamicamente para o bundle moderno do py4pd.
Todos os arquivos abaixo são placeholders (vazios) e servem apenas para ilustrar a estrutura de distribuição.

- py4pd.dll           Loader C para Pure Data no Windows
- py4pd.pd_linux      Loader C para Pure Data no Linux
- py4pd.pd_darwin     Loader C para Pure Data no macOS
- py4pd-py3.11.dll    Binário real do py4pd para Python 3.11
- py4pd-py3.12.dll    Binário real do py4pd para Python 3.12
- py4pd-bootstrap.sh  Script de bootstrap multiplataforma

Estes arquivos são placeholders e não possuem implementação funcional.
EOF
#!/usr/bin/env bash
set -e

PY_VERSIONS=("3.11" "3.12")
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Limpando diretórios build/ e dist/"
rm -rf "$ROOT_DIR/build" "$ROOT_DIR/dist"
mkdir -p "$ROOT_DIR/dist"

for PYV in "${PY_VERSIONS[@]}"; do
  BUILD_DIR="$ROOT_DIR/build/py$PYV"
  echo "==> Compilando para Python $PYV"
  mkdir -p "$BUILD_DIR"
  cmake -B "$BUILD_DIR" -DPY4PD_PYTHON_VERSION="$PYV"
  cmake --build "$BUILD_DIR"
  BIN=$(find "$BUILD_DIR" -type f -name "py4pd.*" | head -n 1)
  if [ -f "$BIN" ]; then
    EXT="${BIN##*.}"
    cp "$BIN" "$ROOT_DIR/dist/py4pd-$PYV.$EXT"
    echo "  -> Binário copiado para dist/py4pd-$PYV.$EXT"
  else
    echo "  !! Binário não encontrado para Python $PYV"
    exit 1
  fi
done

echo "==> Build finalizado com sucesso!"