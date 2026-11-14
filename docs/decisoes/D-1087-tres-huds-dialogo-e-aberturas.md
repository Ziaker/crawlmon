<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1087 — Três protótipos de HUD de diálogo + três animações de abertura

- **Data:** 2026-11-09.
- **Área:** Exploração / UI / diálogo / design.
- **Relacionadas:** D-1063 (NPCs/diálogo), D-1075 (prompt/diálogo), D-1085 (prompt).
- **Status:** **C escolhido pelo criador e integrado ao diálogo real (D-1090)**; A e B ficam como referência no lab de protótipos; nada publicado.

## O que o criador disse (literal)

> 4 - eu quero ver as 3 pra eu escolher a melhor, se houver videos melhor ainda

> inclusive eu quero uma animação de UI UX quando abre a caixa de dialogo, me dê 3 opções pra ela também, pode ser ambicioso, quero surpresas então não vou dar a direção disso

## Decisão

1. **Três estilos completos:**
   - **A — SMT III / terminal:** vidro escuro, scanlines, tipografia condensada, nameplate inclinado, typewriter.
   - **B — Comic/manga:** balão claro com contorno preto, meio-tom, retrato em medalhão, tail do balão, typewriter.
   - **C — Card de papel/RPG:** pergaminho, verde/âmbar da Murky Forest, mesmo *shear* do HUD, medalhão/retrato, typewriter.
2. **Cada estilo tem uma abertura própria:**
   - **A:** varredura de scanline + glitch/slices + flicker.
   - **B:** pop/elastic scale, tail do balão crescendo, meio-tom animado, retrato entrando.
   - **C:** sobe/rotaciona levemente, papel “desenrola”, selo/carimbo e typewriter.
3. **Conteúdo:** a mesma fala de NPC nos três; retrato + nome + typewriter + `[Z] NEXT`; sem escolhas e sem som nesta rodada.
4. **Formato:** lab separado (`dialogue_style_lab`), um vídeo/GIF curto por estilo + folha de contato; apresentar para o criador escolher.
5. **Não substituir** o painel de diálogo atual até a escolha. O lab das três fica como referência.
6. **Não muda:** batalha, 2D, HUD/status, cards, NPCs, regras.

## Ambiguidades

- O criador não deu direção de arte para a abertura; as três acima são propostas.
- A escolha pode combinar estilo de um com abertura de outro? O lab será modular para permitir isso.
- Retratos: usar a arte local dos Pokémon e o retrato do Orc; para NPCs sem retrato, usar um medalhão neutro.

## Protótipos prontos (2026-11-09)

- **A — SMT/terminal:** painel de vidro escuro, wipe de scanline/glitch, nameplate vermelho, retrato em moldura ciano, texto mono com typewriter e `[Z] NEXT`.
- **B — Comic/mangá:** balão creme com contorno preto, tail, meio-tom, retrato circular, nome em badge preto e pop elástico na abertura.
- **C — Paper/RPG:** card de pergaminho inclinado -2°, moldura verde, medalhão dourado, selo “M” com quique, texto serifado e typewriter.
- **Vídeos (7 s, 30 fps, 1280×720):**
  - `docs/referencias/exploracao/3d/dialogue_hud_a_smt.mp4` / `.gif`
  - `docs/referencias/exploracao/3d/dialogue_hud_b_comic.mp4` / `.gif`
  - `docs/referencias/exploracao/3d/dialogue_hud_c_paper.mp4` / `.gif`
- **Folha de contato:** `docs/referencias/exploracao/3d/dialogue_hud_aberturas_contato.png` (0,0 s / 0,5 s / 1,5 s / 6,0 s).
- **Lab:** `scenes/debug/dialogue_style_lab.tscn` + `scripts/debug/dialogue_style_lab.gd` + `scripts/debug/dialogue_hud_styles.gd`; não integrado ao diálogo real.
- **Escolha do criador:** **C — Paper/RPG**, integrado em D-1090. A e B continuam no lab como referência; a combinação de estilo/abertura continua possível.

## O que não foi verificado

- 60 fps/mobile, outras resoluções, áudio e localização.
- A escolha do criador; nada foi integrado ao painel real.
- A cena principal em headless continua bloqueada pelos erros de VFX de outra sessão; teste no lab isolado.

## Estado

Protótipos, aberturas, vídeos e folha de contato prontos. Aguardando a escolha do criador para integrar. Nada publicado.
