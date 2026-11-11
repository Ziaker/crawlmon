# D-1165 — Status: esconder o HUD do overworld e mostrar o card de Move do Abra

- **Data:** 2026-11-11.
- **Área:** UI / HUD de status / overworld.
- **Relacionadas:** D-1150/D-1159 (pausa de status), D-1156/D-1157/D-1158 (HUD/notificações do overworld), D-1070 (HUD que aparece parado), D-1144 (Mystic/Megido), D-235 (nada depende de personagem/time/lado), D-1154 (esta correção é de overworld/UI, fora do `BattleTrace`).
- **Status:** **implementado e provado no lab real**; **sem push**.
- **Numeração:** usa **D-1165** porque `D-1157`/`D-1158` já colidem com arquivos de outra sessão e `D-1163`/`D-1164` foram ocupados por outras sessões durante esta correção. Nada de outra sessão foi renumerado.

## O que o criador disse (literal)

> correções

> 1 - remova essas huds relacionadas ao overworld quando o jogador abre a hud de status

> 2 - apenas com o pancham aparece na direita as descrições dos moves, não com o abra, corrija

## Decisão

1. **Ao abrir a tela de status, todo HUD do overworld some.** Ficam ocultos: barra de ajuda, minimapa, prompt `E TALK`/`[Z] TALK`, prompt de saída, cards de HP/MP, HUD de diálogo, banners de aliado, HUD de ataque, notificações de coleta e orbe. O que não é HUD (vinheta, clima, mundo 3D, câmera) não muda.
2. **Ao fechar o status, cada HUD volta exatamente ao estado de visibilidade que tinha antes.** Um HUD que já estava oculto por conta própria continua oculto; um que estava visível volta visível.
3. **O card de descrição do Move, na parte de baixo à direita, tem de aparecer para qualquer membro da party.** O caso do Abra falhava porque **Megido é `MYSTIC`** e esse elemento não existia nas tabelas de cor do status; o desenho era abortado antes do card. Mystic passa a ter cor/ícone próprios e nenhum elemento pode mais abortar o desenho por falta de chave.
4. **Nada mais muda:** regras de combate, ATB, fila, dano, status, posições, câmera, coleta, inventário e notificações continuam iguais. A correção é de desenho/visibilidade.

## Implementação

- `scripts/ui/menus.gd`: grupo `overworld_hud`, `_hide_overworld_huds()` guarda a visibilidade anterior e `_restore_overworld_huds()` devolve ao fechar o status (`closed`). O caminho é o mesmo do `X` e do `Esc` (o `StatusScreen` emite `closed`).
- `scripts/debug/murky_forest_3d_lab.gd`: entram no grupo as camadas do minimapa (15), badges (18), ajuda/saída (20), diálogo/ataque/prompt (22), notificações (22) e orbe (23).
- `scripts/debug/third_person_3d_lab.gd`: camada de ajuda/saída (20) entra no grupo.
- `scripts/debug/exploration_battle_hud.gd`: a camada dos cards (19) entra no grupo.
- `scripts/ui/status_screen.gd`: `MYSTIC` entra em `ELEMENT_COLORS` (`#65b5b3`) e `ELEMENT_GLYPH_COLORS` (texto escuro), com ícone `mystic.svg`; os acessos diretos a `BattleFx.COLORS[...]` viraram `.get(..., fallback)` para nenhum elemento novo derrubar o `_draw_moves()`.
- `tests/ui/capture_status_screen_real.gd`: o Megido do cenário de captura passou de `LUZ` para `MYSTIC`, igual ao catálogo real (D-1144); era o que mascarava o bug.

## Provas

- `docs/referencias/exploracao/3d/d1165_status_hud_abra.png` — status do Abra aberto no **lab real**: nenhum HUD do overworld aparece; o card mostra `TACKLE`.
- `docs/referencias/exploracao/3d/d1165_status_hud_abra_megido.png` — o mesmo status com **MEGIDO** selecionado: card teal de Mystic desenhado, sem erro.
- `docs/referencias/exploracao/3d/d1165_status_hud_restored.png` — status fechado e menu fechado: barra de ajuda, minimapa e card do Abra voltaram.
- Log do audit (`video_lab/audit_status_hud.tscn`): grupo com **7** camadas; `initial visible=true` em todas, `status open visible=false` em todas, `status closed + idle visible=true` em todas; `ExplorationBattleHud` com `status_visible=true` e card do herói `visible=true` depois do idle.
- Reprodução anterior: `SCRIPT ERROR: Out of bounds get index '11'` em `status_screen.gd:1000` (`_draw_moves`) assim que o Abra tinha Megido; depois da correção o mesmo cenário desenha os 7 Moves sem erro.
- `tests/ui/capture_status_screen_real.gd`: 8 capturas `[CAPTURE_SUCCESS]`, sem erro de script.

## O que não foi verificado

- A abertura por **teclado real** no jogo (o audit chama o mesmo caminho `Menus._open`/`_on_chosen`; o fechamento usa o mesmo sinal `closed` que o `X`/`Esc` emite). Não testei com um humano segurando as teclas.
- Outras cenas que ainda não marcaram seus HUDs no grupo `overworld_hud`: só o lab 3D e o `ExplorationBattleHud` foram marcados; a exploração 2D não tem esses HUDs e não foi tocada.
- Outras resoluções/aspectos e o comportamento do grupo se o status for aberto durante um diálogo.
- Combate, dano, fila e VFX **não** foram testados nesta correção, porque nada neles mudou.
- O documento do D-1158 continua com a colisão de ID; este D-1165 não a resolve.

## Estado

Implementado/provado no lab real; **sem push**. O commit seletivo continua pendente da escolha de numeração das decisões antigas (D-1157/D-1158).
