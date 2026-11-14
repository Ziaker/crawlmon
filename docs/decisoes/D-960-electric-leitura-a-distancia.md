<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-960 — Electric: leitura a distância (melhoria 1 do plano)

- **Data:** 2026-11-07.
- **Origem:** o criador escolheu "Começa pela 1" no plano de melhorias da D-959.

## Decisão

Mantém o tamanho fixo em metros (D-308 item 6) e engrossa os raios finos (arcos da carga, filamentos, coroas, pontas, estouro e raios do impacto) em **1,8×**. A borda dos raios, que é o que aparece a distância, fica **dourado claro**. Um contorno escuro foi testado e reprovado pelo assistente: deixava os raios cinza a distância.

## Verificado

Vídeo `test_captures/electric_beam_v5_leitura.mp4`, com as duas vistas. Na espelhada, o estouro e as coroas agora aparecem como um aglomerado dourado no atacante a ~37 m. Antes eram quase invisíveis. A carga do wind-up continua pouco visível na espelhada.
