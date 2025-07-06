# context.md

Qual o foco atual do trabalho?
- Atualizar e expandir a documentação técnica do py4pd, detalhando arquitetura, automação de setup/build, integração Python-Pd, exemplos práticos e fluxos de manutenção, com base no código-fonte, scripts e exemplos reais.

Houve mudanças recentes relevantes?
- Criação e padronização dos scripts multiplataforma de setup e build (`setup_dev_env.sh`, `setup_dev_env.bat`, `build_all.sh`, `build_all.bat`), com suporte explícito a múltiplas versões de Python.
- Estrutura de distribuição moderna com placeholders e documentação automática no bundle.
- Expansão dos exemplos integrados Python/Pd, cobrindo áudio, manipulação de dados, criação de objetos customizados e fluxos visuais.
- Registro formal de tarefas repetitivas em `tasks.md` (ex: adicionar nova versão Python, criar novo exemplo).
- Consolidação do fluxo de build determinístico e multiplataforma.
- Ajustes nos fontes C para integração robusta com múltiplas versões de Python e inicialização automática do ambiente.

Quais os próximos passos planejados?
- Finalizar e revisar a documentação técnica e de onboarding para alinhar com os fluxos reais do projeto.
- Incluir fluxogramas, tabelas de mensagens e exemplos visuais na documentação.
- Validar o processo de build e integração em todos os sistemas suportados.
- Ajustar exemplos e documentação conforme feedback de usuários e mantenedores.