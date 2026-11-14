<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1000 — Arco próprio do Swing quando a mão quase não se move

- **Data:** 2026-11-08.

## Frase literal do criador

> Sim, arco próprio

## Medição

No Tackle do Pancham a mão direita nunca passa pelas costas nem por cima da cabeça: sobe 0,3, avança ~0,7 m em 0,07 s e fica quase parada. O rastro preso à mão só podia sair como uma cunha curta.

## Decisão

1. Quando, nos primeiros 0,2 s do rastro, nenhuma mão andou mais que metade da altura do corpo, o rastro vira um **arco próprio**: sai de trás do ombro, sobe por cima da cabeça e desce até o ponto de contato no alvo, percorrido em 0,5 s (chega junto com o contato) e some em 0,3 s.
2. Tamanho medido pela altura do corpo do atacante; direção pelo eixo até o alvo real (D-235).
3. Quem tem um caminho de mão amplo (ex.: Abra, aprovado) continua seguindo a mão.

## Ambiguidade

- O limite "metade da altura do corpo" decide quem usa o arco próprio; ajustar se um golpe cair no lado errado.

## Estado

Implementado para revisão.
