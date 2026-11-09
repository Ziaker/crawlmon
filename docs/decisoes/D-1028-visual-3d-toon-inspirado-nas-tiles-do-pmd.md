# D-1028 — Visual 3D toon inspirado nas tiles do Pokémon Mystery Dungeon

- **Data:** 2026-11-09
- **Área:** Exploração / direção visual 3D / cenário / shaders
- **Origem:** o criador definiu a direção visual do 3D depois do lab em terceira pessoa (D-1023) e da direção 3D (D-1022).
- **Status:** tratamento definido (**reconstrução 3D baseada no visual das tiles + toon só no overworld**); bioma inicial, escala, fidelidade, materiais e licença pendentes; **nada implementado**; nada publicado.

## O que o criador disse (literal)

> e o visual 3D ser baseado visualmente nessas tiles, no caso, as malhas e detalhes

> usando o filtro toon para tudo

Respostas desta rodada:

> 1 - render top-down

> 2 - sim, reconstrução baseada no visual

> 3 - overworld

> 4 - sim, também será usado para outras coisas eventualmente

"Essas tiles" são as tiles do Pokémon Mystery Dungeon (Explorers of Time/Darkness/Sky) que o projeto já usa no 2D, incluindo os 16 biomas do `assets/pmd/dungeons/sky/atlas/biome_pool.json` (`murky_forest`, `limestone_cavern`, `barren_valley`, `icicle_forest`, `temporal_spire`, `4th_station_pass`, etc.).

## Decisão

1. **O visual do cenário 3D é baseado visualmente nas tiles do PMD**, em especial nas **malhas e detalhes** delas, e não em um kit de pedra genérico.
2. **Reconstrução 3D:** as tiles são traduzidas para **geometria 3D low-poly** baseada no visual (paredes, piso, degraus, arcos, rachaduras, props), **não** como textura 2D esticada sobre uma malha simples (resposta 2).
3. **Filtro toon em tudo dentro do overworld 3D** (resposta 3): personagens, cenário, props e efeitos do overworld usam o mesmo tratamento, para o conjunto parecer um jogo só. **A batalha 3D fica fora**; ela só muda com uma decisão nova.
4. Esta decisão é de **direção visual**. Ela não muda sozinha a batalha 3D, a party, os atributos, os Moves, a UI de combate ou as regras (D-1022).
5. A geração procedural e a lógica de salas/corredores continuam valendo (D-326: tilesets modulares sobre a geração; não substituir por mapas completos).

## O que ainda precisa ser definido (ambiguidades)

- **Fidelidade da reconstrução:** recriar os detalhes das tiles com liberdade autoral (mesmo clima/paleta/props) ou copiar fielmente as formas e o pixel art? O nível de fidelidade muda o tempo e o risco de ficar "torto".
- **Quais partes reconstruir primeiro:** piso, paredes, batentes, arcos, degraus, portas, água/lava, props, teto. O lab atual é um corredor de pedra; o primeiro kit precisa de uma lista.
- **Bioma inicial:** começar por qual dos 16 biomas do PMD? `murky_forest`, `limestone_cavern`, `barren_valley`, `temporal_spire`, `icicle_forest` ou outro?
- **Escala/grid 3D:** tamanho da célula (metros), altura de parede, largura de corredor e proporção dos props. O lab usa alturas provisórias (Abra 1,0 m, Pancham 0,7 m, Orc 2,1 m) e um corredor largo; o kit 3D precisa de uma grade definida.
- **Materiais e paleta:** como a geometria low-poly recebe cor? Cores flat por material, vertex color, textura pequena pintada à mão ou paleta por bioma? O toon precisa de uma rampa de luz; definir quantas bandas e se há contorno preto.
- **Escopo do toon dentro do overworld:** inclui VFX, partículas, água/lava e UI 3D? "Tudo" foi respondido como overworld, mas a lista exata de sistemas pode ficar para a implementação.
- **Relação com D-1016:** o jogo normal 2D usa o shader pixel nos modelos 3D; o toon é para o overworld 3D novo, não para o 2D. Confirmar que o pixel shader do jogo normal não muda.
- **Licença:** a D-325 autoriza os assets 2D do PMD no projeto; usar as **formas** como referência para geometria autoral é o caminho mais seguro. Copiar fielmente as tiles/texturas continua sendo material de terceiros (Square Enix/Chunsoft); para publicar, o kit 3D teria de ser original ou licenciado.
- **O que "outras coisas" significa na resposta 4:** o criador disse que "também será usado para outras coisas eventualmente"; confirmar se é o ícone do mini-mapa, o kit 3D ou o sistema de marcadores.

## Estado

Nada implementado. O lab 3D continua com o corredor de pedra neutro e os modelos sem toon. Nenhum shader toon, kit 3D ou textura do PMD foi criado/importado para o 3D.
