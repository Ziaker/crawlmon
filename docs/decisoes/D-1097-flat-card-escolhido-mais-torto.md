# D-1097 — Flat Card escolhido, com o paralelogramo mais torto

- **Data:** 2026-11-10.
- **Área:** Exploração / overworld 3D / UI dos nomes.
- **Relacionadas:** D-1096 (as 3 placas), D-1094 (histórico), D-235 (nada depende de personagem/time/lado).
- **Status:** **implementado/provado**; batalha, 2D, HUD/status, cards, regras, falas, câmera e retratos não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> opção A só que mais torta

## Regra

1. **A opção A (Flat Card) é a escolhida** para as placas de nome do overworld; ela é o padrão do lab.
2. **Flat Card:** bloco **paralelogramo flat creme** (`#eae9d9`) com **só o nome** em Impact escuro (`#111b29`), sem barras, badges, ícones, borda ou papel.
3. **Mais torta:** o paralelogramo passa a ter uma inclinação maior — deslocamento de **90 px** na textura (≈22,6°) — e o card inteiro recebe uma **rotação de -3,5°** em relação à câmera, para ficar visivelmente mais torto que o anterior (28 px / 0°). O nome acompanha a rotação do card.
4. **Tamanho mantido:** 30% maior que a versão anterior; textura 768×216, `pixel_size` 0,003978 → ~3,06×0,86 m.
5. **B e C** (Move Strip e Expedition Tag) continuam no componente como referência/alternativa (`F6`), mas **não são o padrão**.
6. **O que não muda:** batalha, 2D, HUD/status, cards, regras, falas, câmera, alturas das placas e os retratos da D-1095.

## Implementação

- `assets/ui/nameplates/nameplate_unit_card.png`: forma `[(90,0),(768,0),(678,216),(0,216)]`, creme flat, sem detalhes.
- `floating_nameplate.gd`: estilo `unit_card` com `_base_tilt = deg_to_rad(-3.5)`, nome centrado, papel oculto.
- `murky_forest_3d_lab.gd`: `name_style = "unit_card"` como padrão; `F6` continua alternando para B/C.

## Provas

- `docs/referencias/exploracao/3d/name_styles_d1096_comparison.png` — A mais torta ao lado de B/C.
- `docs/referencias/exploracao/3d/name_styles_d1096_lineup.png` — comparação direta.
- `docs/referencias/exploracao/3d/name_styles_d1096_unit_card.png` — A no cenário.
- `docs/referencias/exploracao/3d/name_styles_d1096_cycle.gif` / `.mp4` — ciclo com a A torta.

## O que não foi verificado

- Se o ângulo de -3,5° é exatamente o que o criador queria; é um ajuste visual fácil (aumentar/diminuir).
- Todos os 10 NPCs em todas as distâncias/ângulos, mobile/60 fps e a cena principal completa (VFX de outra sessão).

## Estado

Implementado e provado. Commit local; **sem push**.
