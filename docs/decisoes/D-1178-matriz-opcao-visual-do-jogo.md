# D-1178 — Matriz de afinidades: opção de visual do jogo (cards flat em ângulos diferentes)

- **Data:** 2026-11-11
- **Área:** Protótipo / ferramenta de cadastro de personagem (`prototypes/affinity_matrix.html`).
- **Relacionadas:** D-416 (paralelogramos flat, sem bordas), D-421 (Combat Gauges creme / Attributes navy), D-424 (mochila marrom e dourado), D-434 (Battle Strips), D-1072 (cards de batalha), D-1097 (Flat Card torto), D-1177 (QoL da matriz).
- **Estado:** implementado no protótipo como opção; aguardando aprovação visual. Nenhum arquivo do jogo alterado.

## Declaração literal do criador

> "veja como sao feitos os visuais e a estetica visual do jogo, e replique em uma opcao da matrix, seja bem visualmente semelhante, com angulos diferentes e cards flat"

## Decisão

1. A matriz ganha um seletor **Visual: Editor / Jogo** (tecla `V`, também na paleta). O visual atual continua existindo como **Editor**; a escolha fica salva no navegador.
2. **Jogo** replica a Status Screen (`scripts/ui/status_screen.gd`, referência `docs/referencias/exploracao/3d/d1165_status_hud_abra_megido.png`):
   - **Flat:** sem bordas, sem degradê e sem cantos chanfrados; sombra dura deslocada.
   - **Ângulos diferentes:** cada card tem uma rotação pequena própria e volta a ficar reto com o mouse em cima; faixas, badges, botões e células são paralelogramos `/ /`.
   - **Paleta do jogo:** `LIME d6fa66`, `CORAL ff746c`, `PAPER f4eee1`, `INK 10263a`, `BLUE 63d9ec`, `GOLD f0c57e`, navy `0a1a27`/`0e2435`, couro `3c2415` + dourado `dfc980`.
   - **Fontes do jogo:** Impact nos títulos e Arial peso 800 no corpo (`FanMenu.title_font()` / `body_font()`).
   - **Cores e glifos de elemento do jogo** (`ELEMENT_COLORS` / `ELEMENT_GLYPH_COLORS`), com o glifo dentro de um badge paralelogramo da cor do elemento.
3. Onde cada peça do jogo foi usada:
   - cabeçalho de elemento = ficha de Move (fundo do elemento + glifo em marca d'água);
   - cards "Por personagem" e seletor da ficha = card creme do roster;
   - `ATTRIBUTES` = card creme dos Combat Gauges, com segmentos no formato dos pips de ATB;
   - `MATCHUPS` = couro e dourado da Expedition Satchel;
   - lista de moves = Battle Strips;
   - arte da ficha = paralelogramo inclinado da cor do primeiro elemento atrás do personagem;
   - título = `TEAM /STATS` (barra coral + palavra lima).

## Escolhas do assistente (não ditas pelo criador)

- Ser uma **opção alternável** em vez de substituir o visual atual ("em uma opcao da matrix").
- Os valores de cada rotação (entre 0,3° e 2°) e qual card recebe creme, navy ou couro.
- A tabela da visão Matriz **não é girada** (cabeçalho fixo e pintura por arrasto dependem disso); só as células viram paralelogramos.
- O fundo usa um degradê azul-petróleo com colunas em silhueta feitas em CSS, sem a arte de cenário do jogo.

## O que não muda

- Dados, regras, atalhos e o JSON `crawlmon.affinities.v1`. As cores de elemento não vão para o JSON.
- Nada de commit/push (D-022).
