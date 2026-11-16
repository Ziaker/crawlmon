<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1246 — Murky Forest como destino recorrente

- **Data** — 2026-11-16
- **Área** — Exploração 3D / level design / eventos de expedição
- **Estado** — Direção de design aprovada. Validação em jogo pendente.
- **Relacionadas** — [D-1245](D-1245-murky-forest-level-design-medicao-e-gating.md), D-1181, D-1208 (integração com o Hub), [GDD §7.20–7.21 e §7.27](../GDD.md).

## Frases literais do criador

> absolutamente NADA referente a audio deve ser levado em conta por ora. eu estou pensando em murky forest for alem de um ambiente inicial, tambem um ambiente que incentive a ida e a volta pra ela, com eventos diferentes

> aprovo

## Direção aprovada

1. A Murky Forest é o ambiente inicial e um destino recorrente. As novas expedições oferecem situações distintas em lugares reconhecíveis. Conhecer o espaço ajuda o jogador a perceber mudanças, escolher rotas e encontrar descobertas.
2. O ciclo de design começa com um motivo para voltar apresentado no Hub. Na mata, a situação se revela por pistas no cenário e por personagens. Os eventos devem dar ao jogador algo diferente para fazer em salas que ele já conhece.
3. Dentro da mesma expedição, a revisita usa o layout e o estado já estabelecidos conforme o GDD (R9-Q2 e R36-Q3). O retorno do Hub em uma nova expedição pode apresentar outra situação.
4. O primeiro recorte de validação prevê duas expedições ligadas pelo Hub. Na primeira, o jogador avista um lugar que desperta curiosidade. Na segunda, um acontecimento dá motivo para chegar até lá. Corredor, abrigo da Super Poção e arco elevado são referências do recorte conceitual. O áudio fica integralmente fora deste escopo.

## Pendências

- Gatilhos, ordem, conteúdo concreto dos eventos e recompensas.
- O que persiste entre expedições e como apresentar o motivo de retorno no Hub.
- Geometria exata e acessos ao lugar avistado, incluindo arco, passagem inferior e posto de vigia.
- Resgate, grupo de exploradores, encontro raro e recrutamento são exemplos a decidir.
