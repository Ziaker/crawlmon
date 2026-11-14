<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-028 — O Evade só aparece durante a ação, não na chamada

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> a proposta pra desvio tá acontecendo na chamada ao invés da ação, não é pra acontecer na chamada

## Decisão

O aviso de desvio (ESPAÇO / DESVIAR) e o botão Evade só existem **durante a ação** do ataque (o trajeto: a corrida ou o voo), **não durante a chamada** (o preparo). Durante o preparo o Evade não é oferecido.

## Ambiguidades em aberto (perguntar antes de agir)

- Consequência: apertar Espaço no preparo deixa de fazer qualquer coisa, então o **whiff** de D-016 (perder ATB e levar crítico) deixa de existir. Confirmar com o criador.

## Estado no código

Implementado (`battle_evade.gd`: só ataques no trajeto são oferecidos/aceitos).
