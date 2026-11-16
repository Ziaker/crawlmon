<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1253 — Saldo comum e balanceamento dos Cascos

- **Data** — 2026-11-16
- **Área** — Economia / comércio / recompensas de expedição
- **Estado** — Direção aprovada. Implementação e balanceamento pendentes.
- **Relacionadas** — [D-1250](D-1250-hub-loja-e-economia-de-expedicao.md), [D-1251](D-1251-moedas-exploracao-e-economia-inicial.md), [D-1252](D-1252-cascos-de-bronze-prata-e-ouro.md).

## Frase literal do criador

> sigo suas recomendacoes

## Direção aprovada

1. Bronze Shell, Silver Shell e Golden shells são denominações distintas de um saldo comum na loja, com equivalências fixas e transparentes.
2. A exploração deve render mais que repetir lutas fáceis. Comparar o rendimento de rotas completas, incluindo tempo e HP/MP gastos. A primeira compra deve ser viável sem drop de prata, com um desvio bem sinalizado que ensina o valor de explorar. Segredos mais difíceis podem pagar mais.
3. O ouro deve ter valor alto e manter relevantes as escolhas de compra nas próximas saídas. O balanceamento precisa considerar a rota de quem já sabe onde o ouro está, inclusive uma entrada seguida de coleta e saída imediata.
4. A mochila preparada no Hub deve chegar à expedição com as compras. Resolver a transição pelo Portão antes de estipular preços. O primeiro teste é encontrar moedas no mapa, comprar um consumível no Hub e verificar que ele chega à expedição seguinte.
5. O saldo já consolidado é protegido. O destino dos ganhos da expedição em caso de derrota ou retirada fica para uma decisão própria.

## Pendências

- Equivalências numéricas, saldo inicial, preços, chances e quantidades de drops.
- Instante de consolidação do saldo, destino dos ganhos em derrota ou retirada e elegibilidade de vitória, recrutamento e fuga para drops.
- Distribuição e repetibilidade das recompensas nos mapas.
- Regra de reposição do kit inicial compatível com a mochila preparada no Hub.
