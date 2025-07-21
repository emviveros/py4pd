## Adicionar Suporte a Nova Versão do Python
**Última execução:** 2025-06-07
**Arquivos a modificar:**
- `scripts/setup_dev_env.sh` – Adicionar novo bloco para instalar a versão desejada via `uv`
- `scripts/setup_dev_env.ps1` – Adicionar novo bloco para instalar a versão desejada via `uv`
- `scripts/build_all.sh` – Incluir a nova versão no array `PY_VERSIONS`
- `scripts/build_all.ps1` – Incluir a nova versão na variável `PY_VERSIONS`
- `CMakeLists.txt`/`Makefile` – Garantir flags e targets para a nova versão
- Documentação relevante (README, etc.)

**Passos:**
1. Adicionar a nova versão Python nos scripts de setup, garantindo:
   - No [`scripts/setup_dev_env.ps1`](scripts/setup_dev_env.ps1:1): incluir a versão desejada no array `$PY_VERSIONS` e garantir o bloco correspondente com os comandos `uv python install <versão>` e `uv venv -p <versão> .venv-<versão>`, seguindo o padrão já existente para múltiplas versões.
   - No [`scripts/setup_dev_env.sh`](scripts/setup_dev_env.sh:1): incluir a versão no array equivalente e garantir o fluxo de criação do ambiente Python para a nova versão.
2. Incluir a nova versão no array/variável de versões dos scripts de build.
3. Garantir que o build gere binários nomeados corretamente para a nova versão.
4. Atualizar documentação e exemplos, se necessário.
5. Testar o build e a integração no Pure Data.

**Notas importantes:**
- Garanta que todas as plataformas suportadas (Windows, Linux, macOS) recebam suporte equivalente, mesmo que os scripts de build e setup sejam separados para cada sistema.
- Teste o loader e os binários em todos os sistemas suportados.
- Atualize exemplos se houver mudanças de compatibilidade.

---

## Criar Novo Exemplo Integrado Python/Pd
**Última execução:** 2025-06-07
**Arquivos a modificar:**
- `Documentation/examples/<nome>/main.py`
- `Documentation/examples/<nome>/patch.pd`
- Imagens, áudios ou outros recursos de apoio
- Documentação de exemplos, se aplicável

**Passos:**
1. Criar diretório para o novo exemplo.
2. Implementar script Python e patch Pd integrados.
3. Adicionar recursos visuais/áudio, se necessário.
4. Documentar o exemplo (README, imagens, GIFs).
5. Validar funcionamento no Pure Data.

**Notas importantes:**
- Siga o padrão dos exemplos existentes para facilitar o onboarding.
- Inclua comentários explicativos nos scripts e patches.
- Teste em múltiplos sistemas, se possível.