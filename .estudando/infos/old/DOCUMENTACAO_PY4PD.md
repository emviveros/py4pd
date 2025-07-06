# Guia de Mensagens do py4pd

## O que é o py4pd?

O `py4pd` é uma ferramenta que permite criar objetos para o Pure Data (Pd) usando Python, facilitando a integração entre o ambiente gráfico do Pd e o poder do Python.

---

## Como o py4pd recebe mensagens?

Quando você cria um objeto `py4pd` no Pd, pode enviar mensagens para ele (como "reload", "set", "run", etc). Essas mensagens se dividem em dois grupos:

- **Mensagens nativas:** já vêm prontas no py4pd, feitas em C, e funcionam sempre.
- **Mensagens roteadas para Python:** qualquer mensagem é aceita e roteada automaticamente para um método Python correspondente, mesmo que você não tenha implementado esse método ainda.

---

## Tabela 1: Mensagens Nativas (sempre disponíveis)

Estas mensagens funcionam assim que você cria o objeto `py4pd`, mesmo sem carregar nenhum script Python:

| Mensagem   | O que faz? | Como usar no Pd | Onde está no código |
|------------|------------|-----------------|--------------------|
| reload     | Recarrega o script Python | `;py4pd reload` | [`Sources/module.c:1294`](Sources/module.c#L1294) |
| tabread    | Lê dados de um array do Pd | `;py4pd tabread nome_array` | [`Sources/module.c:1290`](Sources/module.c#L1290) |
| tabwrite   | Escreve dados em um array do Pd | `;py4pd tabwrite nome_array 1 2 3` | [`Sources/module.c:1288`](Sources/module.c#L1288) |
| logpost    | Mostra mensagens no console do Pd | `;py4pd logpost 2 "Olá"` | [`Sources/module.c:1279`](Sources/module.c#L1279) |
| error      | Mostra mensagens de erro | `;py4pd error "Deu erro"` | [`Sources/module.c:1280`](Sources/module.c#L1280) |
| out        | Envia dados para as saídas do objeto | `;py4pd out 0 0 42` | [`Sources/module.c:1283`](Sources/module.c#L1283) |
| new_clock  | Cria um relógio (clock) para agendar funções | (usado em Python) | [`Sources/clock.c:79`](Sources/clock.c#L79) |

**Exemplo prático:**
```pd
;py4pd reload
```
Isso recarrega o script Python associado ao objeto.


**Exemplo prático:**
No Pd:
```pd
;py4pd set 42
```
No seu script Python:
```python
def in_1_set(self, valor):
    print("Recebi o valor:", valor)
```
Se você não implementar o método, verá um aviso no console, mas a mensagem será aceita.

---

## Como funciona o roteamento de mensagens?

Quando você envia uma mensagem para o objeto py4pd, o seguinte acontece:

1. Se for uma das mensagens nativas, o py4pd executa uma função pronta em C.
2. Se for qualquer outra mensagem, o py4pd SEMPRE aceita e roteia para um método Python chamado `in_1_<mensagem>`.
   - Se encontrar, executa o método.
   - Se não encontrar, mostra um aviso no console e nada acontece.

**Referências no código:**
- Roteamento universal: [`Sources/proxyinlets.c:17`](Sources/proxyinlets.c#L17), [`Sources/proxyinlets.c:89`](Sources/proxyinlets.c#L89)
- Execução do método Python: [`Sources/module.c:402`](Sources/module.c#L402)

---

## Diagrama do fluxo de mensagens

```mermaid
flowchart TD
    PdMensagem["Mensagem Pd"] -->|Nativa| MetodoC["Método C nativo"]
    PdMensagem -->|Outra (qualquer)| Proxy["proxyinlets.c:17"] --> MetodoPython["Método Python in_1_<mensagem> (no seu script)"]
    MetodoPython -->|Se não existe| Aviso["Aviso no console"]
```

---

## Exemplos práticos

### Usando mensagem nativa

No Pd:
```
;py4pd reload
```
Resultado: recarrega o script Python.

### Usando mensagem roteada para Python

No Pd:
```
;py4pd set 42
```
No Python:
```python
def in_1_set(self, valor):
    print("Recebi o valor:", valor)
```
Resultado: imprime "Recebi o valor: 42" no console.

---

## Dicas finais

- Todas as mensagens são aceitas pelo py4pd, mesmo que você não tenha implementado o método Python correspondente.
- As mensagens nativas sempre funcionam, independentemente do script Python.
- Para criar novas mensagens, basta implementar o método Python correspondente no seu script.
- Se você enviar uma mensagem sem implementar o método, verá um aviso no console do Pd.

---

## Para saber mais

- Métodos nativos: [`pdpy_methods`](Sources/module.c#L1278)
- Roteamento: [`pdpy_proxy_anything`](Sources/proxyinlets.c#L4), [`pdpy_execute`](Sources/module.c#L396)
- Exemplo de script Python padrão: [`Sources/py4pd/py.pip.pd_py`](Sources/py4pd/py.pip.pd_py)