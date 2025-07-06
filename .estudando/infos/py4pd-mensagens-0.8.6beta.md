# Mensagens Registradas no Código-Fonte (`py4pd_setup`)

Este quadro mostra exatamente as mensagens aceitas pelo objeto `[py4pd]` conforme registradas no código C (`py4pd_setup`). Cada linha corresponde a um `class_addmethod` ou similar, indicando o nome da mensagem, a função C associada e o tipo de argumento aceito.

---

## Tabela das Mensagens e Funções

| Mensagem      | Função C associada                | Tipo de argumento      | Observação                        |
|---------------|-----------------------------------|-----------------------|-----------------------------------|
| home          | Py4pd_SetPy4pdHomePath            | A_GIMME               | Caminho home do py4pd             |
| packages      | Py4pd_SetPackages                 | A_GIMME               | Caminho dos pacotes Python        |
| pip           | Py4pd_Pip                         | A_GIMME               | Instalação de pacotes Python      |
| pointers      | Py4pd_SetPythonPointersUsage       | A_FLOAT               | Ativa/desativa ponteiros numpy    |
| reload        | Py4pd_ReloadPy4pdFunction         | -                     | Recarrega script Python           |
| pipinstall    | Py4pd_Deprecated                  | A_GIMME               | Obsoleto, use pip install         |
| version       | Py4pd_PrintPy4pdVersion           | -                     | Versão do py4pd e Python          |
| editor        | Py4pd_SetEditor                   | A_GIMME               | Define editor de código           |
| open          | Py4pd_OpenScript                  | A_GIMME               | Abre script no editor             |
| create        | Py4pd_OpenScript                  | A_GIMME               | Cria e abre novo script           |
| click         | Py4pd_SetEditor                   | -                     | Abre editor (UI/click)            |
| doc           | Py4pd_PrintDocs                   | -                     | Exibe documentação da função      |
| run           | Py4pd_ExecuteFunction             | A_GIMME               | Executa função Python             |
| set           | Py4pd_SetFunction                 | A_GIMME               | Define função Python a ser chamada|
| functions     | Py4pd_PrintModuleFunctions         | A_GIMME               | Lista funções do módulo Python    |

---

## Trecho do Código-Fonte

```c
class_addmethod(py4pd_class, (t_method)Py4pd_SetPy4pdHomePath,
                gensym("home"), A_GIMME, 0);
class_addmethod(py4pd_class, (t_method)Py4pd_SetPackages,
                gensym("packages"), A_GIMME, 0);
class_addmethod(py4pd_class, (t_method)Py4pd_Pip, gensym("pip"), A_GIMME, 0);
class_addmethod(py4pd_class, (t_method)Py4pd_SetPythonPointersUsage,
                gensym("pointers"), A_FLOAT, 0);
class_addmethod(py4pd_class, (t_method)Py4pd_ReloadPy4pdFunction,
                gensym("reload"), 0, 0);
// DEPRECATED
class_addmethod(py4pd_class, (t_method)Py4pd_Deprecated,
                gensym("pipinstall"), A_GIMME, 0);
// Object INFO
class_addmethod(py4pd_class, (t_method)Py4pd_PrintPy4pdVersion,
                gensym("version"), 0, 0);
class_addmethod(py4pd_class, (t_method)Py4pd_SetEditor, gensym("editor"),
                A_GIMME, 0);
class_addmethod(py4pd_class, (t_method)Py4pd_OpenScript, gensym("open"),
                A_GIMME, 0);
class_addmethod(py4pd_class, (t_method)Py4pd_OpenScript, gensym("create"),
                A_GIMME, 0);
class_addmethod(py4pd_class, (t_method)Py4pd_SetEditor, gensym("click"), 0, 0);
class_addmethod(py4pd_classLibrary, (t_method)Py4pd_SetEditor,
                gensym("click"), 0, 0);
// User
class_addmethod(py4pd_class, (t_method)Py4pd_PrintDocs, gensym("doc"), 0, 0);
class_addmethod(py4pd_class, (t_method)Py4pd_ExecuteFunction, gensym("run"),
                A_GIMME, 0);
class_addmethod(py4pd_class, (t_method)Py4pd_SetFunction, gensym("set"),
                A_GIMME, 0);
class_addmethod(py4pd_class, (t_method)Py4pd_PrintModuleFunctions,
                gensym("functions"), A_GIMME, 0);
```

---

## Observações Técnicas

- Todas as mensagens acima são aceitas pelo objeto `[py4pd]` e mapeadas diretamente para funções C.
- Mensagens como `open`, `create`, `editor`, `click` também são aceitas por objetos do tipo `py4pd_classLibrary`.
- O tipo de argumento (`A_GIMME`, `A_FLOAT`, `0`) define como a mensagem é tratada internamente.
- Mensagens não listadas acima não são reconhecidas pelo objeto, a menos que adicionadas em futuras versões.

---

## Referência Rápida

- **A_GIMME**: Aceita qualquer número/tipo de argumentos.
- **A_FLOAT**: Aceita apenas um argumento float.
- **0**: Não aceita argumentos.

---

Esta tabela reflete fielmente o que está registrado no código-fonte da função `py4pd_setup` e serve como referência para integração, extensão ou depuração do external.