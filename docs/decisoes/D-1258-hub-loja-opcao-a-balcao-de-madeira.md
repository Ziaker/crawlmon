<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1258 — Loja do Hub, opção A de balcão aberto de madeira

- **Data** — 2026-11-16
- **Área** — Hub 3D / loja de suprimentos / arte de ambiente
- **Estado** — Visual aprovado. Implementação pendente.
- **Relacionadas** — [D-1238](D-1238-hub-3d-mais-escuro-detalhado-e-npcs-no-portal.md), [D-1250](D-1250-hub-loja-e-economia-de-expedicao.md) e [D-1255](D-1255-visual-dos-cascos-cunhados.md).

## Frase literal do criador

> a opção A é perfeita

## Decisão

1. A [opção A, balcão aberto de madeira](../referencias/hub_3d/shop-opcao-a-balcao-madeira.png), é a referência visual aprovada da loja de suprimentos do Hub.
2. A referência estabelece o balcão aberto, o toldo baixo com faixa verde, a placa com silhueta de poção, os frascos e suprimentos expostos e a lanterna âmbar concentrada na mercadoria. A peça segue as formas low-poly e a penumbra do Hub em modo dusk.
3. A imagem é uma montagem de conceito sobre uma captura do Hub no Godot. O Plot B fornece o enquadramento do estudo. A localização definitiva continua pendente.

## Pendências

- Localização, comerciante, dimensões e ajuste na câmera e na circulação reais.
- Interface, catálogo exato, preços e regras de comércio conforme a D-1250 e as decisões da economia.
