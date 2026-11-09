# D-1027 — O 2D vira apenas mini-mapa; ícone verde/branco/vermelho

- **Data:** 2026-11-09
- **Área:** Exploração / UI / mini-mapa / direção visual
- **Origem:** o criador definiu o papel do 2D depois da direção 3D (D-1022) e do lab em terceira pessoa (D-1023).
- **Status:** fonte do mini-mapa definida (**render top-down do andar 3D**); aliados definidos (verde, menores); arquivo do ícone e detalhes de exibição ainda pendentes; **nada implementado**; nada publicado.

## O que o criador disse (literal)

> a ideia é usar a versão 2D apenas como o mini-mapa do jogo com este ícone só que verde indicando o jogador, branco indicando npcs e vermelho indicando inimigos

> e o visual 3D ser baseado visualmente nessas tiles, no caso, as malhas e detalhes

> usando o filtro toon para tudo

Respostas desta rodada:

> 1 - render top-down

> 2 - sim, reconstrução baseada no visual

> 3 - overworld

> 4 - sim, também será usado para outras coisas eventualmente

O ícone citado é a imagem anexada nesta conversa: silhueta em pixel art branca sobre fundo preto, simétrica, com duas antenas no topo, corpo central e quatro patas.

## Decisão

1. **O 2D não é mais o overworld jogável.** A versão 2D passa a existir **apenas como mini-mapa** do jogo 3D.
2. **Fonte do mini-mapa:** é um **render top-down do andar 3D** (resposta 1), não os dados do mapa 2D atual. O mini-mapa acompanha o andar que o jogador está explorando no 3D.
3. **Ícone do mini-mapa:** usar o ícone anexado como marcador, com três cores:
   - **verde** = jogador;
   - **branco** = NPCs;
   - **vermelho** = inimigos;
   - **aliados** (Pancham/Orc) = **verde, o mesmo ícone do jogador, porém menores** (resposta 3).
4. O mini-mapa pertence à exploração 3D; não é um modo 2D separado nem uma volta da D-275/D-278/D-313 (substituídas no overworld pela D-1022).
5. Esta decisão **não autoriza** mudar o jogo 2D atual, a batalha, a party, os Moves, a UI de combate ou as regras. O jogo 2D continua como referência/fallback até a fatia 3D ser aprovada (D-1022).

## O que ainda precisa ser definido (ambiguidades)

- **Como é o render top-down:** câmera ortográfica ou perspectiva? Altura, ângulo, zoom e se o mini-mapa mostra o andar inteiro ou uma janela local ao redor do jogador.
- **O que o render mostra:** só piso/paredes (mapa limpo) ou o cenário 3D com props? O jogador, aliados e inimigos aparecem no render ou são escondidos e substituídos pelos ícones? Como fica a névoa de guerra (áreas não exploradas)?
- **Orientação e posição:** o mini-mapa gira com a câmera ou fica fixo no norte? Canto da tela, tamanho em pixels, margem, transparência e resolução (pixel art com `nearest`).
- **Ícone:** ainda não existe como arquivo transparente no projeto; a imagem anexada tem fundo preto. Precisa virar um PNG com alpha (ou ser redesenhado pixel a pixel). Tamanho, contorno, rotação, animação e se o mesmo desenho vale para as três cores. **No primeiro teste, usar um marcador provisório** até o PNG/desenho final.
- **Resposta 4:** "sim, também será usado para outras coisas eventualmente" — confirmar se o "sim" é sobre eu redesenhar o ícone ou apenas sobre o ícone ser reutilizável para outros marcadores no futuro. A resposta não escolheu entre "salvar o PNG" e "redesenhar".
- **Aliados:** definido: mesma cor do jogador (verde) e menores. Falta o tamanho em pixels e se o ícone do aliado é o mesmo desenho reduzido.
- **NPCs:** o lab 3D atual não tem NPCs; só aliados e Slime. Definir o que conta como NPC no mini-mapa.
- **Conteúdo do mini-mapa:** paredes, portas, escadas, itens, baús e pontos de interesse aparecem? Com que símbolos?
- **Relação com D-1022:** a D-1022 mantém o jogo 2D como referência até a fatia 3D; esta decisão muda o papel do 2D no produto final, mas **não** apaga a build 2D de referência.

## Estado

Nada implementado. Nenhum código, cena, shader ou asset novo. O mini-mapa, o bioma de teste e a escala estão definidos; o arquivo do ícone continua pendente (o primeiro teste usará um marcador provisório).
