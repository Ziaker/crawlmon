<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1156 — Notificação de coleta de item no overworld 3D: Paper Tag (opção A)

- **Data:** 2026-11-11.
- **Área:** Overworld 3D / HUD / coleta de item / lab Murky Forest.
- **Relacionadas:** D-1151 (salas e itens), D-1074/D-1090/D-1094 (cards, papel e tinta), D-1154 (telemetria; esta UI não é combate).
- **Status:** **implementado no lab; aguardando aprovação visual**; código na árvore de trabalho; **sem push**.

## O que o criador disse (literal)

> crie um prototipo com 3 opções visuais para uma notificação de coleta de itens

> opção A mas com algumas correções de posição de texto

> deixe o texto em ingles e ter um animação da coleta como um orbe brilhante saindo do chão e se movendo rapidamente até o local onde surge a notificação, na posição do ícone

> o impacto do efeito ao chegar no local devia gerar o cartão proceduralmente, inclusive faça com que o movimento seja iniciando com um arco bem fechado até o local de impacto

## Decisão

1. A opção **A (Paper Tag)** é a escolhida entre A/B/C.
2. A notificação aparece na **coleta automática** dos itens do overworld 3D (D-1151), com o **ícone real** do item, o nome, o tipo e o selo **`+1`**.
3. Visual aprovado: etiqueta de papel bege, borda irregular, tinta escura, kicker `ITEM COLLECTED`, nome em Georgia, ícone em círculo escuro e selo circular `+1`; o selo `NOVO` foi removido por ficar cortado. Todo o texto do card fica em inglês.
4. As opções **B (SMT Uplink)** e **C (Comic Burst)** continuam no protótipo HTML para comparação; não entram no jogo.

## Correções de posição de texto

O criador pediu correções mas **não detalhou quais**. O assistente aplicou as correções visíveis no print, **sujeitas à confirmação dele**:

- Kicker, nome e subtítulo na **mesma coluna** (x = 80); antes o nome começava em x = 78 e os outros em x = 80.
- Bloco de texto **centrado verticalmente** no papel (kicker y = 20, nome y = 29, subtítulo y = 56); antes o bloco ficava alto.
- Coluna de texto limitada a **168 px** para não invadir o selo `+1` (x = 254).
- Nome com **auto-ajuste** de 23 até 16 px quando não couber: `SUPER POTION` cai para 20 px e não é cortado.

Se o criador quis dizer outras posições, esta lista é a proposta a corrigir; **nada além dela foi movido**.

## Layout no jogo

- Card **300×86**, ancorado em **(20, 96)**, rotação **−1,5°**, `CanvasLayer` **22**; o pivô de escala/rotação é o **centro do ícone**.
- Ícone 54×54 (círculo escuro) com textura 40×40 nearest; nome 23 px; kicker 9 px; subtítulo 8 px; `+1` 34 px.
- O card fica **invisível** até o impacto. No impacto ele nasce do ícone: escala **0,1×0,35 → 1**, rotação **−7° → −1,5°**, alpha **0 → 1** em **0,12 s**; segura **2,2 s** e sai pela esquerda em **0,35 s**.
- Um novo pickup reinicia o orbe e o card; não bloqueia o mouse (`MOUSE_FILTER_IGNORE`).

## Orbe de coleta

- Control de tela cheia no `CanvasLayer` **23** (acima do card), com blend aditivo; nada depende de personagem, time ou lado: o ponto de partida é o **chão do item** projetado pela **câmera ativa** e o destino é o **centro do ícone da notificação** (D-235).
- **Arco fechado:** meia-volta de raio **32–52 px** em volta do item por **0,16 s** (sai do chão para a direita, sobe e termina no topo, já apontando para o impacto), seguida de voo em Bézier até o ícone; total **0,45 s**.
- O `show_item()` devolve o centro do ícone medido na posição final; o card só é revelado quando o orbe emite `arrived` no impacto.
- O rastro tem 14 amostras, uma explosão de luz marca o chão e um flash marca a chegada; o card cresce do mesmo ponto do flash.
- Um novo pickup reinicia o orbe; não há fila.

## HUD de vida e posição do card

