> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.

# D-1217 — Reajuste de Brave, Timid, Calm e Adamant para 3 status cada

Data: 2026-11-14

## Frase literal do criador

> "Sim, reajuste"

Em resposta à pergunta da IA: "Posso reajustar Brave, Timid, Calm e Adamant para 3 status cada?", com estes valores propostos ao lado.

## Decisão

Para toda Nature não pura encher os 3 rolos da roleta (D-1215), os modificadores passam a ser:

| Nature | Antes | Depois |
|---|---|---|
| Brave | STR +2, VIT +1, WIS −1, AGI −2 | STR +2, VIT +1, AGI −3 |
| Timid | AGI +2, LUK +1, STR −2, VIT −1 | AGI +2, LUK +1, STR −3 |
| Calm | WIS +2, VIT +1, STR −2, LUK −1 | WIS +2, VIT +1, STR −3 |
| Adamant | STR +3, MAG −3 | STR +3, MAG −2, LUK −1 |

Continuam flat, de −3 a +3, somando zero (D-271, D-393). Os parâmetros de IA (`atb_reserve_bias`, `aggression_mult`) não mudam.

## Consequências

- `scripts/data/nature_data.gd`: os 4 valores.
- `PreGameCatalog.NATURE_DESCRIPTIONS["adamant"]` citava "-3 MAG": corrigido só o número.
- `PreGameCatalog.COMBO_EV_TABLE`: as 24 entradas dessas 4 Natures precisam ser recalculadas.
- `tests/ui/test_status_screen_content.gd` conferia "-2 AGI" da Brave: passa a conferir "-3 AGI".

## Estado

Implementada (dados, descrição da Adamant, 24 entradas de EV, assert "-3 AGI"). Pendente: as descrições de Brave, Modest, Calm e Adamant citam status (D-432); o criador mandou corrigir, mas ainda não deu os textos novos.
