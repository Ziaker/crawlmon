<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-017 — Evade bem-sucedido contra corpo a corpo: interrompe, Burst, chegada, golpe de graça, engajamento

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** PROMPT + memória

## O que o criador disse (literal)

> (a) o atacante é interrompido onde está ... (b) o personagem que desviou ganha +1 Burst e chega imediatamente ao atacante interrompido ... (c) o primeiro golpe seguinte não tem preparo e é golpe de graça: o Burst paga a ação inteira. / Depois de um Evade perfeito o personagem só aparece ao lado do inimigo quando ele então ATACA em trajeto.

## Decisão

1) O atacante é **interrompido onde está** (cambaleia; o ataque é cancelado). 2) Quem desviou ganha **+1 Burst**. 3) O personagem **só vai para junto do inimigo quando ATACA** (o contra-ataque, sem preparo); parado/sem atacar **nunca** teleporta. 4) O Burst paga a ação inteira (mantido). 5) **Estado engajado** enquanto durar a câmera lenta do Burst (2 s reais): se agir, continua engajado; se não agir, volta com o pulo rápido; também volta se o oponente morrer. 6) O **desvio visual** (some, reaparece ao lado, volta) e o texto **MISS!** ficam.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma.

## Estado no código

Implementado.

## Conciliação posterior (2026-11-03)

A descrição histórica de interrupção/cambaleio automático após Evade foi **substituída apenas nesse aspecto** pela D-106: um ataque evitado **conclui como golpe que errou**, sem interrupção mecânica adicional nem animação de interrupção por Evade. Permanecem as demais regras desta decisão onde compatíveis (Burst, contra-ataque, engajamento e teleporte conforme decisões posteriores).
