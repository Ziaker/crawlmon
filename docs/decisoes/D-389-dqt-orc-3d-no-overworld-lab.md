# D-389 — DQT Orc 3D no overworld: seguidor visual

- **Data:** 2026-11-07
- **Área:** Exploração / overworld / visual 3D
- **Origem:** o criador quer um personagem 3D de DQT apenas no overworld, seguindo os outros dois, com movimentação e idle.
- **Status:** lab e jogo normal implementados; o Orc aparece atrás do Pancham no overworld; sem batalha/party; nada publicado.

## O que o criador disse (literal)

> ok, agora vamos adicionar um personagem apenas durante o overworld para seguir os outros 2, MAS o problema é, ele é 3D, pois é um personagem de DQT, quero ver se consegue colocar ele no top-down funcionando normal com a movimentação e idle

Respostas:

> DQT Orc

> Lab no overworld

> Atrás do Pancham

## Decisão

1. **Personagem:** DQT Orc (`dqt_orc`), visual-only, só no overworld.
2. **Primeiro passo:** lab `scenes/debug/overworld_3d_follower_lab.tscn`; carrega a exploração real e adiciona o Orc atrás do Pancham.
3. **Jogo normal:** `exploration.gd` spawna o Orc depois dos seguidores 2D, atrás do **último** deles (Pancham). Ele fica em `entities` (Y-sort), **não** entra em `followers`, então não é alvo de inimigo, não entra em batalha, party, colisão nem regra. Se o GLB não existir (clone sem `assets/modelos/`), o jogo não spawna nada e segue com os dois aliados 2D.
4. **Render 3D→2D:** `SubViewport` 160×160, fundo transparente, MSAA 2×, câmera ortográfica 3/4, luz direcional e ambiente; a textura vai para um `Sprite2D` (escala 0,32; pés alinhados) no mundo 2D.
5. **Modelo:** GLB local `assets/modelos/dqt_orc/dqt_orc.glb` (ignorado no Git); perfil DQT (altura 2,1 m, rotação 180°), `apply_anim_aliases` (idle/walk), weapon follow, strip do root motion, respiração (`start_idle_breath`) e outline; sem sombra elíptica (D-313).
6. **Movimento:** mesmo rastro/gap/velocidade de D-314/D-361/D-388; o Orc segue o **Pancham** (fila Abra → Pancham → Orc), 32 px, 180 px/s, sem atravessar paredes. O modelo vira para a direção do movimento; walk enquanto anda, idle quando para.
7. **Lab:** desliga o clima (`debug_disable`) para o modelo aparecer limpo; o jogo normal mantém o clima de D-381/D-382.
8. **Vídeos:** `docs/referencias/exploracao/dqt_orc_overworld_lab.mp4` (lab, 8 s) e `dqt_orc_overworld_normal.mp4` (jogo normal, 10 s), 1280×720, 30 fps; idle → direita → baixo → esquerda → cima → idle; GIF, PNG e contato.

## Verificação

- O lab rodou no worktree principal; o Orc carregou, apareceu no top-down, andou atrás do Pancham e voltou ao idle; sem erro de script/shader.
- A exploração normal rodou com o Orc atrás do Pancham nas quatro direções e no idle; a cena carregou sem erro de parse.
- O `AnimationPlayer` tocou idle/walk; a arma acompanhou; o root motion foi removido.
- Vídeos, GIFs, PNGs e contatos gerados.

## O que não foi verificado

- Performance de um `SubViewport` 3D por seguidor; não medida.
- Foot sliding/velocidade do walk vs 180 px/s; não calibrado.
- Batalha, party e colisão: não entram (o Orc não está em `followers`).
- O GLB do DQT é ignorado no Git; sem o asset o Orc simplesmente não aparece.
- O visual 3D contra o pixel art é julgamento do criador.

## Estado

Lab e jogo normal implementados; o Orc aparece atrás do Pancham no overworld; batalha/party/colisão intactas; commits locais; **nada publicado**.
