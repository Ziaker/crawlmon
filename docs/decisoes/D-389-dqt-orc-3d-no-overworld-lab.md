# D-389 — DQT Orc 3D no overworld: lab de seguidor

- **Data:** 2026-11-07
- **Área:** Exploração / overworld / visual 3D
- **Origem:** o criador quer um personagem 3D de DQT apenas no overworld, seguindo os outros dois, com movimentação e idle.
- **Status:** lab implementado; o jogo normal não muda; nada publicado.

## O que o criador disse (literal)

> ok, agora vamos adicionar um personagem apenas durante o overworld para seguir os outros 2, MAS o problema é, ele é 3D, pois é um personagem de DQT, quero ver se consegue colocar ele no top-down funcionando normal com a movimentação e idle

Respostas:

> DQT Orc

> Lab no overworld

> Atrás do Pancham

## Decisão

1. **Personagem:** DQT Orc (`dqt_orc`), visual-only, só no overworld.
2. **Primeiro passo:** lab `scenes/debug/overworld_3d_follower_lab.tscn`; carrega a exploração real e adiciona o Orc atrás do Pancham. O jogo normal **não** spawna o Orc; nada de batalha/party.
3. **Render 3D→2D:** `SubViewport` 160×160, fundo transparente, MSAA 2×, câmera ortográfica 3/4, luz direcional e ambiente; a textura vai para um `Sprite2D` (escala 0,32; pés alinhados) no mundo 2D.
4. **Modelo:** GLB local `assets/modelos/dqt_orc/dqt_orc.glb` (ignorado no Git); perfil DQT (altura 2,1 m, rotação 180°), `apply_anim_aliases` (idle/walk), weapon follow, strip do root motion, respiração (`start_idle_breath`) e outline; sem sombra elíptica (D-313).
5. **Movimento:** mesmo rastro/gap/velocidade de D-314/D-361/D-388; o Orc segue o **Pancham** (fila Abra → Pancham → Orc), 32 px, 180 px/s, sem atravessar paredes. O modelo vira para a direção do movimento; walk enquanto anda, idle quando para.
6. **Lab:** desliga o clima (`debug_disable`) para o modelo aparecer limpo; o jogo normal não.
7. **Vídeo:** `docs/referencias/exploracao/dqt_orc_overworld_lab.mp4` — 8 s, 1280×720, 30 fps; idle → direita → baixo → esquerda → cima → idle; GIF, PNG e contato.

## Verificação

- O lab rodou no worktree principal; o Orc carregou, apareceu no top-down, andou atrás do Pancham e voltou ao idle; sem erro de script/shader.
- O `AnimationPlayer` tocou idle/walk; a arma acompanhou; o root motion foi removido.
- Vídeo, GIF, PNG e contato gerados.

## O que não foi verificado

- Integração no jogo normal (o lab é separado).
- Performance de um `SubViewport` 3D por seguidor; não medida.
- Foot sliding/velocidade do walk vs 180 px/s; não calibrado.
- Batalha, party e colisão: não entram.
- O GLB do DQT é ignorado no Git; o lab depende do asset local.
- O visual 3D contra o pixel art é julgamento do criador.

## Estado

Lab implementado; o jogo normal não muda; commits locais; **nada publicado**.
