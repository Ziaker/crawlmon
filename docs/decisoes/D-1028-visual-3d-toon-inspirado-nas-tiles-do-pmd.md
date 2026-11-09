# D-1028 — Visual 3D toon inspirado nas tiles do Pokémon Mystery Dungeon

- **Data:** 2026-11-09
- **Área:** Exploração / direção visual 3D / cenário / shaders
- **Origem:** o criador definiu a direção visual do 3D depois do lab em terceira pessoa (D-1023) e da direção 3D (D-1022).
- **Status:** direção registrada; **escopo do toon, tratamento das tiles e bioma inicial pendentes**; nada implementado; nada publicado.

## O que o criador disse (literal)

> e o visual 3D ser baseado visualmente nessas tiles, no caso, as malhas e detalhes

> usando o filtro toon para tudo

"Essas tiles" são as tiles do Pokémon Mystery Dungeon (Explorers of Time/Darkness/Sky) que o projeto já usa no 2D, incluindo os 16 biomas do `assets/pmd/dungeons/sky/atlas/biome_pool.json` (`murky_forest`, `limestone_cavern`, `barren_valley`, `icicle_forest`, `temporal_spire`, `4th_station_pass`, etc.).

## Decisão

1. **O visual do cenário 3D é baseado visualmente nas tiles do PMD**, em especial nas **malhas e detalhes** delas, e não em um kit de pedra genérico.
2. **Filtro toon em tudo** no 3D: personagens, cenário, props e efeitos visuais devem usar o mesmo tratamento toon, para o conjunto parecer um jogo só.
3. Esta decisão é de **direção visual**. Ela não muda sozinha a batalha 3D, a party, os atributos, os Moves, a UI de combate ou as regras (D-1022).
4. A geração procedural e a lógica de salas/corredores continuam valendo (D-326: tilesets modulares sobre a geração; não substituir por mapas completos).

## O que ainda precisa ser definido (ambiguidades)

- **"Malhas e detalhes":** reconstruir as formas das tiles como **geometria 3D low-poly** (paredes, degraus, arcos, rachaduras, props) com toon, ou usar as **tiles 2D como textura** em malhas 3D simples, ou um híbrido? As tiles foram desenhadas para top-down; texturizar piso/parede 3D diretamente tende a esticar e criar costura.
- **Escopo do "tudo":** só o overworld 3D, ou a batalha 3D também? Inclui personagens, props, VFX, água/lava, partículas e UI 3D? A D-1022 diz que a batalha não muda; para aplicar toon nela seria preciso uma decisão nova.
- **Tipo de toon:** shader por material (bandas de luz, outline, rampa de cor) ou pós-processo de tela? Com ou sem contorno preto? Quantas bandas? A paleta acompanha o bioma ou é fixa?
- **Relação com D-1016:** o jogo normal 2D usa o shader pixel nos modelos 3D; o toon é para o overworld 3D novo, não para o 2D. Confirmar que o pixel shader do jogo normal não muda.
- **Bioma inicial:** começar por qual dos 16 biomas do PMD? `murky_forest`, `limestone_cavern`, `barren_valley`, `temporal_spire`, `icicle_forest` ou outro?
- **Escala/grid 3D:** tamanho da célula (metros), altura de parede, largura de corredor e proporção dos props. O lab usa alturas provisórias (Abra 1,0 m, Pancham 0,7 m, Orc 2,1 m) e uma sala de pedra; o kit 3D precisa de uma grade definida.
- **Licença:** a D-325 autoriza os assets 2D do PMD no projeto; usar as **texturas 2D diretamente em 3D** é um uso novo e continua sendo material de terceiros (Square Enix/Chunsoft). Para publicar, o kit 3D teria de ser original ou licenciado. Reconstruir as formas como geometria autoral inspirada é o caminho mais seguro.
- **Fidelidade:** "baseado visualmente" pode significar (a) recriar o clima/paleta/props do bioma com liberdade autoral, ou (b) copiar fielmente as formas e detalhes das tiles. Definir o nível de fidelidade.

## Estado

Nada implementado. O lab 3D continua com o corredor de pedra neutro e os modelos sem toon. Nenhum shader toon, kit 3D ou textura do PMD foi criado/importado para o 3D.
