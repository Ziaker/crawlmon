# D-1074 — Cards do overworld: retratos Sugimori, barras/textos maiores e ícones de elemento

- **Data:** 2026-11-09.
- **Área:** Exploração / HUD / cards do overworld (`ExplorationBattleHud`).
- **Relacionadas:** D-1072 (casca dos cards), D-1063 (NPCs), D-1023/D-1022 (overworld 3D).
- **Status:** **teste implementado e corrigido** com zoom no rosto (Abra 3, Pancham 2, Gible 2); Gible entrou como 4º card demo; batalha, status, menus, DQT e jogo 2D não mudam; commit local; **sem push**.
- **Nota D-1075/D-1076 (2026-11-09):** os cards agora aparecem após 5 s parado ou Tab (D-1075); a tentativa de shader toon customizado (D-1076) foi **revertida** e o visual voltou ao estado anterior (`DIFFUSE_TOON` no `gl_compatibility`, que não aplica). O layout/arte dos cards não muda.

## O que o criador disse (literal)

> uma mudanca grande nos icones dos pokemons, eu quero que eles nao sejam mais estes icones de poucos pixels mas sim screenshots das sugimori artes deles que temos na pasta do jogo

> alem disso os blocos dentro dos cartoes no overworld estao mt pequenos, o texto tambem, faca questao de ocuparem corretamente o espaco, coloque tambem seus icones de elementos ao lado do nome

> nao assim, eu nao pedi assim, e pra dar zoom perto da face deles QUE NEM VC FEZ COM OS DQT, corrija isso

> perfeito, agora so falta corrigir os textos vazados e deixar o angulo deles coeso com cartao paralelogramatico

Respostas às perguntas de esclarecimento:

- **Onde trocar?** Só os cards do overworld; batalha, status e menus ficam como estão.
- **Tamanho do card?** “usa o mesmo metodo que usa para as artes de DQT, nao e pra aumentar” — manter 330×104 e usar o método das artes DQT de alta resolução (a arte preenche o retrato inclinado e é cortada).
- **Orc?** “isso so afeta os pokemons, nao tem nada haver com os DQT” — o Orc/DQT continua com o retrato atual.

## Decisão

1. **Escopo:** apenas `scripts/debug/exploration_battle_hud.gd` (cards do overworld). `BattleHud`, `UnitCard`, `EnemyTag`, status screen, menus, NPCs DQT e o jogo 2D **não mudam**.
2. **Retratos dos Pokémon com zoom no rosto:** usar as artes Sugimori locais de `res://sugimori/por_nome/<id>.png`, mas **recortadas perto da face**, como os retratos DQT, e não a arte inteira centralizada. O card recebe uma região UV por Pokémon e o `_slant_texture` preenche o quadro inclinado de 56×62 com essa região (aspecto preservado e corte central).
   - **Abra:** opção 3 — crop (300, 120)–(620, 480) na arte 851×851.
   - **Pancham:** opção 2 — crop (300, 40)–(980, 800) na arte 1261×1261.
   - **Gible:** opção 2 — crop (30, 100)–(520, 660) na arte 762×762.
   - As 3 opções de cada um foram geradas em `scratch/sugimori_face_options/`; o criador escolheu Abra 3, Pancham 2 e Gible 2.
3. **DQT/Orc:** continua usando `res://personagens/portraits/orc.png` (256×256) **inteiro**, sem zoom; nenhuma arte DQT é trocada por Sugimori.
4. **Card fixo:** **330×104**, sem aumentar. O herói continua 1,0× e os aliados 0,85×. O Gible entra como **4º card demo** em (14, 394), 0,85×, com HP 100/100 e MP 10/20 (demo).
5. **Barras e textos maiores:** preencher o espaço útil do card:
   - nome em **20 px** (era 18);
   - HP: barra **142×18** (era 120×7), texto **12 px** (era 10);
   - MP: barra **142×14** (era 120×5), texto **11 px** (era 9);
   - valores de HP/MP **alinhados à direita em x=310**, formando uma borda direita inclinada paralela ao lado do card;
   - **textos com o mesmo shear do corpo**: nome, ícones de elemento, `ALLY | AI` e números de HP/MP são desenhados sob `_body_shear()` (8 px em 82 px, pivô em y=18);
   - **barras em paralelogramo**: desenhadas com `_slant` e o mesmo ângulo do card; a borda direita do bloco de texto e as barras ficam paralelas às laterais. Nada vaza da borda inclinada.
6. **Ícones de elemento ao lado do nome:** até **2** ícones de 18×18 imediatamente após o nome, na mesma linha. Fonte: `res://assets/ui/icons/elements/*.svg`, com o mesmo mapa do battle (`FÍSICO→neutral`, `FOGO→fire`, `ÁGUA/GELO→water_ice`, `RAIO→electric`, `PSÍQUICO→psychic`, `VENENO→nature`, `SOM→sound`, `TERRA→earth`, `VENTO→wind`, `LUZ→light`, `TREVAS→dark`, `MYSTIC→mystic`). Cores de contraste: escuras no card creme do herói, claras no card azul dos aliados.
7. **Elementos dos cards atuais:** ABRA = Psíquico; PANCHAM = Físico + Trevas; ORC = Físico (DQT, retrato atual); GIBLE = Terra.
8. **O que não muda:** mini-mapa/bolinhas flat, Slime 0,49 m, NPCs sólidos D-1063, alerta “!”, câmera, batalha 3D, jogo 2D e regras.

