<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1152 — Fase 0: testes de ouro do pipeline de dano

- **Data:** 2026-11-11
- **Área:** Combate / dano / testes / processo.
- **Origem:** o criador aprovou o plano e mandou começar pela Fase 0.
- **Estado:** implementado e testado; nenhum número do jogo foi alterado.

## Declaração literal do criador

> "ok comece"

## Regra aprovada

- Antes de qualquer refatoração do núcleo de dano, congelar o comportamento atual numa matriz de testes de ouro.
- A matriz usa `Combatant` e `MoveData` sintéticos, para não depender da auditoria dos Moves.
- Cada caso verifica **duas coisas**:
  1. `info.dmg` devolvido por `Battle._hit`;
  2. o HP realmente perdido depois de `Combatant.take_damage`.
- A matriz cobre: físico neutro, fraqueza, crítico, passos, `def_buff` positivo/negativo, mágico neutro, WIS 10/2, fraqueza + WIS, crítico + WIS, Guard, ARMOR, escudo, Drain Spear, Burn, status, mínimo 1, arredondamento e paridade `estimate_damage` × `_hit`.
- Se um caso revelar um bug, ele **não** é corrigido silenciosamente no teste: vira decisão separada.

## Achado documentado

O `_hit` devolve `info["dmg"]` **antes** de `take_damage` aplicar `def_buff`. Exemplo do teste:

- `def_buff +2`: `info.dmg = 10`, HP perdido = **7**;
- `def_buff -2`: `info.dmg = 10`, HP perdido = **15**.

Ou seja, o número que a HUD usa pode não ser o dano efetivo quando há estágio de Defesa. A Fase 0 apenas registra; a correção, se desejada, precisa de decisão própria.

## Estado no código

- `tests/battle/test_d1152_damage_golden.gd` — **D1152_PASS** (44 asserções; inclui dois casos de IA e um caso RESIST).
- Nenhuma alteração em `battle.gd`, `combatant.gd`, `skill.gd`, Moves ou UI.
- Nada de commit/push sem autorização (D-022).
