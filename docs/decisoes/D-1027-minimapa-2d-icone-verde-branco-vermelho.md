# D-1027 — O 2D vira apenas mini-mapa; ícone verde/branco/vermelho

- **Data:** 2026-11-09
- **Área:** Exploração / UI / mini-mapa / direção visual
- **Origem:** o criador definiu o papel do 2D depois da direção 3D (D-1022) e do lab em terceira pessoa (D-1023).
- **Status:** direção registrada; **detalhes de exibição, fonte do mapa e escala ainda pendentes**; nada implementado; nada publicado.

## O que o criador disse (literal)

> a ideia é usar a versão 2D apenas como o mini-mapa do jogo com este ícone só que verde indicando o jogador, branco indicando npcs e vermelho indicando inimigos

> e o visual 3D ser baseado visualmente nessas tiles, no caso, as malhas e detalhes

> usando o filtro toon para tudo

O ícone citado é a imagem anexada nesta conversa: silhueta em pixel art branca sobre fundo preto, simétrica, com duas antenas no topo, corpo central e quatro patas.

## Decisão

1. **O 2D não é mais o overworld jogável.** A versão 2D passa a existir **apenas como mini-mapa** do jogo 3D.
2. **Ícone do mini-mapa:** usar o ícone anexado como marcador, com três cores:
   - **verde** = jogador;
   - **branco** = NPCs;
   - **vermelho** = inimigos.
3. O mini-mapa pertence à exploração 3D; não é um modo 2D separado nem uma volta da D-275/D-278/D-313 (substituídas no overworld pela D-1022).
4. Esta decisão **não autoriza** mudar o jogo 2D atual, a batalha, a party, os Moves, a UI de combate ou as regras. O jogo 2D continua como referência/fallback até a fatia 3D ser aprovada (D-1022).

## O que ainda precisa ser definido (ambiguidades)

- **Fonte do mini-mapa:** é um render top-down do andar 3D gerado, ou o mini-mapa usa os dados do mapa 2D atual? As duas opções mudam a arquitetura.
- **Abrangência:** andar inteiro ou janela local ao redor do jogador? Tem névoa de guerra (áreas não exploradas)? Gira com a câmera ou fica fixo no norte? Fica sempre visível ou abre por botão?
- **Posição/tamanho:** canto da tela, tamanho em pixels, margem, transparência e resolução (o ícone é pixel art; precisa de `nearest`).
- **Ícone:** ainda não existe como arquivo transparente no projeto; a imagem anexada tem fundo preto. Precisa virar um PNG com alpha (ou ser redesenhado pixel a pixel). Tamanho, contorno, rotação, animação e se o mesmo desenho vale para as três cores.
- **Aliados:** Pancham e Orc são **verdes** (party) ou **brancos** (NPCs)? O pedido fala só em jogador, NPCs e inimigos.
- **NPCs:** o lab 3D atual não tem NPCs; só aliados e Slime. Definir o que conta como NPC no mini-mapa.
- **Conteúdo do mini-mapa:** paredes, portas, escadas, itens, baús e pontos de interesse aparecem? Com que símbolos?
- **Relação com D-1022:** a D-1022 mantém o jogo 2D como referência até a fatia 3D; esta decisão muda o papel do 2D no produto final, mas **não** apaga a build 2D de referência.

## Estado

Nada implementado. Nenhum código, cena, shader ou asset novo. O mini-mapa e o ícone continuam pendentes de definição e de arquivo.
