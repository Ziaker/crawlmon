<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1255 — Visual dos Cascos cunhados no mapa

- **Data** — 2026-11-16
- **Área** — Arte de exploração 3D / moedas / feedback de coleta
- **Estado** — Direção visual aprovada. Estudo de coleta em imagem, com animação e integração pendentes.
- **Relacionadas** — [D-1252](D-1252-cascos-de-bronze-prata-e-ouro.md), [D-1253](D-1253-saldo-comum-e-balanceamento-dos-cascos.md).

## Frase literal do criador

> opcao 2, elas devem estar no ambiente 3D de tamanhas formas (angulos diferentes) , as vezes pilhadas, separadas, com um feedback visual viciante ao coletar

## Decisão

1. A [opção 2, moedas cunhadas](../referencias/exploracao/3d/shells-opcao-2-moedas-cunhadas.png), define a família visual dos ícones e dos modelos. Bronze Shell é redonda, com uma espiral em relevo. Silver Shell é hexagonal, com uma concha em leque em relevo. Golden shells são octogonais, com entalhe no topo e búzio em relevo.
2. As moedas aparecem como peças tridimensionais no ambiente, em ângulos diferentes. Podem aparecer separadas ou empilhadas.
3. A coleta deve ter feedback visual satisfatório. O [estudo de disposição e coleta](../referencias/exploracao/3d/shells-disposicao-e-coleta-estudo.png) propõe brilho breve, moedas que giram em arcos até o coletor e um brilho de confirmação. A sequência é um estudo para aprovação.

Os [prompts visuais dos Cascos](../plans/PROMPTS_VISUAIS_DOS_CASCOS.md) reúnem as instruções para a prancha de ícones e modelos, o storyboard e a implementação visual.

## Pendências

- Escala no mapa, ângulos, quantidade de peças por grupo e relação entre representação e valor.
- Gatilho de coleta, movimento, ritmo, intensidade e apresentação visual final.
- Validação de legibilidade e feedback na câmera de exploração.
