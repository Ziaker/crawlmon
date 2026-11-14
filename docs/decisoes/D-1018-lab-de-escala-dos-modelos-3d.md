<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1018 — Lab de escala dos modelos 3D: variantes A/B/C/D

- **Data:** 2026-11-08
- **Área:** Exploração / overworld / visual 3D / laboratório
- **Origem:** depois de ver os modelos 3D pequenos no ambiente, o criador pediu para testar uma lab de escalas antes de decidir qualquer mudança no jogo.
- **Status:** lab implementado; 5 variantes gravadas (A/B/C/D + C32); **o jogo normal não muda**; escolha da variante pendente; nada publicado.

## O que o criador disse (literal)

> vamos testar a lab de escalas

## Diagnóstico que originou o teste

- O pipeline dos tiles (D-345) recorta a arte nativa do PMD em **24×24 e escala 2× com nearest** para **48 px**. O ambiente está em 2×.
- Os sprites e os modelos 3D ficaram em 1×: Abra 25, Pancham 24, Orc 30 px de mundo (D-991/D-1016). O Abra ocupa ~0,52 tile; no PMD, o personagem ocupa ~1 tile.
- O sprite 2D antigo também era 1×; o 3D só tornou a diferença visível.
- Aumentar só os modelos deixaria o jogador gigante ao lado de NPCs e inimigos, que continuam em 1×.

## Decisão

1. **Só laboratório.** O lab testa a escala visual; nenhuma regra, colisão, velocidade, câmera do jogo normal ou clima muda. O jogo normal continua com D-1016.
2. **Variantes**, todas no mesmo andar (`GameState.new_dungeon(20261108, false)`), mesmo input e mesmo tempo de gravação:
   - **A:** escala 1,0× — Abra 25, Pancham 24, Orc 30; gap 32; zoom 2,3× (referência atual).
   - **B:** escala 1,5× — Abra 37,5, Pancham 36, Orc 45; gap 32; zoom 2,3×.
   - **C:** escala 2,0× — Abra 50, Pancham 48, Orc 60; gap 48; zoom 2,3× (Abra ~1 tile).
   - **D:** escala 2,0× — mesmos tamanhos; gap 48; zoom 2,8×, para testar o enquadramento mais fechado.
   - **C32 (extra):** escala 2,0× com o gap atual de 32 px, para mostrar a sobreposição da fila.
3. **Gap dos seguidores:** A/B mantêm **32 px** (D-361/D-388); C/D usam **48 px** (1 tile) porque corpos de 50–60 px com gap de 32 se sobrepõem. Uma variante extra **C32** repete o 2× com gap 32 para mostrar a sobreposição. O jogo normal continua com 32 px; o gap é uma variável do lab.
4. **Referências no quadro:** um **NPC** e um **inimigo** reais, mantidos em **1×** de propósito, para mostrar a inconsistência atual com o resto do mundo. O inimigo fica congelado (`can_act = false`) e fora do caminho do jogador; os outros encontros são removidos para a gravação não abrir batalha.
5. **Fatores de lab:** `DungeonModel3DView.height_scale` e `DungeonFollower.gap_scale`, ambos com padrão **1,0**; o jogo normal não os altera.
6. **Gravação:** 10 s a 30 fps, 1280×720, idle → direita → baixo → esquerda → cima → idle; quatro MP4s, um MP4 2×2, GIF, PNG de contato e um close 4×.
7. **Nada de escolha agora:** o criador escolhe a variante depois de ver os vídeos. Se uma variante vencer, uma nova decisão define os tamanhos finais e o que mais escala (NPCs, inimigos, pickups, gap, colisão, render 64→96 se necessário).

## Resultado do teste

