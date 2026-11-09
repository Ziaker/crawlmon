# D-1016 — Modelos 3D de Abra e Pancham no jogo normal, estilo pixel

- **Data:** 2026-11-08
- **Área:** Exploração / overworld / visual 3D
- **Origem:** depois do laboratório de D-991 com quatro estilos gravados, o criador escolheu o estilo **pixel** e respondeu onde ele entra, qual tamanho manter e o que fazer com a sombra do chão.
- **Status:** implementado; no jogo normal, Abra, Pancham e o Orc usam os GLBs com o shader pixel; sprites 2D saem quando o modelo existe; nada publicado.

## O que o criador disse (literal)

> pixel

Respostas da rodada:

> Abra, Pancham e Orc em 3D (Recommended)

> imagino que teremos que fazer um overhaul completo no mapa das dungeons, para caberem corretamente em cada tile, deixaremos no recomendado pois vamos mudar isso depois

> Esconder sob os 3D (Recommended)

## Decisão

1. **Onde:** no **jogo normal**, os sprites de Abra (líder), Pancham e do Orc são substituídos pelos modelos 3D. O laboratório de D-991 continua existindo como histórico; o jogo normal deixa de ser a referência 2D.
2. **Estilo:** **pixel**, a opção escolhida entre as três de D-991: render 64×64 com filtro *nearest*, paleta de 6 níveis, saturação 1,15, contraste 1,08 e silhueta escurecida (0,5 de escuridão, 1 px).
3. **Tamanho:** mantém o recomendado de D-991 — **Abra 25, Pancham 24, Orc 30 px de mundo**. O criador avisou que um overhaul completo dos tiles das dungeons, para os modelos caberem certo em cada tile, fica para depois; não é feito agora.
4. **Sombra do chão:** a elipse escura que `map_visuals.gd` já desenha sob as entidades (divergência com a D-313, registrada na D-324) **não** é desenhada sob os personagens que têm modelo 3D. NPCs, inimigos e itens continuam como estavam; nenhuma sombra nova é criada.
5. **Fallback:** se o GLB não existir no disco (clone sem `assets/modelos/`, que é ignorado no Git), o personagem continua com o **sprite 2D** normal. Nada de cápsula ou modelo-placeholder no jogo normal.
6. **Orc:** continua o terceiro seguidor **visual** de D-389 (atrás do Pancham, 32 px, 180 px/s, fora de `followers`, sem batalha/party/colisão/regra), agora usando a mesma vista 3D compartilhada dos Pokémon em vez de um viewport próprio.
7. **Visual-only:** batalha, party, colisão, IA, regras, tamanhos de colisão e clima **não** mudam. O clima do jogo normal continua o de D-381/D-382; só as gravações o desligam.
8. **Implementação:** a vista 3D→2D de D-991 (`DungeonModel3DView`) passa de `scripts/debug/` para `scripts/dungeon/` e é anexada ao jogador e aos seguidores em `exploration.gd`, escondendo o `Sprite2D` de cada um. O shader é o mesmo `shaders/overworld_model_style.gdshader`.
9. **Gravação:** um vídeo do **jogo normal** (não do lab) com os três modelos e o estilo pixel, andando nas quatro direções e parado, em MP4/GIF/PNG.

## Verificação

- Abra, Pancham e Orc aparecem em 3D no jogo normal com o estilo pixel.
- O sprite 2D some sob o modelo; a elipse escura some sob os três.
- Idle/walk e o virar para as quatro direções funcionam; o Orc continua atrás do Pancham com o rastro de D-314/D-361/D-388.
- Sem os GLBs, o jogo normal mantém os sprites 2D.
- Nenhum erro de script ou de shader nas gravações.

## O que não foi verificado

- **Overhaul dos tiles das dungeons:** adiado pelo criador; os modelos ainda leem um pouco maiores que o corpo visível dos sprites.
- **Divergência D-313/D-324:** o código já desenhava a elipse escura sob jogador, NPCs, inimigos e itens; D-1016 só a esconde sob os três modelos 3D. A divergência continua para NPCs, inimigos e itens e não foi resolvida aqui.
- **Performance:** três SubViewports 3D ativos no jogo normal; não medida.
- **Foot sliding:** velocidade do walk contra 180 px/s não calibrada.
- **Outras espécies:** só Abra, Pancham e Orc têm GLB; qualquer outra espécie continua em sprite 2D.
- Batalha, party, colisão e IA: não tocadas.

## Estado

Implementado no trabalho local; sprites de Abra/Pancham e o Orc usam o modelo 3D com estilo pixel no jogo normal; sem os assets, os sprites voltam; commits locais; **nada publicado**.
