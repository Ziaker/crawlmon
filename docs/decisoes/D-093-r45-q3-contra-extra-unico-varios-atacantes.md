<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-093 — R45-Q3 (3A): Um único contra-ataque extra por múltiplos Evades perfeitos

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 45
- **Origem:** decisão expressa do criador, R45-Q3.
- **Estado:** decisão de design aprovada; implementação não verificada.

## Declaração literal do criador

> 3A — Se o personagem realizar Evade perfeito contra vários atacantes, como funciona o contra-ataque extra? Conceder apenas um contra-ataque extra, escolhendo um dos atacantes como alvo.

## Regra aprovada

Quando um personagem realiza Evade perfeito contra vários atacantes, ganha **um único contra-ataque extra**, direcionado a **um dos atacantes**. Não ganha automaticamente um golpe extra por atacante.

## Referências e limites

- **Decisões relacionadas:** D-017; D-035; D-042; D-043; D-051; D-052; D-062; D-064; D-065; R45-Q2.
- **Limite / pendência:** A resposta não determina quem ou o que seleciona o atacante-alvo; a seleção manual do Move já aprovada não resolve automaticamente a seleção do alvo. Preservar regras existentes de custo, janela, fila e cancelamento.
- **Escopo:** registro documental somente; nenhum código, VFX, teste ou dado de jogo modificado.
