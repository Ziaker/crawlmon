# D-1095 — Ícone do Bulbasaur no recorte anexado, aro interno de volta, fundo marrom escuro e nome centralizado

- **Data:** 2026-11-10.
- **Área:** Exploração / diálogo / retratos / HUD Paper.
- **Relacionadas:** D-1093 (ícone estabelecido), D-1090 (HUD C/Paper), D-1092 (faixas dos aliados), D-1074 (face crop).
- **Status:** **implementado e provado**; batalha, 2D, HUD/status, cards, regras, falas, câmera e placas flutuantes não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> troque o icone do bulbasaur por este que já está no alinhamento que eu queria. Além disso, remova essa borda interior marrom mas mantenha o fundo marrom

> corrija tambem o alinhamento central do nome do personagem, está mais pra cima do que centralizado

> o ícone novo do bulbsaur está otimo mas vc não tirou a borda interior que eu pedi pra tirar, tirou a borda preta que estava boa já

> ok volta com essa borda interior mas muda o fundo dos icones pra um marrom mais escuro

## Regra

1. **Bulbasaur usa o recorte fechado do anexo**, com a face centralizada, a bochecha direita cortada na borda e a boca perto da base. O recorte é feito da arte local (`sugimori/por_nome/bulbasaur.png`), com padding transparente à esquerda para a face ficar na posição do anexo.
2. **O medalhão tem duas bordas:** a **borda preta externa** (2 px, `Color(0.16, 0.25, 0.16)`) e o **aro dourado interno** (o fundo `Color(0.85, 0.68, 0.30)` aparecendo entre a borda e o retrato, com o retrato recuado 8 px no card / 4 px na faixa). As duas ficam.
3. **O fundo do ícone** (atrás do rosto, dentro do retrato) passa a ser um **marrom mais escuro:** `#5C3C1E` (`Color(92/255, 60/255, 30/255)`). É esse marrom que preenche o círculo do retrato; o aro dourado do medalhão continua mais claro.
4. **O nome do personagem no name tab do Paper fica centralizado verticalmente.**
5. **Os demais personagens** continuam com o face crop atual até receberem um ícone próprio; o fundo marrom escuro e o acabamento do medalhão valem para os retratos de face crop.
6. **O que não muda:** batalha, 2D, HUD/status, cards, regras, falas, câmera, anéis e as placas de nome flutuantes (D-1094).

## Implementação

- **Novo asset:** `assets/ui/portraits/bulbasaur.png` (512×512, pré-mascarado em círculo, fundo `#5C3C1E`). O recorte é quadrado (536 px) com 45 px de padding à esquerda, a partir da janela `(0, 47, 491, 583)` da arte local.
- **`_portrait_for_speaker()`** usa esse ícone para o Bulbasaur e mantém o recorte dinâmico (`_circular_portrait`) para os demais personagens.
- **`_circular_portrait()`** compõe o rosto sobre o marrom escuro `#5C3C1E` e mantém o RGB marrom fora do círculo, para a borda da máscara não puxar uma franja escura.
- **`dialogue_hud_styles.gd` (Paper):** `_portrait_back` 142 px com `bg_color = Color(0.85, 0.68, 0.30)` (aro dourado) e `border = Color(0.16, 0.25, 0.16)`, 2 px (borda preta); `_portrait_rect` em `(8, 8)` com 126 px. O aro dourado interno volta, e o fundo do retrato é o marrom escuro.
- **`ally_banner.gd`:** mesmo esquema na faixa: `_portrait_back` 56 px, aro dourado + borda preta, `_portrait_rect` em `(4, 4)` com 48 px.
- **Nome:** `_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER` no name tab Paper.
- O recorte é gerado por `scratch/make_bulbasaur_portrait.py` (script de apoio, não entra no jogo).

## Provas

- `docs/referencias/exploracao/3d/bulbasaur_icon_before_after.png` — antes/depois: recorte novo, aro dourado interno de volta, fundo marrom escuro, borda preta mantida e nome centralizado.
- `docs/referencias/exploracao/3d/murky_forest_paper_dialogue.png` — card Paper completo.
- `docs/referencias/exploracao/3d/murky_forest_panchan_reaction.png` — faixa do Pancham com o mesmo acabamento.
- `docs/referencias/exploracao/3d/murky_forest_orc_reaction.png` — faixa do Orc com o mesmo acabamento.

## O que foi verificado

- O card Paper do Bulbasaur com o recorte fechado, o **aro dourado interno**, o **fundo marrom escuro**, a **borda preta** e o **nome centralizado**.
- A faixa do Pancham/Orc com o mesmo medalhão.
- Cena `scenes/debug/murky_forest_3d_lab.tscn` headless: `exit=0`, sem erro de parse/case (só vazamentos de saída do headless).

## O que não foi verificado

- O tom exato do marrom escuro: usei `#5C3C1E`; se quiser mais escuro/claro, é só ajustar o valor e regravar o ícone.
- A comparação pixel a pixel com o anexo; o recorte foi reconstruído da arte local com a mesma geometria (face centralizada, bochecha direita cortada, boca na base).
- Os demais NPCs e aliados em todas as distâncias/ângulos; a prova cobre Bulbasaur e a faixa do Pancham/Orc.
- Os HUDs Comic/SMT: o ícone do Bulbasaur e os retratos têm o fundo Paper cozido; se o criador trocar o estilo do HUD, o fundo do retrato continuará marrom escuro.
- 60 fps/mobile, outras resoluções e a cena principal completa (VFX de outra sessão).

## Histórico de correções

1. A primeira tentativa removeu a **borda preta externa**; o criador corrigiu: a borda preta era boa, o que devia sair era o aro interno.
2. Depois o retrato passou a ocupar o medalhão até a borda preta, sem o aro interno; o criador pediu para **voltar com o aro interno** e **escurecer o fundo do ícone**.
3. Estado atual: borda preta + aro dourado interno + fundo `#5C3C1E` atrás do rosto + nome centralizado.

## Relação com a D-1093

A D-1093 escolheu o recorte **B (0,78 + 0,03 para a esquerda)** para o Bulbasaur. Esta D-1095 é mais nova e específica: o Bulbasaur passa a usar o **ícone fechado do anexo**. O recorte B e os PNGs A/B/C continuam no histórico/referência; a regra dos ícones estabelecidos para os demais personagens não muda.

## Estado

Implementado e provado. Commit local; **sem push**.
