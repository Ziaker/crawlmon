# D-263 — Fichas de Moves M3-Q6 (6D): todo Move exceto Tackle consome MP

- **Data:** 2026-11-04.
- **Área:** Fichas de Moves / Rodada M3, questão 6.
- **Origem:** decisão expressa do criador (6D) complementada por observação literal que define a alternativa D.
- **Estado:** regra de design aprovada e documentada; implementação e dados individuais pendentes.

## Declaração literal do criador

> 66D — Outra regra.

> Observações e regras próprias: Tudo q não é tackle consome MP , não existe previa de dano em seleção e não deve existir, pare de inventar coisa que eu não pedi

## Regra aprovada, alcance e exemplos

- O criador resolveu **M3-Q6** pela observação expressa: **“Tudo q não é tackle consome MP”**. Portanto, **todo Move diferente de Tackle consome MP em gameplay**, incluindo Moves físicos, mágicos/especiais, de suporte, cura ou status. **Tackle é a única exceção expressamente aprovada** dentro da categoria Moves: **não consome MP**.

- Esta é uma **regra posterior e mais abrangente** que **D-228 (M1-Q4A)**, que exigia MP apenas para Moves mágicos/especiais. **Preservar a D-228 e a D-032 como documentos históricos**, mas a restrição 'apenas mágicos/especiais' **não prevalece mais** para definir elegibilidade de MP. A diretriz de MP adicional aos custos de ATB/Burst aplicáveis continua, sem alterar as regras normativas anteriores de pagamento do recurso de ação.

- **Nenhum custo numérico de MP foi aprovado** para qualquer Move. Não escolher valor global, custo zero implícito, custos concretos de Tackle além da sua exceção ao MP, reservas, escalas ou valores específicos de habilidades.

- **Exemplo de escopo:** Bite, Sand Attack, Dragon Rage e Media, enquanto Moves diferentes de Tackle, **devem ter custo de MP** quando suas fichas forem definidas, mas **a quantidade de MP de cada um permanece pendente**. O exemplo não atribui valores nem resolve sua natureza física/mágica.

- Preservar **D-033/D-063** (1 Burst paga a ação inteira / prioridade de Burst sobre ATB) e as regras de custos de ação anteriores. **A relação específica entre o pagamento integral da ação por Burst e a cobrança adicional de MP permanece potencialmente conflitante e precisa de conciliação explícita posterior**; não alterar a semântica de Burst silenciosamente. Não determinar aqui custos de comandos que **não são Moves** (itens, Evade, Tactics).

- Preservar D-122/D-123/D-244: categoria física/mágica e atributos STR/MAG não são inferidos do custo de MP; a cobrança universal **não torna todo Move mágico**. Nenhum código foi atualizado para implementar custos ou validação de MP.

- A resposta **6D** não aceita as alternativas A/B/C propostas; a única regra adicional aprovada é o que o criador escreveu nas observações.

## Histórico, fontes e escopo

- Preservar **D-061**, **D-228–D-230**, **D-235**, **D-244–D-249** e todos os demais requisitos pertinentes. As novas regras não autorizam reescrever os registros históricos para apagar escolhas anteriores, apenas explicitar precedência quando houver alteração expressa.
- **Nenhuma ficha de Move operacional, código, HUD, teste, VFX, asset, cena, configuração ou dependência foi modificada nesta atualização; não foram executados testes de gameplay.**
