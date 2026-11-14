<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1028 — Visual 3D toon inspirado nas tiles do Pokémon Mystery Dungeon

- **Data:** 2026-11-09
- **Área:** Exploração / direção visual 3D / cenário / shaders
- **Origem:** o criador definiu a direção visual do 3D depois do lab em terceira pessoa (D-1023) e da direção 3D (D-1022).
- **Status:** tratamento definido (**reconstrução 3D baseada no visual das tiles + toon só no overworld**); bioma inicial (`murky_forest`) e escala do teste definidos; **teste implementado no lab isolado**; fidelidade, materiais e licença pendentes; nada publicado.

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
6. **Bioma inicial do teste:** `murky_forest`.
7. **Escala do primeiro teste (recomendação aceita pelo criador):** 1 unidade = 1 m; célula do kit 3 m; corredor de 2 células (6 m); parede de 4,2 m; copa/teto em 5,5 m; manter as câmeras do lab (3,4 m solo, 6,2 m grupo) para comparar. Não é a escala final do jogo.

## O que ainda precisa ser definido (ambiguidades)

- **Fidelidade da reconstrução:** recriar os detalhes das tiles com liberdade autoral (mesmo clima/paleta/props) ou copiar fielmente as formas e o pixel art? O nível de fidelidade muda o tempo e o risco de ficar "torto".
- **Quais partes reconstruir primeiro:** piso, paredes, batentes, arcos, degraus, portas, água/lava, props, teto. O lab atual é um corredor de pedra; o primeiro kit precisa de uma lista.
- **Bioma inicial:** definido: `murky_forest`; os outros 15 ficam para depois.
- **Escala do teste:** definida acima (1 m, célula 3 m, corredor 6 m, parede 4,2 m); a escala final do jogo continua aberta. O lab usa alturas provisórias (Abra 1,0 m, Pancham 0,7 m, Orc 2,1 m).
- **Materiais e paleta:** como a geometria low-poly recebe cor? Cores flat por material, vertex color, textura pequena pintada à mão ou paleta por bioma? O toon precisa de uma rampa de luz; definir quantas bandas e se há contorno preto.
- **Escopo do toon dentro do overworld:** inclui VFX, partículas, água/lava e UI 3D? "Tudo" foi respondido como overworld, mas a lista exata de sistemas pode ficar para a implementação.
- **Relação com D-1016:** o jogo normal 2D usa o shader pixel nos modelos 3D; o toon é para o overworld 3D novo, não para o 2D. Confirmar que o pixel shader do jogo normal não muda.
- **Licença:** a D-325 autoriza os assets 2D do PMD no projeto; usar as **formas** como referência para geometria autoral é o caminho mais seguro. Copiar fielmente as tiles/texturas continua sendo material de terceiros (Square Enix/Chunsoft); para publicar, o kit 3D teria de ser original ou licenciado.
- **O que "outras coisas" significa na resposta 4:** o criador disse que "também será usado para outras coisas eventualmente"; confirmar se é o ícone do mini-mapa, o kit 3D ou o sistema de marcadores.

## Teste implementado (2026-11-09)

- **Cena:** `scenes/debug/murky_forest_3d_lab.tscn` + `scripts/debug/murky_forest_3d_lab.gd`. O layout do L é o mesmo do lab de D-1023 (navmesh, câmera, aliados e Slime continuam valendo); o cenário de pedra foi substituído pela reconstrução 3D da Murky Forest.
- **Reconstrução low-poly:** chão roxo-escuro com folhas/chão irregular, paredes de tronco cobertas por aglomerados de folhagem teal/verde/roxa, copa escura, cogumelos, samambaias, raízes, pedras, vaga-lumes e uma saída verde. As formas foram reconstruídas a partir do visual das tiles, não texturizadas com o PNG 2D.
- **Escala do teste:** 1 unidade = 1 m; célula 3 m; corredor de 6 m; parede 4,2 m; copa 5,6 m; câmeras do lab (3,4 m solo, 6,2 m grupo) mantidas para comparar.
- **Toon:** todos os materiais 3D do overworld usam `DIFFUSE_TOON` + `SPECULAR_TOON` + rim, incluindo os materiais dos modelos importados (Abra, Pancham, Orc, Slime). A auditoria confirmou `toon player=true` e `toon env=true`. A batalha 3D, o shader pixel do jogo 2D e as regras não foram tocados.
- **Mini-mapa:** o render top-down do andar 3D entrou junto (D-1027): SubViewport 256×256, câmera ortográfica de 20 m, camada 5 só do mapa e marcadores verdes/vermelhos. A câmera principal não vê a camada 5.
- **Auditoria (solo e party):** 0 corpos em parede, 0 câmeras dentro de parede, 0 câmeras coladas, path mínimo 2, 0 pares empilhados, porta `near/visible/used` verdadeira, Slime em `CHASE`, mini-mapa com 4 marcadores e centro (128,128). Tudo passou.
- **Vídeos/stills:** `docs/referencias/exploracao/3d/murky_forest_solo.*`, `murky_forest_party.*`, `murky_forest_minimap.png` e as folhas de contato; 11,0 s, 330 quadros a 30 fps.

## O que não foi verificado no visual 3D

- Fidelidade fina às tiles do PMD: esta é uma primeira reconstrução autoral; proporções, detalhes e props ainda podem mudar.
- Performance medida em 60 fps fixos; a gravação roda a 30 fps e não é benchmark.
- Mobile/web, LODs, oclusão e custo dos muitos aglomerados de folhagem.
- A escala final do jogo e a transição para a batalha.
- Uso/publicação das formas do PMD: a reconstrução é autoral, mas a referência continua sendo material de terceiros; licença/atribuição a definir.
- O ícone final do mini-mapa e um NPC branco real.

## Estado

Teste implementado no lab isolado; o corredor de pedra de D-1023 continua intacto como comparação. As mídias estão em `docs/referencias/exploracao/3d/murky_forest_*`. O jogo normal 2D, a batalha, a party, os Moves e a UI não foram tocados; nada publicado.
