# D-1075 — Status do overworld: aparecer após 5 s parado ou com Tab

- **Data:** 2026-11-09.
- **Área:** Exploração / HUD / visibilidade dos cards.
- **Relacionadas:** D-1072/D-1074 (cards), D-1023 (overworld), D-1027 (mini-mapa).
- **Status:** **teste implementado e verificado** no lab isolado; batalha, 2D e menus não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> so faca os statuses aparecerem caso o jogador ficar parado por um tempo ou apertar Tab, inclusive cade o filtro toon que tinha:

## Decisão

1. **Cards escondidos por padrão** enquanto o jogador se move.
2. **5 segundos parado:** os cards de HP/MP aparecem automaticamente. O tempo conta sem deslocamento real do jogador (posição), não apenas sem tecla.
3. **Tab alterna:** uma pressão mostra/esconde os cards na hora; Tab funciona mesmo em movimento. Se o Tab deixou visível, os cards continuam visíveis ao andar; se o Tab deixou escondido, ficam escondidos até novo Tab ou até o jogador andar e parar por 5 s.
4. **Só os cards:** mini-mapa, bolinhas, alerta “!”, prompt/diálogo e o mundo 3D continuam sempre visíveis.
5. **Escopo:** só o overworld 3D (`ExplorationBattleHud`); batalha, status screen, menus, 2D e regras não mudam.
6. **Retorno ao automático:** se o Tab escondeu e o jogador andar, o modo manual é liberado; ao parar, a contagem de 5 s volta a valer. Se o Tab mostrou, o modo manual permanece até novo Tab.

## Ambiguidades

- **Tempo de 5 s:** escolhido pelo criador na pergunta; ajustável por constante.
- **Tab alterna:** uma pressão; não é “segurar”.
- **Cards do herói e aliados:** todos seguem a mesma visibilidade; o card do herói não fica sozinho.

## Teste implementado (2026-11-09)

- **Início (parado há 0,29 s):** `visible=0`, cards escondidos.
- **5,29 s parado:** `visible=4`, aparecem sozinhos.
- **Tab com os cards visíveis:** esconde (`visible=0`).
- **Tab de novo:** mostra (`visible=4`).
- **Tab para esconder e movimento:** `visible=0`; o movimento libera o modo manual.
- **5 s parado depois do movimento:** `visible=4`, volta ao automático.
- **Provas:** `docs/referencias/exploracao/3d/murky_forest_status_hidden.png` (escondido), `murky_forest_hud_sugimori.png` (visível após 5 s), recorte `murky_forest_hud_sugimori_cards.png`, vídeos `murky_forest_status_party.mp4/.gif` e `murky_forest_status_solo.mp4/.gif` (15 s) e a folha `murky_forest_status_contato.png`.
- **Escopo:** só o `ExplorationBattleHud`; mini-mapa/alerta/prompt seguem sempre visíveis. A cena principal em headless está bloqueada pelos erros de VFX de outra sessão; o teste foi no isolado.

## O que não foi verificado

- Tab com o teclado real do jogo (o teste chamou a função de toggle; o polling de `Input.is_key_pressed(KEY_TAB)` está implementado).
- 60 fps/mobile, outras resoluções e o comportamento durante diálogo.
- As mídias antigas D-1028/D-1071/D-1072 mostram os cards sempre visíveis; são anteriores à D-1075.

## Estado

Teste implementado e verificado no lab isolado. Cards escondidos ao andar, auto após 5 s parado e Tab alterna; provas registradas; commit local; **sem push**. Batalha/2D intactos.
