# D-991 — Modelos 3D de Abra/Pancham/Orc no overworld (lab) e estilos de shader

- **Data:** 2026-11-08
- **Área:** Exploração / overworld / visual 3D
- **Origem:** o criador acha estranho o 3D ao lado do pixel art e pediu para trocar os sprites dos Pokémon jogados pelos modelos deles **só para testar**; depois, ver se um shader deixa menos estranho.
- **Status:** lab implementado; na época, o **jogo normal continuava com os sprites 2D**; 3 opções de shader gravadas e apresentadas; escolha feita na D-1016; nada publicado.
- **Nota (D-1016):** o criador escolheu o estilo **pixel** e o jogo normal passou a usar os modelos 3D de Abra, Pancham e Orc. Esta decisão continua descrevendo o laboratório e as opções; no jogo normal, vale a D-1016.

## O que o criador disse (literal)

> não consigo gostar de como ficam estranhos os modelos comparado com os sprites, vamos fazer uma mudança, troque os sprites dos pokemons que jogamos pelos modelos deles também só para testar

> depois veja se há possibilidade de criarmos um shader que deixe menos estranho

Respostas da rodada:

> Lab separado

> Igualar aos sprites

> Propor 3 opções

## Decisão

1. **Onde:** laboratório separado, `scenes/debug/pokemon_3d_overworld_lab.tscn` (+ `scripts/debug/pokemon_3d_overworld_lab.gd`). O jogo normal **não** muda: Abra e Pancham continuam com sprite 2D e o Orc continua 3D como em D-389.
2. **Tamanho:** os modelos são escalados para o tamanho dos sprites, não para a altura real da espécie. Alturas em pixels de mundo: **Abra 25, Pancham 24, Orc 30**. Fórmula do `Sprite2D`: `scale = pixel_height * 1.5 / render_size`, `offset = -render_size / 3` (os pés ficam na base do personagem).
3. **Render 3D→2D:** mesmo pipeline de D-389 — `SubViewport` transparente, câmera ortográfica 3/4 (`size = 1.5`, olhando para y=0,5), modelo normalizado para altura 1 com os pés em y=0. Pokémon são Z-up (giram X 90°); o Orc usa o perfil DQT (Y-up, `rotation_y = 180`). Idle/walk vêm dos clipes do GLB; o root motion é removido e o modelo vira para a direção do movimento.
4. **Shader (3 opções),** `shaders/overworld_model_style.gdshader`, aplicado no `Sprite2D` que mostra a textura do SubViewport:
   - **pixel:** render em 64×64 com filtro *nearest*, paleta de 6 níveis, saturação 1,15, contraste 1,08 e silhueta escurecida.
   - **toon:** render em 160×160 com MSAA, 3 bandas de luz (força 0,75), paleta de 12 níveis, contorno escuro.
   - **Pixel + Toon:** 64×64 *nearest*, 3 bandas (força 0,55), 6 níveis, contorno escuro.
   - **Sem shader** é a referência (160×160, linear, sem pós-processamento).
5. **Contorno 3D removido:** o *inverted hull* de `VfxLib.outline_model` foi retirado do overworld porque desenhava um disco escuro sob os pés na vista de cima; os materiais são achatados (`SPECULAR_TOON`, `roughness` 0,9) em vez disso.
6. **Gravação:** mesmo andar para os quatro estilos (`GameState.new_dungeon(20261108, false)`), encontros removidos para a batalha não matar o gravador, clima desligado no lab (o jogo normal mantém o clima de D-381/D-382).
7. **Referências:** `docs/referencias/exploracao/modelos_3d/` com `modelos_3d_estilos_ingame` (4 estilos no mapa real, 2×2), `modelos_3d_estilos_compare` (sprite 2D + 4 estilos, ampliado 2×) em MP4, GIF e PNG.
8. **O jogo normal não ganha shader nenhum** até o criador escolher uma opção. *(Superado pela D-1016: o estilo escolhido foi o pixel e o jogo normal passou a usá-lo.)*

## Verificação

- O lab carrega a exploração real, cria o Orc próprio (a exploração não cria outro, via `DungeonFollower3D.enabled = false`) e mostra Abra, Pancham e Orc em 3D.
- Abra, Pancham e Orc foram testados em yaw 0 e 180: nos três, **yaw 0 mostra o rosto** para a câmera ("para baixo"). Mapeamento usado: baixo 0°, cima 180°, esquerda −90°, direita +90° (DQT igual, porque o `rotation_y = 180` já está no perfil).
- Os quatro estilos foram gravados no **mesmo andar**, mesmas posições, 240 quadros a 30 fps (8 s), andando para a direita e para baixo.
- A comparação controlada mostra o sprite 2D atual na primeira coluna e os quatro estilos nas demais, com os mesmos três personagens.
- Nenhum erro de script ou de shader nas gravações.

## O que não foi verificado

- **Escolha do shader:** resolvida na D-1016 (pixel).
- **Tamanho:** os modelos 3D ainda leem um pouco maiores que o corpo visível dos sprites (o sprite 32×32 tem corpo de ~16–18 px); não foi pedido ajuste.
- **Sombra do chão:** a elipse escura sob o jogador é o blob shadow existente (D-313), não o modelo 3D; ela continua aparecendo no lab e não foi alterada.
- **Performance:** 3 SubViewports 3D ativos no lab (e 12 na cena de comparação); não medida.
- **Walk/foot sliding:** velocidade da animação contra os 180 px/s não calibrada.
- Batalha, party, colisão e IA: não tocadas; o lab é visual.
- Os GLBs são ignorados no Git (`assets/modelos/`); sem os assets o lab cai num capsule de fallback.

## Estado

Lab e comparação implementados; jogo normal com sprites 2D intacto e sem shader; commits locais; **nada publicado**. Aguardando o criador escolher (ou rejeitar) uma das três opções de shader.
