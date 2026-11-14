<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-284 — Contra-ataque pós-desvio perfeito tem wind-up de 0,3 s (instantâneo só para status)

- **Data:** 2026-11-05
- **Área:** Combate / contra-ataque
- **Origem:** Conversa

## O que o criador disse (literal)

> "faça com que o contra-ataque instantâneo na verdade tenha um wind up de .3 segundos independente do move (instantâneo de verdade se for de status) só pra não parecer bugado"

## Decisão

1. O golpe que sai depois de um desvio perfeito (D-164, D-027) passa a ter **wind-up de 0,3 s**, **independente do Move**, em vez de nenhum.
2. Se o Move é de **status**, continua **instantâneo de verdade** (sem wind-up).
3. Com 0,3 s o contra-ataque mostra a pose de carga e os avisos como qualquer golpe (antes: nenhum, "instantâneo").
4. O restante do contra-ataque (sem antecipação, tempos de acerto curtos, custo, Burst) não muda.
5. Por D-235: vale para qualquer Move, personagem, time e lado.

## Ambiguidades em aberto

- Se o 0,3 s também vale para o estado engajado (que também usa o golpe "instantâneo").
- Se o aviso de perigo no chão deve aparecer nos 0,3 s ou só a pose de carga (aparece tudo, como num golpe comum).

## Estado no código

Implementado (2026-11-05): `Battle.COUNTER_WINDUP`, `Battle.use_skill`, `FxTelegraph.telegraph`.
