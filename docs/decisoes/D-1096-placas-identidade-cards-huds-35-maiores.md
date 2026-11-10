# D-1096 — Placas de nome na linguagem dos cards/HUDs, flat e 30% maiores

- **Data:** 2026-11-10.
- **Área:** Exploração / overworld 3D / UI dos nomes.
- **Relacionadas:** D-1094 (3 estilos anteriores), D-1072 (UnitCard de exploração), D-1074 (cards com retrato/barras), D-1087/D-1090 (HUD Paper), D-417/D-434 (Move Strips, Impact, paralelogramos), D-235 (nada depende de personagem/time/lado).
- **Status:** **3 protótipos implementados e provados; aguardando a escolha do criador**; batalha, 2D, HUD/status, cards, regras, falas e câmera não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> voltando as placas, eu queria 3 opções se baseando na identidade visual do jogo, nos cartões de combate e huds

> mas eu gostei da opção A

> 3 novas na linguagem do jogo, inclusive deixe estes cartões 35% maiores

> o card é mt pequeno, a opção A usa coisas que não devia, é só pra ser um bloco paralelograma flat com o Nome do personagem não ter todos estes detalhes desnecessários, além dos cards ainda estarem pequenos, aumente seu tamanho em 30%

## Leitura da escolha

O criador pediu **3 novas** placas na linguagem dos cards/HUDs. A **Paper & Pin (A)** fica como referência do que ele gostou, mas não entra no trio final. Na revisão, ele definiu que a **opção A** deve ser **só um bloco paralelogramo flat com o nome** — sem barras, badges, ícones, losangos ou papel — e que **todas as placas** devem ficar **30% maiores** que a versão anterior (que já era 35% maior que a D-1094).

## As 3 opções

### A — Flat Card

- **Bloco paralelogramo flat**, cor creme `#eae9d9`, **só o nome** em Impact/Arial Black escuro `#111b29`.
- **Sem** barras de HP/MP, sem badge de papel, sem losango de elemento, sem ícones, sem borda e **sem o papel NPC/ALLY/ENEMY**.
- Base: o card creme do herói (UnitCard) e os cards flat de elemento do HUD, reduzidos ao essencial.
- Entrada de carta sendo distribuída: escala 0,6 → 1,06 → 1.

### B — Move Strip

- Base: as **Move Strips** da hotbar de batalha/status (D-417/D-434).
- Faixa flat com bloco de elemento à esquerda (losango neutro), nome em Impact, “ACTION” pequeno, **5 pips de ATB** em paralelogramo (como os 5 blocos do ATB do jogo) e chip **MP** azul; corte diagonal na direita.
- Cores do HUD: azul-escuro `#0f1b2a`, ardósia `#334155`, ciano `#38bdf8`, azul `#2563eb`, creme `#eae9d9`, dourado `#dfc980`.
- O papel `NPC/ALLY/ENEMY` aparece no topo esquerdo, abaixo de `ACTION`.
- Entrada em wipe horizontal (escala X 0,02 → 1,05 → 1).

### C — Expedition Tag

- Base: o **status screen / Expedition Satchel** (D-424–D-431): couro marrom `#3c2415`, fundo escuro `#24140a`, borda/linha ocre `#dfc980`, costura, rebites e selo vermelho.
- Nome em serifa (Georgia), creme, como uma etiqueta de expedição; aba de papel para `NPC/ALLY/ENEMY`.
- Formato de etiqueta em paralelogramo, com ilhó de latão e selo de cera.
- Entrada de etiqueta sendo pendurada: escala 0,7 → 1,05 → 1 e leve inclinação.

## Regras de implementação

