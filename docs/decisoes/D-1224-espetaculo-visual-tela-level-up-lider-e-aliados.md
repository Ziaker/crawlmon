<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1224 — Espetáculo visual da tela de Level Up (líder e aliados)

- **Data:** 2026-11-15.
- **Área:** Combate / Pós-combate / UI / Animação.
- **Relacionadas:** D-1185, D-1192 (tela de pós-combate), D-1223 (evolução automática de aliados), D-433 §5 (paralelogramos só como fundo, texto reto e medido), D-235 (independência de personagem).
- **Status:** **implementada e verificada.**

## O que o criador disse (literal)

> eu queria que a tela de level up de ambos jogadores e aliados tivesse mais um espetáculo visual, talvez mexendo com os textos, a forma como as formas surgem e também mais animações no geral, me surpreenda

> colocar efeitinhos feios encima não é a solução

> tem uma solução pra esse serrilhado? além disso não gostei do resultado pra quando o cartão da esquerda surge, me projete 3 opções

> opcao C

> tira esse shaking de quando a região da esquerda chega

## Decisão

1. **Sem enfeites superficiais em cima de cards parados:** proibidos anéis circulares, raios/faíscas de explosão em cima da UI de `LV`, marcas d'água translúcidas atrás do texto, trilhos finos poluentes, varreduras de brilho translúcidas e fundo marrom (`3a2f12`) nas linhas.
2. **Construção estrutural dos polígonos (`PcBlock`) e movimento contínuo:**
   - Faixas diagonais em movimento sutil no fundo do palco (`1280×720`) com flutuação contínua suave (`idle_amp`) nos dois cartões principais após assentarem.
   - Cartões principais (`lvc`, `attr`) surgem por **desdobramento diagonal estrutural** (`unfold_card`) acompanhados por lâmina sólida de destaque (`CORAL`/`AQUA`) e moldura gráfica deslocada sob o retrato.
   - Barras `HP MÁX`, `MP MÁX`, carimbo `LEVEL UP!` e as 6 linhas de atributo mais botão `CONFIRMAR` surgem por **extrusão horizontal** (`extrude_bar`) a partir da aba esquerda colorida.
3. **Tipografia cinética sólida e odômetro vertical (`PcDraw`):**
   - `PcDraw.letters()` sobe da linha de base com *squash & stretch* anamórfico e corte sólido de cor (`CORAL`/`AQUA` -> cor final), sem halo borrado.
   - Números de transição (`LV. antigo → novo`, `HP MÁX`, `MP MÁX` e valores de atributo) rolam verticalmente em **odômetro** (`PcDraw.odometer_number`), acompanhados de sublinhado verde-lima no novo nível e pílulas sólidas em paralelogramo (`+ganho`).
   - Carimbo `LEVEL UP!` entra por extrusão + estalo angular (sem `lvc.shake()` na chegada do cartão esquerdo).
4. **Transformação geométrica nas linhas de atributo (líder e aliado, D-235):**
   - Ao receber ponto, a própria linha executa um golpe lateral físico (`kick_bar`, estica `extra_w` e estala de volta), sua aba esquerda colorida inunda horizontalmente para `92 px` com sigla em contraste escuro (`INK`), ganha filete inferior sólido de `3 px` na cor do atributo, fundo azul-escuro elevado (`162c46`), número em odômetro e pílula sólida verde-lima `+N`.
   - **Aliado:** pontos automáticos caem em sequência geométrica (`0,52 s` + `0,24 s` por ponto) e `CONFIRMAR` estala no encerramento (com conclusão imediata se confirmar antes).
5. **Entrada do cartão esquerdo — Opção C ("Foco no Retrato") e antialiasing:**
   - **Serrilhado 2D:** contorno antialiased fechado (`draw_polyline(..., 1.15, true)`) em `PcDraw.fill_para()` para polígonos sólidos opacos (compatível com o renderer `gl_compatibility`).
   - **Cartão esquerdo (`lvc`):** o retrato com sua moldura deslocada (`CORAL`/`AQUA`) dá *punch* primeiro (`0.00s–0.22s`, escala `1.55 → 1.0`), enquanto o cartão creme e sua sombra se expandem por trás dele (`PcBlock.open_from_rect`, `0.14s–0.42s`); o bloco de texto (`NOME`, `LV.`, legendas) aparece quando `construct_p >= 0.45`, seguido por `HP MÁX`, `MP MÁX` e carimbo `LEVEL UP!` (`0.26s+`).
   - **Líder:** alocação/remoção dispara `kick_bar` na linha e estalo em `CONFIRMAR` ao zerar os pontos pendentes.
