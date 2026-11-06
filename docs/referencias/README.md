# Referências de dungeon

## O que mostrou o problema

- `temporal_tower_sky_map.png` — sheet de **backgrounds/mapas** de Temporal Tower (Explorers of Sky, asset 146840). Os quartos do jogo são **backgrounds pintados**: nuvens amarelas, caminho de pedra, pilares azuis e portais. Não são um grid uniforme de tiles 24 px.
- `temporal_tower_time_darkness_tileset.png` — sheet de **tileset** de Temporal Tower (Explorers of Time/Darkness, asset 84824). Ele tem os blocos 3×3 de topo/face/chão, mas é um kit para montar mapas customizados; não é o quarto como aparece no jogo.

## Consequência

O atlas de 24 px, por mais que os blocos 3×3 estejam corretos, **não reproduz** a composição dos quartos do PMD: o jogo usa salas pintadas, com caminhos e paredes próprios. Trocar células do tileset não vai chegar no resultado do background.

## Opções para o próximo passo

- **A. Backgrounds como salas/modelos:** usar os backgrounds pintados como salas, com colisão/walkable desenhados por cima. Alta fidelidade; reduz a geração procedural.
- **B. Tileset novo a partir do background:** extrair piso de nuvem, caminho de pedra, borda de rocha e vazio, criar tiles seamless e manter o gerador procedural. Mais trabalho; fidelidade média.
- **C. Voltar ao visual original do jogo** (pedra azul escura gerada) e guardar os assets PMD para outro momento.

A escolha é do criador. Nada foi commitado ou publicado.