1. **Uma placa por ator:** NPC, aliado e inimigo usam o mesmo componente; o estilo e o papel (`NPC`/`ALLY`/`ENEMY`) mudam, nunca o personagem, o time ou o lado (D-235). O **Flat Card (A)** não mostra papel; B/C mostram.
2. **A placa sempre olha para a câmera** e mantém a escala por distância (`clampf(dist / 8.0, 0.28, 1.1)`).
3. **Tamanho:** textura 768×216 e `pixel_size` 0,003978 → **3,06×0,86 m**. É **30% maior** que a versão anterior (2,35×0,66 m) e ~**75% maior** que a D-1094 (1,74×0,49 m).
4. **Texto dinâmico:** nome e papel são `Label3D`; no B/C os rótulos fixos (`HP`, `MP`, `UNIT`, `ACTION`, `ATB`, `EXPEDITION`) ficam na textura. No A só existe o nome.
5. **Sem dados falsos:** as barras de HP/MP e os pips de ATB do B/C são decorativos; não mostram números nem alteram o combate. O A não tem barras.
6. **Alturas:** NPC/aliado com a placa em `altura + 0,58 m`; ícone de estado e reticências em `altura + 1,30 m`; inimigo em `1,72 m` (a placa maior não encosta no ícone).
7. **O que não muda:** batalha, 2D, HUD/status, cards, regras, falas, câmera, faixas, anéis e a D-1094 (fica como histórico).

## Arquivos

- `assets/ui/nameplates/nameplate_unit_card.png` — bloco flat creme (A).
- `assets/ui/nameplates/nameplate_move_strip.png` — Move Strip (B).
- `assets/ui/nameplates/nameplate_expedition.png` — Expedition Tag (C).
- `scripts/debug/floating_nameplate.gd`
- `scripts/debug/murky_forest_3d_lab.gd` (estilo padrão, F6 e alturas)

## Provas

- `docs/referencias/exploracao/3d/name_styles_d1096_unit_card.png`
- `docs/referencias/exploracao/3d/name_styles_d1096_move_strip.png`
- `docs/referencias/exploracao/3d/name_styles_d1096_expedition.png`
- `docs/referencias/exploracao/3d/name_styles_d1096_comparison.png`
- `docs/referencias/exploracao/3d/name_styles_d1096_lineup.png`
- `docs/referencias/exploracao/3d/name_styles_d1096_roles.png` — papéis NPC/ALLY/ENEMY no **Move Strip** (o Flat Card é só nome).
- `docs/referencias/exploracao/3d/name_styles_d1096_cycle.mp4` / `.gif`

## O que foi verificado

- As 3 placas no mesmo Bulbasaur, mesma câmera e mesma pose, **30% maiores** que a versão anterior.
- O **Flat Card** com apenas o nome, sem barras/badges/ícones/papel.
- A mesma placa em NPC, aliado e inimigo no **Move Strip** (`name_styles_d1096_roles.png`): BULBASAUR/NPC, PANCHAM/ALLY, SLIME/ENEMY.
- Troca de estilo em tempo real pelo `F6`: as 6 placas trocam para `move_strip`, `expedition` e voltam para `unit_card` (`all=true`).
- Cena `scenes/debug/murky_forest_3d_lab.tscn` headless: `exit=0`, sem erro de parse/case (só vazamentos de saída do headless).

## O que não foi verificado

- A escolha final A/B/C.
- Todos os 10 NPCs, aliados, inimigo e lados em todas as distâncias/ângulos.
- 60 fps/mobile/outras resoluções e a cena principal completa (VFX de outra sessão).
- Os textos fixos das texturas em outras resoluções; a placa é 3D e escala, mas os detalhes finos podem ficar pequenos no mobile.

## Relação com a D-1094

A D-1094 tinha **Paper & Pin / SMT Holo / Comic Impact**. O criador gostou da Paper & Pin, mas nesta rodada pediu **3 novas** na linguagem dos cards/HUDs, depois simplificou o A para um bloco flat com só o nome e pediu **+30%** de tamanho. Os três estilos da D-1094 continuam no histórico/referência; o trio ativo agora é Flat Card / Move Strip / Expedition Tag.

## Estado

Implementado e provado. Commit local; **sem push**.
