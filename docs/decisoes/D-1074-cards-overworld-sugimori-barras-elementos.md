# D-1074 — Cards do overworld: retratos Sugimori, barras/textos maiores e ícones de elemento

- **Data:** 2026-11-09.
- **Área:** Exploração / HUD / cards do overworld (`ExplorationBattleHud`).
- **Relacionadas:** D-1072 (casca dos cards), D-1063 (NPCs), D-1023/D-1022 (overworld 3D).
- **Status:** **teste implementado e verificado** no lab isolado; batalha, status, menus, DQT e jogo 2D não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> uma mudanca grande nos icones dos pokemons, eu quero que eles nao sejam mais estes icones de poucos pixels mas sim screenshots das sugimori artes deles que temos na pasta do jogo

> alem disso os blocos dentro dos cartoes no overworld estao mt pequenos, o texto tambem, faca questao de ocuparem corretamente o espaco, coloque tambem seus icones de elementos ao lado do nome

Respostas às perguntas de esclarecimento:

- **Onde trocar?** Só os cards do overworld; batalha, status e menus ficam como estão.
- **Tamanho do card?** “usa o mesmo metodo que usa para as artes de DQT, nao e pra aumentar” — manter 330×104 e usar o método das artes DQT de alta resolução (a arte preenche o retrato inclinado e é cortada).
- **Orc?** “isso so afeta os pokemons, nao tem nada haver com os DQT” — o Orc/DQT continua com o retrato atual.

## Decisão

1. **Escopo:** apenas `scripts/debug/exploration_battle_hud.gd` (cards do overworld). `BattleHud`, `UnitCard`, `EnemyTag`, status screen, menus, NPCs DQT e o jogo 2D **não mudam**.
2. **Retratos dos Pokémon:** usar as artes Sugimori locais de `res://sugimori/por_nome/<id>.png` (Abra e Pancham; a pasta é ignorada pelo Git, mas existe na pasta do jogo). O desenho usa o **mesmo método das artes DQT**: a textura grande preenche o retângulo inclinado de 56×62 (`_slant_texture(pr.grow(-2.0), 5.0, ...)`), com aspecto preservado e corte central.
3. **DQT/Orc:** continua usando `res://personagens/portraits/orc.png` (256×256). Nenhuma arte DQT é trocada por Sugimori.
4. **Card fixo:** **330×104**, sem aumentar. O herói continua 1,0× e os aliados 0,85×.
5. **Barras e textos maiores:** preencher o espaço útil do card:
   - nome em **20 px** (era 18);
   - HP: barra **166×12** (era 120×7), texto **12 px** (era 10);
   - MP: barra **166×10** (era 120×5), texto **11 px** (era 9);
   - textos de HP/MP à direita das barras, alinhados verticalmente com elas.
6. **Ícones de elemento ao lado do nome:** até **2** ícones de 18×18 imediatamente após o nome, na mesma linha. Fonte: `res://assets/ui/icons/elements/*.svg`, com o mesmo mapa do battle (`FÍSICO→neutral`, `FOGO→fire`, `ÁGUA/GELO→water_ice`, `RAIO→electric`, `PSÍQUICO→psychic`, `VENENO→nature`, `SOM→sound`, `TERRA→earth`, `VENTO→wind`, `LUZ→light`, `TREVAS→dark`, `MYSTIC→mystic`). Cores de contraste: escuras no card creme do herói, claras no card azul dos aliados.
7. **Elementos dos cards atuais:** ABRA = Psíquico; PANCHAM = Físico + Trevas; ORC = Físico (DQT, retrato atual).
8. **O que não muda:** mini-mapa/bolinhas flat, Slime 0,49 m, NPCs sólidos D-1063, alerta “!”, câmera, batalha 3D, jogo 2D e regras.

## Teste implementado (2026-11-09)

- **Sugimori:** `res://sugimori/por_nome/abra.png` (851×851) e `pancham.png` (1261×1261) carregam no projeto principal; o retrato usa o mesmo `_slant_texture(pr.grow(-2.0), 5.0, ...)` das artes DQT (preenche o quadro inclinado, mantém aspecto e corta o centro).
- **Orc/DQT:** `personagens/portraits/orc.png` (256×256) continua; nenhuma arte DQT foi trocada.
- **Card:** 330×104, herói 1,0×, aliados 0,85×. Nome 20 px; HP 166×12 com texto 12; MP 166×10 com texto 11; barras e textos ocupando a largura útil.
- **Elementos:** Abra = Psíquico; Pancham = Físico + Trevas; Orc = Físico. Ícones 18×18 ao lado do nome, com o mesmo mapa do `BattleHud` (`FÍSICO→neutral`, `PSÍQUICO→psychic`, `TREVAS→dark`) e cores de contraste (escuras no creme, claras no azul).
- **Prova:** captura isolada em `docs/referencias/exploracao/3d/murky_forest_hud_sugimori.png` e recorte dos três cards em `murky_forest_hud_sugimori_cards.png`; mostra Abra/Pancham com Sugimori, Orc com o retrato DQT, três cards no party, bolinhas flat e NPCs.
- **Verificação:** `--check-only` do HUD e carregamento dos assets no projeto principal; a captura foi feita no projeto isolado porque a janela do projeto principal ainda esbarra nos erros de parse de VFX de outra sessão. A cena principal em headless continua rodando.

## Ambiguidades

- **Tamanho exato** das barras/textos: valores acima são a implementação; o card não cresce, conforme a resposta.
- **Sugimori local:** a pasta `sugimori/` é ignorada pelo Git; se a arte faltar, o card cai no retrato antigo de `personagens/portraits`.
- **Orc:** sem Sugimori; mantém o retrato DQT atual.
- **Ordem dos ícones:** segue a ordem dos elementos inatos (`get_elements()`); se o criador quiser só um ícone ou outra ordem, é uma decisão nova.

## O que não foi verificado

- **Janela do projeto principal:** a captura foi no isolado; o projeto principal carrega os assets, mas a janela ainda é bloqueada pelos erros de VFX de outra sessão.
- **Sugimori local:** a pasta `sugimori/` é ignorada pelo Git; se a arte faltar, o card cai no retrato antigo.
- **Corte da arte:** o método DQT corta o centro do quadro 56×62; extremidades das mãos/patas podem ficar fora, como nas artes DQT.
- **Orc:** sem Sugimori; mantém o retrato DQT.
- **60 fps, mobile/web, outras resoluções** e batalha/status/menus (não tocados).

## Estado

Teste implementado e verificado no lab isolado; prova em `murky_forest_hud_sugimori*`. Documentação registrada; commit local; **sem push**. Nada de combate/2D/DQT muda.
