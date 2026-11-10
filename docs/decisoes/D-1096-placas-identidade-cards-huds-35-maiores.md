# D-1096 — Placas de nome na linguagem dos cards/HUDs do jogo, 35% maiores

- **Data:** 2026-11-10.
- **Área:** Exploração / overworld 3D / UI dos nomes.
- **Relacionadas:** D-1094 (3 estilos anteriores), D-1072 (UnitCard de exploração), D-1074 (cards com retrato/barras), D-1087/D-1090 (HUD Paper), D-417/D-434 (Move Strips, Impact, paralelogramos), D-235 (nada depende de personagem/time/lado).
- **Status:** **3 protótipos implementados e provados; aguardando a escolha do criador**; batalha, 2D, HUD/status, cards, regras, falas e câmera não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> voltando as placas, eu queria 3 opções se baseando na identidade visual do jogo, nos cartões de combate e huds

> mas eu gostei da opção A

> 3 novas na linguagem do jogo, inclusive deixe estes cartões 35% maiores

## Leitura da escolha

O criador pediu **3 novas** placas — a Paper & Pin (A) fica como referência do que ele gostou, mas não entra no trio final. As novas placas usam a linguagem real dos cards/HUDs do jogo, não estilos genéricos. As placas ficaram **35% maiores** que as da D-1094: textura 768×216 e `pixel_size` 0,00306 → ~2,35×0,66 m (antes 512×144 e 1,74×0,49 m).

## As 3 opções

### A — Unit Card

- Base: o **UnitCard** dos cards de batalha/exploração (D-1072/D-1074).
- Card escuro `#17283b` com borda creme `#eae9d9`, corte no canto superior direito, faixa creme à esquerda e badge de papel no topo direito.
- Nome em Impact/Arial Black (a fonte de título do HUD), creme; barras **HP** (`#e96159`) e **MP** (`#38bdf8`) em paralelogramo na base, com trilhos escuros e rótulos pequenos.
- Losango dourado de elemento no canto; as barras são decorativas (não inventam HP/MP de NPC).
- Entrada de carta sendo distribuída: escala 0,6 → 1,06 → 1.

### B — Move Strip

- Base: as **Move Strips** da hotbar de batalha/status (D-417/D-434).
- Faixa flat com bloco de elemento à esquerda (losango neutro), nome em Impact, “ACTION” pequeno, **5 pips de ATB** em paralelogramo (como os 5 blocos do ATB do jogo) e chip **MP** azul; corte diagonal na direita.
- Cores do HUD: azul-escuro `#0f1b2a`, ardósia `#334155`, ciano `#38bdf8`, azul `#2563eb`, creme `#eae9d9`, dourado `#dfc980`.
- Entrada em wipe horizontal (escala X 0,02 → 1,05 → 1).

### C — Expedition Tag

- Base: o **status screen / Expedition Satchel** (D-424–D-431): couro marrom `#3c2415`, fundo escuro `#24140a`, borda/linha ocre `#dfc980`, costura, rebites e selo vermelho.
- Nome em serifa (Georgia), creme, como uma etiqueta de expedição; aba de papel para `NPC/ALLY/ENEMY`.
- Formato de etiqueta em paralelogramo, com ilhó de latão e selo de cera.
- Entrada de etiqueta sendo pendurada: escala 0,7 → 1,05 → 1 e leve inclinação.

## Regras de implementação

1. **Uma placa por ator:** NPC, aliado e inimigo usam o mesmo componente; o estilo e o papel (`NPC`/`ALLY`/`ENEMY`) mudam, nunca o personagem, o time ou o lado (D-235).
2. **A placa sempre olha para a câmera** e mantém a escala por distância (`clampf(dist / 8.0, 0.28, 1.1)`).
3. **35% maiores:** textura 768×216 e `pixel_size` 0,00306, resultando em ~2,35×0,66 m.
4. **Texto dinâmico:** nome e papel são `Label3D`; os rótulos fixos (`HP`, `MP`, `UNIT`, `ACTION`, `ATB`, `EXPEDITION`) ficam na textura.
5. **Sem dados falsos:** as barras de HP/MP e os pips de ATB são decorativos; não mostram números nem alteram o combate.
6. **Alturas:** NPC/aliado com a placa em `altura + 0,58 m`; ícone de estado e reticências em `altura + 1,15 m`; inimigo em `1,58 m` (subiu para a placa maior não encostar no ícone de estado).
7. **O que não muda:** batalha, 2D, HUD/status, cards, regras, falas, câmera, faixas, anéis e a D-1094 (fica como histórico).

## Arquivos

- `assets/ui/nameplates/nameplate_unit_card.png`
- `assets/ui/nameplates/nameplate_move_strip.png`
- `assets/ui/nameplates/nameplate_expedition.png`
- `scripts/debug/floating_nameplate.gd`
- `scripts/debug/murky_forest_3d_lab.gd` (estilo padrão, F6 e alturas)

## Provas

- `docs/referencias/exploracao/3d/name_styles_d1096_unit_card.png`
- `docs/referencias/exploracao/3d/name_styles_d1096_move_strip.png`
- `docs/referencias/exploracao/3d/name_styles_d1096_expedition.png`
- `docs/referencias/exploracao/3d/name_styles_d1096_comparison.png`
- `docs/referencias/exploracao/3d/name_styles_d1096_lineup.png`
- `docs/referencias/exploracao/3d/name_styles_d1096_roles.png`
- `docs/referencias/exploracao/3d/name_styles_d1096_cycle.mp4` / `.gif`

## O que foi verificado

- As 3 placas no mesmo Bulbasaur, mesma câmera e mesma pose, 35% maiores que a D-1094.
- A mesma placa em NPC, aliado e inimigo (`name_styles_d1096_roles.png`): BULBASAUR/NPC, PANCHAM/ALLY, SLIME/ENEMY, todos com o Unit Card.
- Troca de estilo em tempo real pelo `F6`: as 6 placas trocam para `move_strip`, `expedition` e voltam para `unit_card` (`all=true`).
- Cena `scenes/debug/murky_forest_3d_lab.tscn` headless: `exit=0`, sem erro de parse/case (só vazamentos de saída do headless).

## O que não foi verificado

- A escolha final A/B/C.
- Todos os 10 NPCs, aliados, inimigo e lados em todas as distâncias/ângulos.
- 60 fps/mobile/outras resoluções e a cena principal completa (VFX de outra sessão).
- Os textos fixos das texturas em outras resoluções; a placa é 3D e escala, mas os detalhes finos podem ficar pequenos no mobile.

## Relação com a D-1094

A D-1094 tinha **Paper & Pin / SMT Holo / Comic Impact**. O criador gostou da Paper & Pin, mas nesta rodada pediu **3 novas** na linguagem dos cards/HUDs e 35% maiores. Os três estilos da D-1094 continuam no histórico/referência; o trio ativo agora é Unit Card / Move Strip / Expedition Tag.

## Estado

Implementado e provado. Commit local; **sem push**.
