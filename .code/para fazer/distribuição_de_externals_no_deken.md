**O Tratamento Atual no Deken:**

O Deken funciona como um repositório onde os desenvolvedores podem fazer o upload de seus externals em formato de pacote, geralmente um arquivo .zip. Para que o Deken possa apresentar a versão correta para o usuário, o desenvolvedor precisa nomear o arquivo de uma maneira específica que inclua a arquitetura do sistema.

A convenção de nomenclatura, conforme a documentação para desenvolvedores do Deken, segue o formato `NOME_DO_EXTERNAL-VERSÃO-(SISTEMA-ARQUITETURA-BITS)-externals.zip`. Por exemplo:

* `freeverb~-v0.1-(Linux-amd64-64)-externals.zip` para Linux de 64 bits.
* `freeverb~-v0.1-(Darwin-x86_64-64)-externals.zip` para macOS de 64 bits.
* `freeverb~-v0.1-(Windows-i386-32)-externals.zip` para Windows de 32 bits.

Quando um usuário busca por um external no Deken (através da interface gráfica do Pd), o Deken tenta identificar o sistema operacional e a arquitetura do usuário para sugerir o download correto. No entanto, isso depende inteiramente do desenvolvedor ter compilado e enviado um pacote para essa plataforma específica.

**Possibilidades Atuais e Limitações:**

* **Compilação Múltipla:** A prática atual exige que os desenvolvedores de externals compilem seus projetos para cada combinação de sistema operacional (Windows, macOS, Linux) e arquitetura (Intel, ARM, etc.) que desejam suportar. Ferramentas como o `pd.build` podem auxiliar nesse processo, mas não o automatizam de forma "universal".
* **Binários Universais no Pd:** O próprio Pure Data, em algumas de suas distribuições, como para macOS, é distribuído como um binário universal, que funciona tanto em processadores Intel quanto Apple Silicon. Contudo, essa prática não se estende aos externals distribuídos pelo Deken.
* **Ausência de um "Instalador Inteligente":** Não há, no momento, um mecanismo no Deken que funcione como um instalador "inteligente", que detecte o sistema do usuário e, a partir de um único pacote, instale a versão correta.

Em resumo, a possibilidade de um usuário instalar um external sem a necessidade de escolher a plataforma/arquitetura depende do desenvolvedor do external ter criado e disponibilizado um pacote específico para o sistema do usuário, e do Deken conseguir identificar corretamente esse sistema. Não existe um "binário universal" de external que funcione em múltiplos sistemas operacionais distintos.