<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1298 — Moves que não gastam MP não pausam a recuperação automática de MP

- **Data:** 2026-11-17
- **Área:** Combate / MP
- **Estado:** implementado.
- **Relacionadas:** D-413 (timer reseta ao usar Move que custa MP), D-1062, D-1070 (ATB cheio 1,75x).

## O que o criador disse (literal)

> "Moves que não gastam MP NÃO deviam pausar a taxa de recuperação automatica de MP, especialmente tackles genéricos ou tackles únicos (orc e cyclops)"

## Decisão

Enquanto um combatente prepara/executa um Move cujo custo de MP é 0, o pulso de MP continua correndo (mesmo ritmo, inclusive o 1,75x com ATB cheio). Move que gasta MP segue como antes (D-413: o timer reseta ao pagar). Nada mais do `tick` (ATB travado no windup, durações) muda.

## Causa medida

`Battle._process` só chamava `Combatant.tick()` fora do windup/ação; o pulso de MP está dentro de `tick()`, então todo Move (também Tackle, custo de MP 0) parava a recuperação durante o preparo e a execução.

## Ambiguidades em aberto

Nenhuma. (A pausa de status D-031 continua parando tudo, inclusive o MP: não foi pedida mudança.)
