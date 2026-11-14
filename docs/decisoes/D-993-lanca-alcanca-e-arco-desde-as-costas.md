<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-993 — A lança alcança o alvo (só visual); o arco do Swing começa nas costas

- **Data:** 2026-11-08.

## Frase literal do criador

> acho que o problema do orc é a distância de seu ataque, tem como fazer ser apenas visual uma distância maior para que a lança realmente atinja e não passe?
> cyclops está perfeito e não precisa mais de alterações
> quanto ao trajeto do pancham, como demarcado em giz branco, ele deve partir das costas dele, e realizar um movimento em arco, não sumir nas costas, como na segunda imagem, ajuste o tempo também

## Decisão

1. Arma longa e fina (lança): na fase de golpe o modelo fica recuado em ~90% de meia lança, **só no visual**, para a ponta encontrar o alvo; a posição de combate não muda (D-019).
2. O rastro do Swing começa 0,5 s antes do contato (era 0,3 s) e vive 0,65 s: o arco parte das costas, passa por cima e desce até o alvo.
3. Cyclops aprovado, sem mudanças.

## Estado

Implementado para revisão.
