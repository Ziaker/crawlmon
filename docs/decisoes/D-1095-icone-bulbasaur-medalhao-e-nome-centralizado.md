# D-1095 — Ícone do Bulbasaur no recorte anexado, medalhão sem aro interno e nome centralizado

- **Data:** 2026-11-10.
- **Área:** Exploração / diálogo / retratos / HUD Paper.
- **Relacionadas:** D-1093 (ícone estabelecido), D-1090 (HUD C/Paper), D-1092 (faixas dos aliados), D-1074 (face crop).
- **Status:** **implementado e provado**; batalha, 2D, HUD/status, cards, regras, falas, câmera e placas flutuantes não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> troque o icone do bulbasaur por este que já está no alinhamento que eu queria. Além disso, remova essa borda interior marrom mas mantenha o fundo marrom

> corrija tambem o alinhamento central do nome do personagem, está mais pra cima do que centralizado

> o ícone novo do bulbsaur está otimo mas vc não tirou a borda interior que eu pedi pra tirar, tirou a borda preta que estava boa já

## Regra

1. **Bulbasaur usa o recorte fechado do anexo**, com a face centralizada, a bochecha direita cortada na borda e a boca perto da base. O recorte é feito da arte local (`sugimori/por_nome/bulbasaur.png`), com padding transparente à esquerda para a face ficar na posição do anexo, e o fundo do medalhão é preenchido com o **marrom/dourado do Paper** (`Color(0.85, 0.68, 0.30)`).
2. **A borda preta externa do medalhão continua** (era boa). O que sai é o **aro dourado/marrom interno** entre essa borda e o retrato: o retrato passa a ocupar o medalhão até a borda preta (2 px), mantendo o **fundo marrom/dourado** atrás do rosto. Vale para o card Paper do diálogo e para a faixa do aliado.
3. **O nome do personagem no name tab do Paper fica centralizado verticalmente**; antes o texto estava mais para cima do que o centro da faixa.
4. **Os demais personagens** continuam com o face crop atual até receberem um ícone próprio; o acabamento do medalhão (sem aro interno) e o nome centralizado valem para todos.
5. **O que não muda:** batalha, 2D, HUD/status, cards, regras, falas, câmera, anéis e as placas de nome flutuantes (D-1094).

## Implementação

- **Novo asset:** `assets/ui/portraits/bulbasaur.png` (512×512, pré-mascarado em círculo, fundo marrom/dourado). O recorte é quadrado (536 px) com 45 px de padding à esquerda, a partir da janela `(0, 47, 491, 583)` da arte local; a boca fica na base e a bochecha direita é cortada.
- **`_portrait_for_speaker()`** usa esse ícone para o Bulbasaur e mantém o recorte dinâmico (`_circular_portrait`) para os demais personagens.
- **`_circular_portrait()`** compõe o rosto sobre o dourado do Paper e mantém o RGB dourado fora do círculo, para a borda da máscara não puxar uma franja escura.
- **`dialogue_hud_styles.gd` (Paper)** e **`ally_banner.gd`:** o `_portrait_back` mantém `bg_color = Color(0.85, 0.68, 0.30)` e `border = Color(0.16, 0.25, 0.16)`, 2 px. O `_portrait_rect` ocupa o conteúdo até a borda (138 px no card, 52 px na faixa), eliminando o aro dourado interno.
- **Nome:** `_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER` no name tab Paper.
- O recorte é gerado por `scratch/make_bulbasaur_portrait.py` (script de apoio, não entra no jogo).

## Provas

- `docs/referencias/exploracao/3d/bulbasaur_icon_before_after.png` — antes/depois do ícone, do aro interno e do nome; a borda preta aparece no depois.
- `docs/referencias/exploracao/3d/murky_forest_paper_dialogue.png` — card Paper completo com o novo ícone, borda preta, sem aro interno e nome centralizado.
- `docs/referencias/exploracao/3d/murky_forest_panchan_reaction.png` — faixa do Pancham com o mesmo acabamento.
- `docs/referencias/exploracao/3d/murky_forest_orc_reaction.png` — faixa do Orc com o mesmo acabamento.

## O que foi verificado

- O card Paper do Bulbasaur com o recorte fechado, o **fundo marrom/dourado mantido**, a **borda preta externa** e **sem o aro dourado interno**; o nome centralizado.
- A faixa do Pancham/Orc com o retrato até a borda preta e sem o aro interno.
- Cena `scenes/debug/murky_forest_3d_lab.tscn` headless: `exit=0`, sem erro de parse/case (só vazamentos de saída do headless).

## O que não foi verificado

- A comparação pixel a pixel com o anexo; o recorte foi reconstruído da arte local com a mesma geometria (face centralizada, bochecha direita cortada, boca na base).
- Os demais NPCs e aliados em todas as distâncias/ângulos; a prova cobre Bulbasaur e a faixa do Pancham/Orc.
- Os HUDs Comic/SMT: o ícone do Bulbasaur e os retratos têm o fundo Paper cozido; se o criador trocar o estilo do HUD, o medalhão continuará marrom/dourado.
- 60 fps/mobile, outras resoluções e a cena principal completa (VFX de outra sessão).

## Correção após o feedback

A primeira tentativa removeu a **borda preta externa** do `_portrait_back` e deixou o aro dourado interno. O criador corrigiu: a borda preta era boa e o que devia sair era o **aro interno**. Nesta versão a borda preta voltou (2 px) e o retrato passou a ocupar o medalhão até ela; o aro dourado interno desapareceu e o fundo marrom/dourado atrás do rosto ficou.

## Relação com a D-1093

A D-1093 escolheu o recorte **B (0,78 + 0,03 para a esquerda)** para o Bulbasaur. Esta D-1095 é mais nova e específica: o Bulbasaur passa a usar o **ícone fechado do anexo**. O recorte B e os PNGs A/B/C continuam no histórico/referência; a regra dos ícones estabelecidos para os demais personagens não muda.

## Estado

Implementado e provado. Commit local; **sem push**.
