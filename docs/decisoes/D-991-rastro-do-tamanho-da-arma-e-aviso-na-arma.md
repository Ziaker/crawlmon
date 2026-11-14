<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-991 — Rastro do tamanho da arma, alinhado nela; aviso de Evade na arma

- **Data:** 2026-11-08.

## Frase literal do criador

> o dodge notification aparece muito mais a esquerda do cyclops do que acima dele (indicando a arma), mude isso nele.
> na segunda imagem, quanto ao efeito do rastro, ele devia ser grande como a marreta e corretamente alinhado no meio

## Decisão

1. Quem segura uma arma (malha presa a um único osso com nome de arma: "buki", "weapon", "wmodel"…): o rastro do Swing cobre **o comprimento inteiro da arma**, centrado nela, seguindo sua orientação real.
2. O aviso da janela de Evade (D-986) fica **no meio da arma**, e não ao lado do corpo. Sem arma, segue a regra de D-989.
3. Nomes genéricos, nunca por espécie (D-235).

## Estado

Implementado para revisão.