- O HUD aprovado é o `ExplorationBattleHud` (D-1072/D-1074): cards **330×104**, ABRA creme e PANCHAM/ORC/GIBLE azul-escuros, retratos Sugimori e HP/MP, empilhados no topo-esquerdo a partir de `(14, 76)`; o HUD antigo de badges (D-1037) fica escondido, como no jogo.
- O card em `(20, 96)` cobre o **card do ABRA** e o topo do **PANCHAM**; ORC e GIBLE continuam visíveis abaixo.
- **Proposta:** manter o HUD onde está e mover o card para o **topo-centro** (`x = 490` em 1280×720), abaixo da faixa de ajuda e longe do mini-mapa; os quatro cards ficam 100% visíveis. O card continua nascendo do impacto; o orbe passa a mirar o centro do ícone nessa posição.
- Provas: `d1156_hud_atual.gif` (card atual + HUD aprovado), `d1156_hud_proposta.gif` (card no topo-centro + HUD aprovado), `d1156_hud_atual_sheet.png` e `d1156_hud_proposta_sheet.png`; cards `d1156_hud_left_card.png` e `d1156_hud_center_card.png`.
- O padrão do jogo continua em `(20, 96)` até a escolha; a posição é configurável por `set_home()`.
- A auditoria força `_tab_visible`/`_status_visible` (D-1075) e `_party_visible` para os cards aparecerem; no jogo normal eles aparecem após 5 s parado ou Tab.

## O que não muda

- Salas, itens, distância de coleta e inventário da D-1151.
- Ataque, câmera, movimento, paredes, mini-mapa, HUD de exploração e combate.
- Regras de combate e telemetria D-1154.

## Provas

- `docs/referencias/exploracao/3d/d1156_item_notification.png` — AMULET (nome 23 px, `amulet=2`).
- `docs/referencias/exploracao/3d/d1156_item_notification_super_potion.png` — SUPER POTION (nome 20 px, `super_potion=1`).
- `docs/referencias/exploracao/3d/d1156_orb_sheet.png` — 24 quadros (0,00–0,77 s) do orbe e do card nascendo.
- `docs/referencias/exploracao/3d/d1156_orb.mp4` (2,40 s, 3 repetições) e `d1156_orb.gif` (0,80 s, loop).
- Log: `[D-1156] orb start=... target≈(58, 139)`; `[D-1156] amulet name_size=23 ...` e `super_potion name_size=20`; cena `exit=0`.

## O que foi verificado

- As duas notificações aparecem na coleta, com ícone, nome, tipo e `+1`.
- O nome longo não é cortado e não invade o selo.
- As bordas do papel, ícone e selo continuam dentro do card.
- O orbe nasce no chão do item (projeção da câmera ativa), faz a meia-volta fechada e chega ao centro do ícone; o card só aparece **depois** do impacto.
- O card nasce do ícone (escala/rotação em volta dele) e cresce até o tamanho final; antes do impacto ele não aparece.
- Rastro, explosão no chão e flash no ícone aparecem; o card volta ao normal depois.

## O que não foi verificado

- Aprovação visual do criador para as correções de posição e para o orbe.
- A prova usa uma **câmera fixa de sala** (o jogador é revelado nos quadros); o caminho com a câmera normal atrás do jogador não foi capturado, porque o teleporte do audit deixa a câmera de jogo instável.
- Outras resoluções/aspectos além de 1280×720.
- Dois pickups durante o mesmo voo (o segundo reinicia o orbe).
- Item fora do campo de visão: o orbe começaria fora da tela e entraria.
- Se “arco bem fechado” é a **meia-volta em volta do item** (implementada) ou uma **curva única** do chão até o impacto; a segunda é um ajuste de trajetória.
- A posição **topo-centro** é uma proposta e **não** está ativada por padrão; o HUD mostrado é o demo de **4 cards** do `ExplorationBattleHud` (D-1074 inclui GIBLE), e o HUD real deve ler `GameState.party`.
- Nomes de item muito longos fora do catálogo atual.

## Estado

Implementado e provado no lab (card em inglês, orbe com meia-volta e card gerado no impacto); **sem push**. Entreguei também a comparação com o HUD (atual × topo-centro); o padrão ainda é o canto esquerdo. Aguardando a escolha do criador sobre a posição, o arco e o kicker (`ITEM COLLECTED` ou `ITEM ACQUIRED`).
