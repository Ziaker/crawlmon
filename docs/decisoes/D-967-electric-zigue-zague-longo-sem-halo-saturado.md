<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-967 — Electric: zigue-zague mais longo, sem o halo "mostarda", cores saturadas

- **Data:** 2026-11-08.

## Frase literal do criador

> os movimentos em zigzague poderiam ser mais duradouros, eles mal se distânciam, aumente o intervalo entre dobras do zigzague, inclusive o que é esse overlay de mustarda no efeito? pode remover ele?  e deixar o efeito mais claro, com cores mais saturadas

## Decisão

1. **Zigue-zague:** as dobras ficam a cada **2,6 m** (antes 1,2 m), com desvio de até **1,0 m** (antes 0,6 m). Cada forma dura mais: o caminho muda **6 vezes por segundo** (antes 15).
2. **"Overlay de mostarda":** era o tubo translúcido de halo da D-958, amarelo-pálido semitransparente sobre o fundo escuro. Foi **removido**; os sprites de brilho da D-966 fazem esse papel.
3. **Cores mais saturadas:** núcleo (1,0; 1,0; 0,82), meio amarelo puro (1,0; 0,86; 0,0), borda (1,0; 0,6; 0,0) e brilho (1,0; 0,82; 0,12).
