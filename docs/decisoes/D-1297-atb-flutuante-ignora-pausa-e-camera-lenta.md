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

## Conflito (preservo as duas; confirmação pedida ao criador)

**D-1040** (item 1) diz que o relógio é do `Battle` e que "pausa e câmera lenta valem para os dois" (lógica e visual). A frase acima abre uma exceção só para o voo dos tokens de ATB/Burst. Implementei a exceção (pedido explícito e estreito) mantendo o relógio dentro do `Battle` (`battle_rewards.gd`), então o visual continua sem temporizador próprio (D-019). **Pergunta: a exceção da D-1297 prevalece sobre o trecho "pausa e câmera lenta valem para os dois" da D-1040, só para estes tokens?**

## Ambiguidades em aberto

- **D-1229 (Employ "congela tudo")** diz que nada avança durante a tentativa de Employ. Preservado: o voo continua congelado durante o Employ. Se o criador quiser que também ignore o Employ, é uma pergunta separada.
