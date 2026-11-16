<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1251 — Moedas pela exploração e economia inicial difícil

- **Data** — 2026-11-16
- **Área** — Exploração / recompensas / economia
- **Estado** — Regra de design aprovada. Implementação e balanceamento pendentes.
- **Relacionadas** — [D-1250](D-1250-hub-loja-e-economia-de-expedicao.md) e [GDD §7.18–7.19](../GDD.md).

## Frase literal do criador

> moedas devem ser recebidas cacando por recompensas e segredos nos mapas, inimigos dropam tambem mas e muito pouco e a economia e densa e dificil no inicio

## Decisão

1. A fonte principal de moedas é a busca por recompensas e segredos nos mapas.
2. Inimigos também deixam moedas em quantidades muito pequenas.
3. A economia é densa e difícil no início. A escassez inicial deve dar peso a cada compra.
4. O primeiro recorte da D-1250 começa com uma recompensa encontrada no mapa. O jogador usa as moedas no Hub e leva a compra à próxima expedição.

## Pendências

- Valores, frequência dos drops, tipos e distribuição das recompensas em moedas nos mapas.
- Preços, saldo inicial, duração da fase inicial e regras de retenção ou perda de moedas.