- **A (1,0×):** é o jogo atual; Abra ~0,5 tile, visivelmente pequeno contra as paredes de 48 px.
- **B (1,5×):** melhora bastante; a fila ainda cabe com o gap de 32 e o NPC de 1× fica próximo do jogador.
- **C (2,0×, gap 48):** Abra ~1 tile; é a proporção mais próxima do PMD e a que faz o personagem “existir” no ambiente. Com o gap de 32 (**C32**), os três corpos se sobrepõem e a fila vira um bloco; com 48 a fila fica legível.
- **D (2,0×, gap 48, zoom 2,8×):** o personagem fica maior na tela, mas o campo de visão cai (~9,5 tiles de largura contra ~11,6 em A/B/C); o inimigo de referência chega perto da borda e a fila ocupa quase toda a altura. É o mais “SMT-like” dos quatro, e o mais claustrofóbico.
- **NPC e inimigo em 1×:** em B/C/D o jogador fica claramente maior que o NPC; se a escala maior vencer, NPCs, inimigos, pickups e sombras precisam acompanhar (ou o mundo fica inconsistente).
- **Render pixel:** em 2× o render de 64 px é ampliado ~1,7× na tela; o pixel fica mais grosso. Pode ser o look desejado ou pedir render 96/128.

## Verificação

- As cinco variantes rodaram no mesmo andar (`GameState.new_dungeon(20261108, false)`), com o mesmo input de 10 s, 300 quadros a 30 fps, 1280×720.
- O grupo foi colocado num salão com espaço (varredura de células livres) para a fila não ser julgada pelo aperto do spawn.
- NPC Bulbasaur fixo e um inimigo real congelado (`can_act = false`) em 1×, fora do caminho do jogador; os outros encontros foram removidos para não abrir batalha.
- Nenhum erro de script ou de shader nas gravações.
- Jogo normal: as três vistas 3D continuam anexadas, sprites escondidos; `test_follower_speed.gd` continua **OK** (180/180, passo 3,0 px).

## O que não foi verificado

- **Colisão e passagem** com corpos de 50–60 px: o raio do jogador continua 14 px e os corredores continuam de 48 px; não foi testado andar por corredores estreitos com 2×.
- **NPCs, inimigos, pickups e sombras em 2×:** o lab os mantém em 1× de propósito; a escala coerente do resto do mundo não foi testada.
- **Gap 48 em corredores/curvas:** o lab usa um salão; o comportamento da fila em corredores de 1 tile não foi medido.
- **Câmera 2,8× (D):** limites de câmera, névoa e enquadramento em salas pequenas não foram testados; só o salão.
- **Render 64 px em 2×:** o pixel fica mais grosso; não foi comparado com render 96/128.
- **Performance:** três SubViewports 3D com modelos maiores; não medida.
- **Batalha/party/colisão/IA:** não tocadas; o lab é visual.

## O que o lab não decide

- Se NPCs, inimigos, pickups e sombras também vão para 2× no jogo.
- Se o gap de 32 px (D-361/D-388) muda no jogo.
- Se o raio de colisão de 14 px acompanha o tamanho visual.
- Se a câmera de 2,3× (D-344) muda.
- Se o render pixel de 64 px sobe para 96/128 para segurar o detalhe em 2×.
- Se o overworld continua 2D (D-275/D-278/D-313) — o lab não muda essa direção.

## Estado

Lab implementado em `scenes/debug/model_scale_lab.tscn` + `scripts/debug/model_scale_lab.gd`; gravações em `docs/referencias/exploracao/modelos_3d/escala/`:
- `escala_a.mp4`, `escala_b.mp4`, `escala_c.mp4`, `escala_d.mp4` (10 s, 30 fps, 1280×720).
- `escala_c32.mp4` (2× com o gap atual de 32 px, para mostrar a sobreposição).
- `escala_2x2.mp4/.gif/.png` (A/B/C/D lado a lado, 2560×1440).
- `escala_close.png` (recortes 1:1 dos quatro), `escala_contato.png` (idle/direita/cima) e `escala_c32.png`.

Jogo normal intocado (D-1016, gap 32, câmera 2,3×); commits locais; **nada publicado**. A escolha da variante fica pendente do criador.
