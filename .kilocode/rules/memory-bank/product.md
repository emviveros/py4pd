# product.md

Por que este projeto existe?
- O projeto existe para permitir a integração direta entre Pure Data (Pd) e Python, facilitando a criação de objetos Pd que executam scripts Python, ampliando as possibilidades criativas e computacionais dentro do ambiente Pd.

Que problema resolve?
- Resolve a limitação do Pure Data em executar lógica avançada, manipulação de dados, inteligência artificial e automação, ao permitir que qualquer usuário utilize o poder do Python em patches Pd sem precisar programar em C/C++.

Como o usuário final deve interagir com o produto?
- O usuário instancia o objeto `[py4pd]` em seu patch Pd e envia mensagens (ex: `pip install PACKAGE`, `set`, `run`, etc). Essas mensagens são roteadas para métodos Python definidos em scripts `.pd_py`, permitindo customização e extensão dinâmica do comportamento do objeto Pd.

Quais objetivos de experiência do usuário são esperados?
- Facilidade de uso para integrar Python ao Pd.
- Documentação clara e exemplos práticos.
- Flexibilidade para criar e estender funcionalidades sem recompilar.
- Feedback imediato no console do Pd para erros e logs.
- Compatibilidade com fluxos criativos e experimentais do público-alvo.