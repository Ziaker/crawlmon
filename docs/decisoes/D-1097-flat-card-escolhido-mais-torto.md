<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

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
- `murky_forest_3d_lab.gd`: `name_style = "unit_card"` como padrão; `F6` continua alternando para B/C; alturas da placa A ajustadas (`+0,65 m`, ícone `+1,75 m` na D-1098, reticências `+1,65 m`, inimigo `2,20 m`).

## Provas

- `docs/referencias/exploracao/3d/flat_card_size_30.png` — **antes/depois com régua:** 3,06 m → 3,97 m (+30%) e nome 100 → 120, mesma câmera.
- `docs/referencias/exploracao/3d/name_styles_d1096_unit_card.png` — A no cenário.
- `docs/referencias/exploracao/3d/name_styles_d1096_comparison.png` — A maior ao lado de B/C.
- `docs/referencias/exploracao/3d/name_styles_d1096_lineup.png` — comparação direta.
- `docs/referencias/exploracao/3d/name_styles_d1096_cycle.gif` / `.mp4` — ciclo com a A maior.
- `docs/referencias/exploracao/3d/audit_d1097_10npcs.png` — os 10 NPCs com a A.
- `docs/referencias/exploracao/3d/audit_d1097_roles.png` — BULBASAUR/PANCHAM/ORC/SLIME.
- `docs/referencias/exploracao/3d/audit_d1097_near_far.png` — 3 m × 9 m.
- `docs/referencias/exploracao/3d/audit_d1097_mirror.png` — frente × lado espelhado.
- `docs/referencias/exploracao/3d/audit_d1097_icon.png` — vão até o ícone de estado.
- `docs/referencias/exploracao/3d/audit_d1097.txt` — relatório completo.

## Validação (2026-11-10)

- **Padrão A:** `name_style = unit_card`; 6 placas (3 NPCs + 2 aliados + 1 inimigo).
- **10 NPCs:** todos os nomes cabem; maior **CHARMANDER 3,37 m** de 3,51 m úteis.
- **Papéis:** BULBASAUR/NPC, PANCHAM/ALLY, ORC/ALLY e SLIME/ENEMY usam a mesma placa A (o A é só nome).
- **Vão do ícone (validação com o ícone 2D de 0,56 m):** topo da placa 1,989 m; base do ícone 2,118 m → **0,13 m** sem sobreposição; inimigo **0,11 m**.
- **D-1098:** o ícone 2D foi substituído pelo **3D de 1,00 m** em `altura + 1,75 m` (desceu 0,10 m a pedido do criador); o vão atual é **0,04 m** no NPC e **0,09 m** no inimigo (placa em 2,20 m). As provas `audit_d1097_icon.png` são históricas.
- **F6:** `move_strip`, `expedition` e `unit_card` em todas as 6 placas; papel visível em B/C e oculto em A.
- **Vistas:** frente e lado espelhado com o nome correto; perto (3 m) e longe (9 m) legíveis.
- **Headless:** `exit=0`; checks dos scripts OK.

## O que não foi verificado

- Se o ângulo de -3,5° e o tamanho de 3,97 m são exatamente o que o criador queria; são ajustes visuais fáceis (aumentar/diminuir).
- Todos os ângulos possíveis de câmera, mobile/60 fps e a cena principal completa (VFX de outra sessão).

## D-1105 (posterior)

A base do Flat Card A foi reduzida para **40%** (1,588 × 0,448 m) e o fator de distância passou a **diminuir** o tamanho na tela com a distância. As medidas de 3,97 × 1,12 m desta decisão são históricas.

## Estado

Implementado e provado. Commit local; **sem push**.
