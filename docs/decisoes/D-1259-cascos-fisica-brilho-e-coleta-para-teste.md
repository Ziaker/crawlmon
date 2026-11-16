<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1259 — Cascos: física, brilho no chão e feedback de coleta (valores de TESTE)

- **Data** — 2026-11-16
- **Área** — Exploração 3D / moedas / feedback de coleta
- **Estado** — Aprovado **somente para fins de teste**. Valores provisórios, sujeitos a revisão do criador.
- **Relacionadas** — [D-1252](D-1252-cascos-de-bronze-prata-e-ouro.md), [D-1253](D-1253-saldo-comum-e-balanceamento-dos-cascos.md), [D-1255](D-1255-visual-dos-cascos-cunhados.md).

## Frase literal do criador

> elas devem ter fisica aplicada, brilharem no chão, e emitirem um efeito de feedback viciante ao serem coletadas
>
> sigo suas recomendações para fins de teste

## Decisão (teste)

1. Física só ao nascer: a moeda cai e quica no chão. Colide apenas com o chão e com outras moedas, não com o jogador. Pilhas se montam pela queda das peças.
2. Brilho: um reflexo que varre a face da moeda de tempos em tempos, mais um brilho suave sobre o chão ao redor. A intensidade cresce de bronze para ouro.
3. Coleta: a moeda é puxada quando o coletor chega perto, voa em arco girando, e na chegada há estouro de faíscas, brilho de confirmação, som curto e um "+1" flutuante. Em coleta em sequência, o tom do som sobe a cada moeda.

## Pendências

- O "+1" conta moedas, não valor: valores seguem pendentes em D-1253.
- Escala das moedas no mapa (provisório 0,32 m de diâmetro), raio de puxada, ritmo, intensidade e som final.
- Contador no HUD.
