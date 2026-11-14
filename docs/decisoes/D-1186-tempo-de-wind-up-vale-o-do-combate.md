# D-1186 — O tempo de wind-up que vale é o do combate; os textos dos Moves seguem o dado

- **Data:** 2026-11-12.
- **Área:** Moves / conteúdo / textos de UI.
- **Relacionadas:** D-1185 rodada 11 (divergência encontrada), D-420 (fichas de Move), D-1079 (Move como pacote `.tres`).
- **Status:** **aplicado nos textos**; nenhum tempo de combate mudou.

## O que o criador disse (literal)

Pergunta: "Nos 12 Moves, qual tempo de wind-up vale?" (o texto de wind-up dizia um tempo e o combate usa outro)

> O do combate

## Decisão

1. **Vale o tempo do combate:** o campo `windup` do Move (`content/moves/*/move.tres`) ou, sem ele, o padrão do combate (0,5 s para status, 1,5 s para os demais — `scripts/combat/battle.gd:91` e `:98`).
2. **Os textos se ajustam ao dado:** onde o texto (`windup_text` e as cópias em `phase_visuals`) dizia outro número de segundos, só o número foi trocado pelo do combate. Nenhuma outra palavra mudou.
3. **Nenhuma regra, tempo ou comportamento do combate mudou.**

## Aplicação

A varredura achou 29 Moves com o número errado no texto (não só os 12 do protótipo); todos foram corrigidos. Lista e comando de verificação no commit.

## O que não foi verificado

- Moves com `behavior_script` próprio podem ter tempo efetivo diferente do campo `windup`; a correção usou o campo/padrão.
- Textos fora de `content/moves` (ex.: `SkillLegacyData.windup()`) não foram mexidos.
