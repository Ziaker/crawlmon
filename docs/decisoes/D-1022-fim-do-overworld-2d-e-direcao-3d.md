# D-1022 — Fim do overworld 2D e nova direção 3D (escopo pendente)

- **Data:** 2026-11-08
- **Área:** Exploração / overworld / direção visual / escopo
- **Origem:** depois do teste de escala dos modelos 3D (D-1018), o criador concluiu que não quer mais o overworld 2D.
- **Status:** direção registrada; **o escopo 3D ainda não foi definido**; o jogo 2D atual continua sendo a build de referência; **nada implementado**; nada publicado.

## O que o criador disse (literal)

> ok desisto do jogo ter o overworld 2D...

## Decisão

1. **O overworld deixa de ser 2D.** A direção passa a ser um overworld 3D. Esta decisão **substitui**, no que diz respeito ao overworld, a D-275 (overworld 2D com referência da arena), a D-278 (restaurar o overworld 2D) e a D-313 (overworld 2D, tiles e efeitos).
2. **Nada de código ainda.** O estilo de câmera, a geração de mapa, os assets de cenário, os seguidores, a névoa, os encontros e a transição para a batalha **não estão definidos**. Não vou iniciar um rewrite no escuro.
3. **O jogo 2D atual não é apagado.** Ele continua funcionando como referência/fallback até a fatia 3D ser aprovada. A batalha 3D, a party, os atributos, os Moves e a UI não mudam por esta decisão.
4. **A lab de escala (D-1018) fica superada para o overworld**: em 3D, o tamanho é definido pela escala do mundo e pela câmera, não por `pixel_height`. As proporções entre Abra, Pancham e Orc continuam úteis como referência.
5. **Os sprites 2D de Dragon Quest pesquisados não são para o overworld 3D.** Eles poderiam servir para menus/bestiário, mas não para o cenário; os modelos 3D (DQT e Pokémon) passam a ser a base visual.
6. **Próximo passo obrigatório:** uma **lab de uma sala/corredor 3D** com as duas câmeras candidatas — top-down 3D (diorama) e terceira pessoa estilo SMT III — para o criador escolher com vídeo. Só depois disso o overworld 2D é substituído.
7. **O que precisa ser decidido antes da fatia:** câmera; geração do mapa (salas/corredores 3D ou tiles 3D); kit de cenário (blocos/texturas ou kit modular); colisão e navegação; seguidores; névoa/iluminação; encontros e transição para a batalha; controles; performance (gl_compatibility, desktop/mobile/web).
8. **O que não muda:** batalha 3D, party, atributos, Moves, UI, economia e regras de combate. O overworld é a parte que será refeita.

## O que já existe a favor

- A batalha já é 3D e os personagens (Abra, Pancham, DQT Orc, Cyclops, Slime) têm modelos/animacões.
- O pipeline de modelo 3D→2D de D-389/D-991 pode ser aposentado no overworld, mas o carregamento dos GLBs e os clipes de idle/walk continuam úteis.
- A geração procedural em grid, o A* e a lógica de encontros podem ser adaptados para células 3D; a renderização, a câmera, a colisão e a névoa 2D não.

## O que não foi decidido

- Câmera: top-down 3D, isométrica ou terceira pessoa estilo SMT III.
- Mapa: salas/corredores 3D autorais, grade 3D com tiles texturizados ou kit modular.
- Escala do mundo: 1 unidade = 1 metro? 1 tile = 1 unidade?
- Assets de cenário: não existe kit 3D de dungeon no projeto.
- Seguidores: fila em 3D, rastro 3D ou outro comportamento.
- Névoa/iluminação: como a visão do dungeon funciona em 3D.
- Encontros: contato no mundo 3D, símbolos, ou transição para a arena.
- Plataformas: desktop, mobile, web.
- Se a troca será incremental (uma sala) ou um novo modo separado.

## Próximo passo proposto

Uma **lab 3D** pequena, sem tocar no jogo normal:
- uma sala/corredor com piso, paredes e teto;
- Abra, Pancham e Orc nos modelos atuais;
- duas câmeras na mesma sala: **top-down 3D** e **terceira pessoa SMT III**;
- andar, colidir, virar, um inimigo e uma porta/escada;
- vídeos das duas câmeras para o criador escolher.

Se a câmera e o estilo forem aprovados, aí sim uma decisão nova define a substituição do overworld 2D e a fatia vertical.

## Estado

Direção registrada; nenhuma cena ou script 3D criado; o overworld 2D continua no ar como referência; commits locais; **nada publicado**.
