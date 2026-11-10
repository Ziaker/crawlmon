# D-1105 — Cards de nome 40% da base e ícones sempre acima do nome

- **Data:** 2026-11-10.
- **Área:** Exploração / placas flutuantes (Flat Card A) / ícones de estado 3D.
- **Relacionadas:** D-1097 (Flat Card A), D-1098 (ícones 3D e alturas), D-1099 (arte sem contorno), D-1095 (medalhão), D-235 (nada depende de personagem/lado).
- **Status:** **implementado/provado**; commit local; **sem push**.

## O que o criador disse (literal)

> ok os blocos com os nomes dos personagens esto enormes, reduza o tamanho em 60% baseado na distancia, quanto mais longe, menor, inclusive tambem deixa os icones acima dos personagens sempre, nunca abaixo, se tiverem nome, acima dos nomes

Respostas de esclarecimento:
- **O que reduzir:** “Base 40% + encolhe no longe” — o Flat Card base fica com 40% do atual e a escala de distância passa a **diminuir** o tamanho na tela.
- **Tamanho no longe:** “Metade do perto” — a ~9 m o card tem **metade do tamanho visível** que tem a ~4 m.
- **Ícones:** “Só os nomes” — os ícones de estado continuam no tamanho atual.

## Regra

1. **Flat Card A — base 40%.** A base do card passa de **3,97 × 1,12 m** para **1,588 × 0,448 m** na escala 1,00 (o texto do nome escala junto). As referências B/C continuam com a base de 3,06 m; só o A muda de base.
2. **Distância — o longe é menor.** O fator de distância deixa de crescer (`dist/8`, que deixava o card quase do mesmo tamanho na tela) e passa a **diminuir** o tamanho visível: `s = clamp(0,50 + (dist − 4,0) × 0,0125, 0,40, 0,70)`. A 4 m `s = 0,50`; a 9 m `s = 0,5625`, então o **tamanho na tela a 9 m é metade do de 4 m**. Vale para NPCs, aliados, inimigo e as referências B/C.
3. **Centro das placas não muda:** NPC/aliado em `altura + 0,65 m`; inimigo em `2,20 m`. Só o tamanho do card muda; o card menor flutua acima do personagem.
4. **Ícones sempre acima.** Os ícones de estado continuam no **tamanho atual** (1,00 m; `0,55 + dist/16`) e ficam **sempre acima do personagem**; se houver nome, **acima do nome**. Na prática, a **base do ícone = topo atual do card + 0,08 m** (o topo considera a escala de distância). Se o NPC estiver falando, o ícone fica acima também do `...` para não cobri-lo.
5. **Inimigo:** o ícone sai de **1,05 m** (abaixo da placa) e passa para **cima da placa**, como no NPC. A altura fixa deixa de existir; o ícone segue o topo do card em todas as distâncias.
6. **Alturas fixas da D-1098 ficam históricas:** NPC `+1,75 m` e inimigo `1,05 m` são substituídos pela posição dinâmica acima do card. A D-1097 (tamanho 3,97 m) também fica histórica para o A.
7. **O que não muda:** a arte sem contorno (D-1099), o **tamanho** do ícone, a arte do Flat Card, o medalhão (D-1095), batalha, 2D, HUD/status, cards, regras, falas e câmera.

## Implementação

- `scripts/debug/floating_nameplate.gd`: `STYLE_PIXEL_SIZE["unit_card"]` para 40% da base; novo `card_top_local()` para o laboratório saber o topo atual do card (com escala, intro e bob).
- `scripts/debug/murky_forest_3d_lab.gd`: novo fator de distância; ícone posicionado acima do `card_top_local()` + 0,08 m; vínculo ícone↔placa e ícone↔`...`; ícone do inimigo acima da placa.
- A ordem de atualização passa a ser placa antes do ícone, para o topo do card já estar no frame.

## Provas

- `docs/referencias/exploracao/3d/murky_forest_lab_cards_40.mp4` — vídeo de 35,8 s: walkthrough real + 5 estados, 9 m, inimigo e espelho.
- `docs/referencias/exploracao/3d/murky_forest_lab_cards_40_preview.gif` — recorte dos 5 estados do inimigo.
- `docs/referencias/exploracao/3d/murky_forest_lab_cards_40_result.gif` — 15 s de resultado: NPC e inimigo em movimento.
- `docs/referencias/exploracao/3d/murky_forest_lab_gameplay_cards_40.mp4` — 10,7 s de gameplay limpo, com o player andando e os NPCs.
- `docs/referencias/exploracao/3d/murky_forest_lab_gameplay_cards_40.gif` — o mesmo gameplay em GIF.
- `JOGAR_LAB_3D.bat` — launcher do lab: WASD/setas andar, Q/E câmera, Z/E falar/saída, 1 aliados, 2 trocar NPCs, F6 estilo do nome, Esc sair.
- `docs/referencias/exploracao/3d/d1105_npc_icon_above.png` — NPC com o card menor e o ícone acima.
- `docs/referencias/exploracao/3d/d1105_enemy_icon_above.png` — inimigo com o ícone acima da placa.

## O que foi verificado

- O Flat Card A ficou com 40% da base; o nome escala junto.
- A 4 m o fator é 0,50; a 9 m 0,5625: o card na tela fica na **metade** do tamanho de 4 m.
- O ícone de estado fica **acima do topo atual do card** (gap de 0,08 m) no NPC e no inimigo; o inimigo saiu de baixo da placa e o `✳` de fúria não encosta mais no Slime.
- O tamanho do ícone não mudou (1,00 m base; `0,55 + dist/16`).
- A cena `scenes/debug/murky_forest_3d_lab.tscn` headless: `exit=0`.
- O vídeo mostra o walkthrough, os 5 estados, o NPC a 9 m, o inimigo e o espelho.

## O que não foi verificado

- Todos os 10 nomes com o card a 40% (o texto escala junto; a D-1097 validou o encaixe no tamanho antigo).
- O `...` de fala no novo empilhamento (o código o mantém abaixo do ícone; não houve prova em vídeo).
- Câmera baixa, o inimigo em patrulha real, o jogo 3D principal (ainda 2D) e mobile/60 fps.

## Estado

Implementado e provado. Commit local; **sem push**.
