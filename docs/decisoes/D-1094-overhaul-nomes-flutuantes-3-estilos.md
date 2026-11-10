# D-1094 — Overhaul dos nomes flutuantes: 3 estilos para comparação

- **Data:** 2026-11-10.
- **Área:** Exploração / overworld 3D / UI dos nomes.
- **Relacionadas:** D-1086 (nomes/ícones/círculos), D-1090 (ícones/estouro), D-1091 (anéis), D-1092 (faixas/câmera), D-1093 (ícones estabelecidos), D-235 (nada depende de personagem/time/lado).
- **Status:** **3 protótipos implementados e capturados; aguardando a escolha do criador**; o lab usa **Paper** como provisório e `F6` alterna; batalha, 2D, HUD/status, cards, regras e falas não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> me de ideias de overhaul para os nomes flutuantes, pode ser ambicioso, efetue as 3 ideias de imediato para comparação visual e depois escolherei a melhor

## Objetivo

Trocar o nome flutuante simples (um `Label3D` solto acima da cabeça) por uma **placa de nome** com identidade visual própria, mantendo o nome legível a qualquer distância e o mesmo comportamento para NPC, aliado e inimigo (D-235). As três opções foram executadas juntas, com o mesmo personagem, a mesma câmera e o mesmo momento, para o criador escolher uma.

## As 3 opções

### A — Paper & Pin

- Placa de papel rasgado, pino dourado e aba verde de identificação (`NPC`/`ALLY`/`ENEMY`).
- Nome em tipografia com serifa, tinta escura; papel envelhecido com fibras e linha dourada.
- Entrada com encaixe do pino e balanço suave; a placa respira junto com o personagem.
- Combina com o HUD Paper (D-1090) e com as faixas dos aliados (D-1092).

### B — SMT Holo

- Terminal de vidro escuro com cantos ciano, barra vermelha, scanlines e marca `SMT //`.
- Nome em monoespaçada ciano, alinhado à esquerda; entra como um boot de terminal, com o nome sendo digitado.
- Um feixe de varredura percorre a placa e, de tempos em tempos, um glitch curto desloca/duplica o nome em vermelho.
- É a leitura mais "SMT III / Nocturne" das três.

### C — Comic Impact

- Balão de fala de papel creme, contorno preto grosso, rabicho, meio-tom e acento amarelo.
- Nome em Kanit Black Italic, preto, com badge de papel no canto para `NPC`/`ALLY`/`ENEMY`.
- Entrada elástica (estoura e assenta), inclinação leve e oscilação de balão.
- É a opção mais "comic/manga" e a de maior contraste à distância.

## Regras de implementação

1. **Uma placa por ator:** NPC, aliado e inimigo usam o mesmo componente (`scripts/debug/floating_nameplate.gd`); o comportamento depende do estilo e do papel (`NPC`/`ALLY`/`ENEMY`), nunca do personagem, do time ou do lado (D-235).
2. **A placa sempre olha para a câmera**, com texto e adornos grudados na placa; não há posição fixa de câmera nem lado privilegiado.
3. **A distância continua controlando o tamanho** (`clampf(dist / 8.0, 0.28, 1.1)`), como nos nomes atuais. A placa é maior que o `Label3D` antigo (512×144, `pixel_size` 0,0034) para o texto não encolher junto com a moldura.
4. **O nome não substitui os indicadores:** o ícone de estado, as reticências de fala e os anéis do chão continuam existindo; a placa é só o nome.
5. **Alturas:** NPC/aliado têm a placa em `altura + 0,50 m`; o inimigo Slime em `1,45 m`. Ícone de estado e reticências do NPC/aliado subiram para `altura + 0,92 m` para não colidir com a placa.
6. **Ordem de desenho:** a placa, o nome e a função usam `render_priority` (0/3/5) para o texto não ser coberto pela textura transparente da placa; o fantasma do glitch usa prioridade 4.
7. **Escolha única:** o criador escolhe A, B ou C; as outras duas ficam como referência. O estilo escolhido vira o padrão do overworld. Até a escolha, `name_style = "paper"` é provisório e `F6` alterna no lab.
8. **O que não muda:** batalha, 2D, HUD/status, cards, regras, falas, câmera, faixas e anéis.

## Arquivos

- `assets/ui/nameplates/nameplate_paper.png`
- `assets/ui/nameplates/nameplate_terminal.png`
- `assets/ui/nameplates/nameplate_comic.png`
- `scripts/debug/floating_nameplate.gd`
- `scripts/debug/murky_forest_3d_lab.gd` (integração, `F6`, `set_name_style()`)

## Provas

- `docs/referencias/exploracao/3d/name_style_a_paper.png` — A no cenário real.
- `docs/referencias/exploracao/3d/name_style_b_terminal.png` — B no cenário real.
- `docs/referencias/exploracao/3d/name_style_c_comic.png` — C no cenário real.
- `docs/referencias/exploracao/3d/name_styles_comparison.png` — folha A/B/C lado a lado.
- `docs/referencias/exploracao/3d/name_styles_lineup.png` — mesma pose, três placas, comparação direta.
- `docs/referencias/exploracao/3d/name_styles_roles_paper.png` — Bulbasaur/NPC, Pancham/ALLY e Slime/ENEMY com a mesma placa (D-235).
- `docs/referencias/exploracao/3d/name_styles_cycle.mp4` / `.gif` — ciclo real com entrada, flutuação, digitação e glitch.

## O que foi verificado

- As 3 placas no mesmo NPC, mesma câmera e mesma pose; texto legível a ~3 m e ~7 m (composição da prova e lineup).
- A mesma placa em NPC, aliado e inimigo, inclusive o inimigo do lado esquerdo e o aliado no centro (D-235); papéis `NPC`/`ALLY`/`ENEMY` visíveis.
- Troca de estilo em tempo real por `set_name_style()` (usada pelas provas) e pelo `F6` no lab.
- Cena `scenes/debug/murky_forest_3d_lab.tscn` headless: `exit=0`, sem erro de parse/case (só vazamentos de saída do headless).

## O que não foi verificado

- A escolha final A/B/C.
- Todos os 10 NPCs, todos os aliados e o inimigo em todas as distâncias, ângulos e lados; as provas cobrem Bulbasaur, Pancham e Slime.
- 60 fps/mobile, outras resoluções e a cena principal completa (VFX de outra sessão).
- O texto do papel/terminal/comic em todos os idiomas/tamanhos de tela.

## Estado

Protótipos A/B/C implementados, integrados e capturados. O estilo **Paper** está provisório no lab; nenhum estilo foi oficializado. Commit local; **sem push**.
