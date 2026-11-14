<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-008 — AoE corpo a corpo: o atacante fica parado; quem desvia ganha Burst sem interromper

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> A, B, B, B, ... (respostas 1 e 2 da lista de ambiguidades de AoE)

## Decisão

**1A:** AoE corpo a corpo = o atacante **fica parado** (como golpe lançado). **2B:** quem desvia de um AoE corpo a corpo **ganha o Burst, mas não interrompe o atacante e não fica engajado**.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma.

## Estado no código

**Não implementado.**
