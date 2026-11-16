<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1226 — Seleção de personagem: sem briefing nem barra de câmera; 3D com filtro pixel ou só arte; fundo do protótipo; fraquezas/resistências

- **Data:** 2026-11-15. **Área:** pré-jogo, tela de seleção (`pre_game_view_charselect.gd`, `pre_game_stage_3d.gd`, `pre_game_backdrop.gd`).
- **Relacionadas:** D-1016 (estilo pixel), D-1084 (idle_full DQT), D-1165 (afinidades), D-416/D-421/D-428, D-1207/D-1208.

## Declaração literal do criador

> "além disso poderia remover isso? [...] só deixe a opção de ver o modelo 3D COM o filtro do jogo já aplicado (mude o fundo da seleção pro fundo escuro do html do prototipo do pre-jogo também) e a opção de ver só a arte do personagem"

> "completamente vazio, inclusive devia mostrar as fraquesas e resistencias elementais do jogo na tela de seleção do personagem, coloque isso no lugar só que na região onde ficava o rotate com os textos azuis. Tem também como corrigir o idle dos DQT e do abra que fica repetindo toda hora? vc corrigiu isso no combate"

## Respostas às perguntas (criador)

1. (REVOGADO depois, ver abaixo) Filtro do jogo = **Pixel D-1016** (render 64×64 nearest, 6 níveis, sat. 1,15, contraste 1,08, silhueta escura).
2. Alternância = **um único chip que alterna** entre 3D e ARTE.
3. Controles ROTATE/TURNTABLE/AABB RIG/CENTER, readout AABB e atalhos Q/E/T/R/C: **removidos**.
4. Espaço do painel de briefing: **completamente vazio**. Na região da barra de câmera: **fraquezas e resistências elementais** da espécie.

## Decisão

- Removidos o painel "FIRST EXPEDITION BRIEFING" e a barra de controles do modelo 3D.
- Fundo da seleção: `#04070c` com gradiente radial `#0e1929` -> `#04070c` do protótipo `prototypes/pre_game_hud.html`.
- Fraquezas/resistências vêm de `weaknesses`/`resistances` da espécie (D-1165).
- Idle de Abra/DQT na seleção: ver "Estado".

## Estado (2026-11-15)

- **Feito:** briefing e barra de câmera removidos; chip único `VIEW: 3D MODEL / VIEW: ART` (atalho `F`, escolha técnica da IA); fundo `#04070c` + brilho `#0e1929` só na seleção; modelo 3D com estilo pixel D-1016 (`stretch_shrink` 5 + `overworld_model_style.gdshader`); linha "WEAK TO / RESISTS" com ícones elementais na região da antiga barra (dados de D-1165); auditoria de quads troca `wedge` por `affinity`.
- **Idle:** `pre_game_stage_3d.gd` não força mais `LOOP_LINEAR` em clipes que o loader já deixou `LOOP_NONE` (`idle_full` DQT, D-1084: toca uma vez e segura). **Não verificado** em tela; o caso do Abra não foi diagnosticado (idle dele já é loop do loader).
- **Debug:** `--view=charselect [--art=1] --shot=arq.png --res=1280x720`; `PREGAME_BOOT`, `PREGAME_PARITY_LAYOUT`, `PREGAME_QUAD_AUDIT` passam.
- **Não feito:** a rotação automática (turntable) continua ligada sem controle; arrastar com mouse segue como antes.

## Revisão (2026-11-15)

> "inclusive volte atrás quanto a escolha de shader, é pra ser o toon, não este"

- Filtro do modelo 3D na seleção = **toon** (estilo `toon` de `model_3d_view.gd`: linear, 12 níveis, 3 bandas a 0,75, silhueta 0,55), não pixel.
- Vista ARTE usa a arte completa (`sugimori/por_nome/<id>.png`; DQT em `DQT_PORTRAIT_PATHS`), não o ícone do roster.
- Bug: Z/Enter não ativava o menu principal (controlador enviava "enter", menu/quit/settings ouviam "confirm"); corrigido no roteamento.

## Teclado e botões do menu (2026-11-15)

> "todas opções que possuem botão no teclado simplesmente NÃO FUNCIONAM quando usa o teclado, só com clique, corrija isso imediatamente"

> "deixe 4x maiores estes botões, só os diminua se a equipe tiver completa já quando o jogo abre"

- Causa: o controlador emitia nomes de ação genéricos ("enter", "tab_next", A/D como left/right) que menu, configurações, modais e seleção não reconheciam. `_view_action` agora traduz por tela; A = dossiê avançado e D = dossiê de skill (como mostram os rótulos), 1–4 = camadas, Espaço = pular roleta, R = revelar.
- Botões do menu (PLAY, SETTINGS, CREDITS, QUIT GAME): **4x de área = 2x largura e altura** (resposta do criador); gaveta PLAY movida para a direita.
- Teste: `--scenario=PREGAME_KEYS` (11 teclas reais, ok).
- **Pendente (criador):** quando os botões diminuem ("equipe completa" ainda não definida, hoje ficam sempre grandes); opção de NEW GAME com só o líder ou com 1 ou 2 aliados (hoje cria líder + 1 aliado), onde fica essa opção.
