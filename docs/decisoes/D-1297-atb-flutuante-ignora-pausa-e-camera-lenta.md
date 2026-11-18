<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1297 — Blocos de ATB flutuantes (recompensas) não são afetados por pausa nem câmera lenta

- **Data:** 2026-11-17
- **Área:** Combate / HUD
- **Estado:** implementado (relógio do voo); visual aguarda julgamento do criador.
- **Relacionadas:** D-031/D-1146/D-1150 (pausa de status), D-1229 (Employ "congela tudo"), D-1296 (câmera lenta de 2,0 s).

## O que o criador disse (literal)

> "Os atbs flutuantes ganhos ao causar as recompensas NÃO deviam ser afetados por pausa e muito menos camera lenta, deviam ir direto sem parar mesmo com isso"

## Decisão

O voo dos tokens de recompensa (ATB e Burst: flutuar sobre a fonte, voar ao slot, impacto) corre em **tempo real**: não congela com hit-stop (`freeze`), pausa de status, nem encolhe com a câmera lenta (`Engine.time_scale`). O crédito de ATB na lógica continua imediato (como já era).

## Causa medida

`Battle._process` chamava `_reward_queue.step(delta)` só no fim, depois dos retornos antecipados de freeze/pausa de status e com `delta` já escalado pelo `time_scale`.

## Resposta do criador sobre o conflito com a D-1040

A D-1040 dizia que pausa e câmera lenta valem para lógica e visual. O criador respondeu que não quer essas siglas e confirmou o pedido acima: **a exceção vale** para o voo dos tokens (resposta: "EU VOU LÁ SABER OQUE SÃO ESSES Ds"). O relógio continua dentro do `Battle` (`battle_rewards.gd`), sem temporizador próprio no visual.

## Em aberto

- O voo continua congelado só durante a tentativa de Employ (o criador mandou "congela tudo" antes). Se quiser que também ignore o Employ, é só dizer.
