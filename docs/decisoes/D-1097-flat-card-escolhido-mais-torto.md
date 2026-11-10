# D-1097 — Flat Card escolhido, mais torto e 30% maior

- **Data:** 2026-11-10.
- **Área:** Exploração / overworld 3D / UI dos nomes.
- **Relacionadas:** D-1096 (as 3 placas), D-1094 (histórico), D-235 (nada depende de personagem/time/lado).
- **Status:** **implementado/provado**; batalha, 2D, HUD/status, cards, regras, falas, câmera e retratos não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> opção A só que mais torta

> melhor mas deixe o nome maior e o cartão 30% maior, vc não tá fazendo oq eu to pedindo de deixar o cartão maior? ja é a terceira vez q mando

## Regra

1. **A opção A (Flat Card) é a escolhida** para as placas de nome do overworld; ela é o padrão do lab.
2. **Flat Card:** bloco **paralelogramo flat creme** (`#eae9d9`) com **só o nome** em Impact escuro (`#111b29`), sem barras, badges, ícones, borda ou papel.
3. **Mais torta:** o paralelogramo tem deslocamento de **90 px** na textura (≈22,6°) e o card inteiro recebe uma **rotação de -3,5°** em relação à câmera. O nome acompanha a rotação do card.
4. **A é 30% maior que a versão anterior:** passou de **3,06×0,86 m** para **3,97×1,12 m** (`pixel_size` 0,0051714, textura 768×216). B e C continuam em 3,06×0,86 m como referência.
5. **Nome maior:** o nome do A passou de **100 para 120 px** na textura; com o card maior, o nome cresceu de ~0,40 m para ~0,62 m de altura.
6. **B e C** (Move Strip e Expedition Tag) continuam no componente como referência/alternativa (`F6`), mas **não são o padrão**.
7. **O que não muda:** batalha, 2D, HUD/status, cards, regras, falas, câmera, alturas das outras placas e os retratos da D-1095.

## Implementação

- `assets/ui/nameplates/nameplate_unit_card.png`: forma `[(90,0),(768,0),(678,216),(0,216)]`, creme flat, sem detalhes.
- `floating_nameplate.gd`: `STYLE_PIXEL_SIZE` com A = 0,0051714 e B/C = 0,003978; nome A = 120, centrado; papel oculto; `_base_tilt = deg_to_rad(-3.5)`.
- `murky_forest_3d_lab.gd`: `name_style = "unit_card"` como padrão; `F6` continua alternando para B/C; alturas da placa A ajustadas (`+0,75 m`, ícone/reticências `+1,55 m`, inimigo `1,88 m`).

## Provas

- `docs/referencias/exploracao/3d/flat_card_size_30.png` — **antes/depois com régua:** 3,06 m → 3,97 m (+30%) e nome 100 → 120, mesma câmera.
- `docs/referencias/exploracao/3d/name_styles_d1096_unit_card.png` — A no cenário.
- `docs/referencias/exploracao/3d/name_styles_d1096_comparison.png` — A maior ao lado de B/C.
- `docs/referencias/exploracao/3d/name_styles_d1096_lineup.png` — comparação direta.
- `docs/referencias/exploracao/3d/name_styles_d1096_cycle.gif` / `.mp4` — ciclo com a A maior.

## O que não foi verificado

- Se o ângulo de -3,5° e o tamanho de 3,97 m são exatamente o que o criador queria; são ajustes visuais fáceis (aumentar/diminuir).
- Todos os 10 NPCs em todas as distâncias/ângulos, mobile/60 fps e a cena principal completa (VFX de outra sessão).

## Estado

Implementado e provado. Commit local; **sem push**.
