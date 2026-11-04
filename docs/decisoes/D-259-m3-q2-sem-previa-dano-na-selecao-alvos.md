# D-259 — Fichas de Moves M3-Q2 (2D): não existe nem deve existir prévia de dano na seleção de alvos

- **Data:** 2026-11-04.
- **Área:** Fichas de Moves / Rodada M3, questão 2.
- **Origem:** decisão expressa do criador (2D) complementada por observação literal que define a alternativa D.
- **Estado:** regra de design aprovada e documentada; implementação e dados individuais pendentes.

## Declaração literal do criador

> 22D — Outra regra.

> Observações e regras próprias: Tudo q não é tackle consome MP , não existe previa de dano em seleção e não deve existir, pare de inventar coisa que eu não pedi

## Regra aprovada, alcance e exemplos

- O criador resolveu **M3-Q2** pela observação expressa: **“não existe previa de dano em seleção e não deve existir”**. **Não implementar, propor como comportamento escolhido ou exigir prévia de dano na seleção de alvos**. Não criar números antes/depois da seleção, previsões por alvo ou comparação automática entre alvos nessa interface.

- A proibição é relativa **à seleção de alvos**; preservar **D-229/D-230** sobre **tooltip de habilidade em combate**, que exige informações mecânicas integradas e dano/cura numéricos quando verificáveis. **Não concluir** que tooltip e seleção de alvos são a mesma interface ou que a exigência numérica foi revogada.

- **Exemplo de restrição (não implementação):** selecionar um alvo não produz um cartão 'dano previsto: 36', nem uma lista de previsões contra diferentes oponentes. A descrição usual de um Move continua regida pela D-229/D-230 em seu contexto, **sem criar cálculo de prévia durante a seleção**.

- **Pendências preservadas:** fonte e contexto dos números da tooltip que não sejam previsão de seleção; não escolher recálculo por seleção, regra de alvo neutro, dinâmica de hover ou outras interfaces. O usuário explicitamente vetou essa invenção; não reabrir o tema sem solicitação.

- A resposta **2D** não aprova nenhuma das alternativas A/B/C anteriores; apenas a regra negativa escrita nas observações é aprovada.

## Histórico, fontes e escopo

- Preservar **D-061**, **D-228–D-230**, **D-235**, **D-244–D-249** e todos os demais requisitos pertinentes. As novas regras não autorizam reescrever os registros históricos para apagar escolhas anteriores, apenas explicitar precedência quando houver alteração expressa.
- **Nenhuma ficha de Move operacional, código, HUD, teste, VFX, asset, cena, configuração ou dependência foi modificada nesta atualização; não foram executados testes de gameplay.**
