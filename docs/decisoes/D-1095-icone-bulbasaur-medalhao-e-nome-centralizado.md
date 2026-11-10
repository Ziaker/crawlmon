# D-1095 — Ícone do Bulbasaur no recorte anexado, medalhão sem borda interna e nome centralizado

- **Data:** 2026-11-10.
- **Área:** Exploração / diálogo / retratos / HUD Paper.
- **Relacionadas:** D-1093 (ícone estabelecido), D-1090 (HUD C/Paper), D-1092 (faixas dos aliados), D-1074 (face crop).
- **Status:** **implementado e provado**; batalha, 2D, HUD/status, cards, regras, falas, câmera e placas flutuantes não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> troque o icone do bulbasaur por este que já está no alinhamento que eu queria. Além disso, remova essa borda interior marrom mas mantenha o fundo marrom

> corrija tambem o alinhamento central do nome do personagem, está mais pra cima do que centralizado

## Regra

1. **Bulbasaur usa o recorte fechado do anexo**, com a face centralizada, a bochecha direita cortada na borda e a boca perto da base. O recorte é feito da arte local (`sugimori/por_nome/bulbasaur.png`), com padding transparente à esquerda para a face ficar na posição do anexo, e o fundo do medalhão é preenchido com o **marrom/dourado do Paper** (`Color(0.85, 0.68, 0.30)`), para não aparecer a franja escura da máscara.
2. **O medalhão do retrato perde a borda interna escura** (o `border` do `StyleBoxFlat` do `_portrait_back`), mas mantém o **fundo marrom/dourado**. Vale para o card Paper do diálogo e para a faixa do aliado.
3. **O nome do personagem no name tab do Paper fica centralizado verticalmente**; antes o texto estava mais para cima do que o centro da faixa.
4. **Os demais personagens** continuam com o face crop atual até receberem um ícone próprio; a mudança desta rodada é o Bulbasaur e o acabamento do medalhão/nome.
5. **O que não muda:** batalha, 2D, HUD/status, cards, regras, falas, câmera, anéis e as placas de nome flutuantes (D-1094). Nas faixas, só o medalhão perde a borda; o resto da faixa continua igual.

## Implementação

- **Novo asset:** `assets/ui/portraits/bulbasaur.png` (512×512, pré-mascarado em círculo, fundo marrom/dourado). O recorte é quadrado (536 px) com 45 px de padding à esquerda, a partir da janela `(0, 47, 491, 583)` da arte local; a boca fica na base e a bochecha direita é cortada.
- **`_portrait_for_speaker()`** usa esse ícone para o Bulbasaur e mantém o recorte dinâmico (`_circular_portrait`) para os demais personagens.
- **`dialogue_hud_styles.gd` (Paper)** e **`ally_banner.gd`:** o `_portrait_back` agora tem `border_w = 0` e continua com `bg_color = Color(0.85, 0.68, 0.30)`.
- **Nome:** `_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER` no name tab Paper.
- O recorte é gerado por `scratch/make_bulbasaur_portrait.py` (script de apoio, não entra no jogo).

## Provas

- `docs/referencias/exploracao/3d/bulbasaur_icon_before_after.png` — antes/depois do ícone, da borda do medalhão e do nome.
- `docs/referencias/exploracao/3d/murky_forest_paper_dialogue.png` — card Paper completo com o novo ícone e o nome centralizado.
- `docs/referencias/exploracao/3d/murky_forest_panchan_reaction.png` — faixa do Pancham sem a borda interna do medalhão.
- `docs/referencias/exploracao/3d/murky_forest_orc_reaction.png` — faixa do Orc com o mesmo acabamento.

## O que foi verificado

- O card Paper do Bulbasaur com o recorte fechado, o fundo marrom/dourado mantido e o nome centralizado.
- A faixa do Pancham/Orc com o medalhão sem a borda interna.
- Cena `scenes/debug/murky_forest_3d_lab.tscn` headless: `exit=0`, sem erro de parse/case (só vazamentos de saída do headless).

## O que não foi verificado

- A comparação pixel a pixel com o anexo; o recorte foi reconstruído da arte local com a mesma geometria (face centralizada, bochecha direita cortada, boca na base).
- Os demais NPCs e aliados; só o Bulbasaur e o acabamento do medalhão/nome mudam nesta rodada.
- Os HUDs Comic/SMT: o ícone do Bulbasaur tem o fundo Paper cozido; se o criador trocar o estilo do HUD, o medalhão continuará marrom/dourado.
- 60 fps/mobile, outras resoluções e a cena principal completa (VFX de outra sessão).

## Notas nas decisões relacionadas

- **D-1093:** o Bulbasaur passa a usar este ícone fechado; o B (0,78 + 0,03 esquerda) fica como referência.
- **D-1090:** o name tab Paper fica com o nome centralizado e o medalhão sem a borda interna.
- **D-1092:** a faixa do aliado mantém o fundo marrom/dourado, sem a borda interna do medalhão.

## Relação com a D-1093

A D-1093 escolheu o recorte **B (0,78 + 0,03 para a esquerda)** para o Bulbasaur. Esta D-1095 é mais nova e específica: o Bulbasaur passa a usar o **ícone fechado do anexo**. O recorte B e os PNGs A/B/C continuam no histórico/referência; a regra dos ícones estabelecidos para os demais personagens não muda.

## Estado

Implementado e provado. Commit local; **sem push**.
