# D-205 — Rodada 71 Q2 (2A): arredondamento exato em 0,5 para cima

- **Data:** 2026-11-04.
- **Área:** Combate / dano / regra numérica.
- **Origem:** escolha expressa do criador, Rodada 71.
- **Estado:** requisito aprovado; não implementado nesta atividade.

## Declaração literal do criador

> 2A — Quando a fração for exatamente 0,5, arredondar para o inteiro superior.

## Regra aprovada

- No **arredondamento único final do dano** já estabelecido pela D-198, quando a parte fracionária do **resultado não negativo** for **exatamente 0,5**, **arredondar para o inteiro superior**.
- Para resultados não empatados, preservar o arredondamento ao **inteiro mais próximo** aprovado na D-198. **Não introduzir arredondamento entre as etapas** de mitigação e multiplicação.
- **Exemplos matemáticos:** `4,5 → 5`, `5,5 → 6`; `4,49 → 4` e `4,51 → 5`. Esses valores são ilustrativos, não números oficiais de dano.
- Aplicar depois o mínimo de dano **1 quando cabível**, preservando a exceção por imunidade/bloqueio completo (**D-194**). O piso não gera dano em golpes que erraram ou foram esquivados.

## Limites e pendências

- A regra cobre resultados de **dano não negativo**, sem escolher forma de arredondar valores negativos de outros sistemas.
- **Não define** tolerância para erro de ponto flutuante, formato numérico, nem a cadeia ainda pendente de fatores de fraqueza/crítico em relação à resistência natural. Essas escolhas não devem ser presumidas.
- A `main` ainda possui arredondamentos em dois locais de código (`battle.gd` e `combatant.gd`); documentar não é corrigir implementação.
- Somente documentação; nenhum código, teste, cena, ficha de Move, VFX ou asset modificado.
