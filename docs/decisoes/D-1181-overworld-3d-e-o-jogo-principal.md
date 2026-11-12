# D-1181 — O overworld 3D (o antigo laboratório) é o jogo principal; o jogo é completamente 3D

- **Data:** 2026-11-11.
- **Área:** Escopo do produto / exploração / GDD.
- **Relacionadas:** D-1022 (fim do overworld 2D), D-1023 (terceira pessoa SMT III), D-1027/D-1064 (2D só como mini-mapa), D-1028 (visual 3D toon), D-275/D-278/D-313 (overworld 2D, já substituídas no overworld por D-1022).
- **Status:** **decisão de escopo registrada; GDD atualizado (§7.30 e avisos de substituição); nenhum código, cena ou `project.godot` alterado.**

## O que o criador disse (literal)

> digamos que esse laboratorio é o jogo principal agora, não é mais um jogo 2D com 3D, agora é completamente 3D, atualize o GDD com todas features do overworld 3D

## Decisão

1. **O laboratório 3D da Murky Forest (`scenes/debug/murky_forest_3d_lab.tscn`, `scripts/debug/murky_forest_3d_lab.gd`, herdando `scripts/debug/third_person_3d_lab.gd`) passa a ser o jogo principal**, não mais um laboratório isolado.
2. **O Crawlmon deixa de ser "um jogo 2D com combate 3D" e passa a ser um jogo completamente 3D** (exploração em terceira pessoa + combate 3D com ATB).
3. **O 2D existe só como mini-mapa** (D-1027/D-1064): render top-down do andar 3D com bolinhas azul/branco/vermelho.
4. **As frases dos arquivos que dizem "o jogo normal não muda", "o jogo 2D atual é a build de referência" ou "só laboratório"** descrevem o estado *antes* desta decisão. Elas ficam intactas como histórico; o papel de "jogo normal" passa ao 3D.
5. **O GDD recebe a seção §7.30**, que reúne todas as features do overworld 3D já decididas (D-1022 a D-1180), cada uma com o ID de origem.

## O que esta decisão NÃO faz (nada foi alterado no código)

- `project.godot` continua com `run/main_scene="res://scenes/exploration.tscn"` (cena 2D). **Trocar a cena principal para o 3D é uma etapa separada** e não foi feita.
- O código e as cenas 2D (`scenes/exploration.tscn`, `scripts/dungeon/exploration.gd` etc.) **não foram apagados nem movidos**.
- O `README.md` continua descrevendo o protótipo 2D; não foi reescrito.
- Nenhuma regra de combate, atributo, Move ou número muda.

## Ambiguidades abertas (para o criador)

1. **Cena principal:** quando e como trocar `run/main_scene` para o 3D, e se o `JOGAR_LAB_3D.bat` vira o ponto de entrada.
2. **O que acontece com o overworld 2D:** apagar, manter como fallback (como em D-1022 item 3) ou arquivar em `scripts/legacy/`.
3. **Geração procedural em 3D:** o lab é um mapa fixo de salas autorais. A geração procedural em grade (D-326/D-1028 item 5) continua valendo no GDD, mas **não existe em 3D**; falta definir como ela vira 3D.
4. **Regras de exploração 2D do GDD (§7.14–§7.29):** as que falam de "mapa 2D", "aliados em 2D", "fog of war 2D" e "arenas por bioma a partir do 2D" foram marcadas como **substituídas no meio de exibição** (não nas regras de jogo). Se alguma regra de jogo dependia do meio 2D, precisa de decisão.
5. **Escala final, câmera final, bioma além da Murky Forest:** continuam pendentes (D-1023, D-1028).
