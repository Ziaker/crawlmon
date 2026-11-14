<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1081 — Electric Beam custa 6 MP

- **Data:** 2026-11-09
- **Área:** Combate / Moves / Custos de MP
- **Origem:** resposta do criador à divergência entre o teste `test_d977_electric_beam.gd` (8 MP) e o código/catálogo (6 MP).
- **Estado:** decidida; correção do teste aplicada.

## Frase literal do criador

> "6mp"

## Decisão

1. **Electric Beam custa 6 MP.** O valor de 8 MP da D-977 é lido junto com o desconto de 30% da D-438: `8 × 0,7 = 5,6`, arredondado para **6 MP**.
2. O catálogo (`content/moves/electric_beam/move.tres`) e a tabela legada de `Skill.get_mp_cost_for()` permanecem em **6 MP**.
3. O teste `tests/battle/test_d977_electric_beam.gd`, que esperava 8 MP, é corrigido para **6 MP**. Nenhuma outra regra do Electric Beam muda (dano, STUN de 4 s, 20% + LUK, vento/up, VFX).
4. Nenhum outro Move tem o custo alterado por esta decisão.

## Ambiguidades em aberto

Nenhuma.

## Estado no código

Correção documental e do teste. O código do Move já estava em 6 MP; nenhum valor de jogo foi alterado. Nenhum push.