## Teste implementado (2026-11-09)

- **Sugimori com zoom no rosto:** Abra (crop 300,120–620,480), Pancham (300,40–980,800) e Gible (30,100–520,660) carregam no projeto principal; o card usa a região UV escolhida no mesmo `_slant_texture(pr.grow(-2.0), 5.0, ...)` das artes DQT.
- **Orc/DQT:** `personagens/portraits/orc.png` (256×256) continua inteiro; nenhuma arte DQT foi trocada.
- **Cards:** 330×104, herói 1,0×, aliados 0,85×. Nome 20 px; HP 142×18 com texto 12; MP 142×14 com texto 11; valores alinhados à direita em x=310. Agora são **4 cards no party**: Abra, Pancham, Orc e Gible (Gible demo 100/100 + 10/20).
- **Ângulo dos textos e blocos:** nome, ícones de elemento, `ALLY | AI` e HP/MP são desenhados com o mesmo shear do corpo (`8/82`, pivô y=18); os valores à direita formam uma borda inclinada paralela ao card. As barras de HP/MP são **paralelogramos** com o mesmo ângulo; nada cruza a borda (HP 100/100 fica com ~20 px de margem).
- **Elementos:** Abra = Psíquico; Pancham = Físico + Trevas; Orc = Físico; Gible = Terra. Ícones 18×18 ao lado do nome, com o mesmo mapa do `BattleHud` (`FÍSICO→neutral`, `PSÍQUICO→psychic`, `TREVAS→dark`, `TERRA→earth`) e cores de contraste (escuras no creme, claras no azul).
- **Prova:** captura isolada em `docs/referencias/exploracao/3d/murky_forest_hud_sugimori.png` e recorte dos quatro cards em `murky_forest_hud_sugimori_cards.png`; mostra Abra/Pancham/Gible com Sugimori em close, Orc com o retrato DQT, quatro cards no party (visíveis após 5 s parado ou Tab, D-1075), bolinhas flat e NPCs; os textos estão dentro da borda inclinada e com o mesmo shear do card.
- **Verificação:** `--check-only` do HUD e carregamento dos assets no projeto principal; a captura foi feita no projeto isolado porque a janela do projeto principal ainda esbarra nos erros de parse de VFX de outra sessão. A cena principal em headless também está bloqueada no momento por erros de `tidal_surge_vfx.gd` de outra sessão; o HUD isolado e a auditoria D-1063 rodam sem erro.

## Ambiguidades

- **Tamanho exato** das barras/textos: valores acima são a implementação; o card não cresce, conforme a resposta.
- **Sugimori local:** a pasta `sugimori/` é ignorada pelo Git; se a arte faltar, o card cai no retrato antigo de `personagens/portraits`.
- **Orc:** sem Sugimori; mantém o retrato DQT atual, inteiro.
- **Gible:** entrou como 4º card **demo** (100/100 + 10/20); a party real ainda não foi ligada.
- **Ordem dos ícones:** segue a ordem dos elementos inatos (`get_elements()`); se o criador quiser só um ícone ou outra ordem, é uma decisão nova.
- **Crop de rosto:** os retângulos foram escolhidos entre 3 opções por Pokémon; outro enquadramento é uma decisão nova.

## O que não foi verificado

- **Janela do projeto principal:** a captura foi no isolado; o projeto principal carrega os assets, mas a janela e a cena headless ainda são bloqueadas pelos erros de VFX de outra sessão (`tidal_surge_vfx.gd`).
- **Sugimori local:** a pasta `sugimori/` é ignorada pelo Git; se a arte faltar, o card cai no retrato antigo.
- **Crop de rosto:** os retângulos são manuais; o Abra 3, Pancham 2 e Gible 2 foram escolhidos, mas não há detecção automática de rosto.
- **Glifos:** o shear dos textos é o mesmo do card (8/82), então o ângulo dos glifos é leve; a borda direita do bloco e as barras são claramente paralelas. Se o criador quiser glifos mais inclinados, é uma decisão nova.
- **Orc:** sem Sugimori; mantém o retrato DQT.
- **Gible na party real:** o card é demo; não foi ligado a `GameState.party`.
- **60 fps, mobile/web, outras resoluções** e batalha/status/menus (não tocados).

## Estado

Teste implementado e corrigido no lab isolado; Abra/Pancham/Gible em close no rosto, valores alinhados à direita com borda inclinada, barras em paralelogramo e Gible como 4º card demo; prova em `murky_forest_hud_sugimori*`. Documentação registrada; commit local; **sem push**. Nada de combate/2D/DQT muda.
