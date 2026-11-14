<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-020 — Preservar o que existe; não reintroduzir o que foi removido

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** PROMPT

## O que o criador disse (literal)

> Preserve o que existe: ATB, itens, Tactics, Burst, esquiva automática, crítico, fraquezas, câmera (Cinema/Tática/Impacto), HUD, efeitos e pausa do Status/Tactics. Não reintroduza movimento ocioso dos personagens nem tremor/zoom de câmera. Textos 3D de esquiva e de ATB foram removidos a pedido; o miss_text fica.

## Decisão

Preservar ATB, itens, Tactics, Burst, esquiva automática, crítico, fraquezas, câmera (Cinema/Tática/Impacto), HUD, efeitos e a pausa de Status/Tactics. **Não** reintroduzir movimento ocioso dos personagens, tremor ou zoom de câmera, nem os textos 3D de esquiva e de ATB. O `miss_text` fica.

## Ambiguidades em aberto (perguntar antes de agir)

Zoom/dolly de câmera: ver D-015 (pergunta aberta).

## Estado no código

Em vigor.
