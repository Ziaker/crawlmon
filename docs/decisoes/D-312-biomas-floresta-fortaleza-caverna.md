<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-312 - Biomas iniciais: floresta, fortaleza e caverna

- **Data:** 2026-11-05
- **Área:** Exploração / visual
- **Origem:** Conversa (resposta à P5 do plano do overworld)

## O que o criador disse (literal)

> p5 - floresta, fortaleza (é o que usamos ja), caverna por ora

## Decisão

Por enquanto existem três biomas: **floresta**, **fortaleza** (o visual atual) e **caverna**. A D-278 continua valendo para a fortaleza.

## Ambiguidades em aberto

De quanto em quanto tempo o bioma muda, quais espécies aparecem em cada um e como floresta e caverna ficam visualmente sem ferir a D-278.

## Estado no código

Não implementado.