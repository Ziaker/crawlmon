# D-1206 — Move Forge: protótipo HTML separado para criar Moves por blocos

- **Data:** 2026-11-13
- **Área:** Ferramentas / Moves / protótipo HTML (`prototypes/`).
- **Relacionadas:** D-1163 e D-1179 (matriz de afinidades, ferramenta HTML), D-1204 (debug), D-308 (fases do Move), D-235 (Move independente de personagem/lado), D-236 (Splitter Flames), D-1205 (MoveData).
- **Estado:** **protótipo criado (2026-11-13), aguardando avaliação do criador:** `prototypes/move_forge/move_forge.html` + `tools/build_move_forge_data.py` (gera `prototypes/move_forge/move_forge_data.js` com os 39 Moves e as listas de VFX). Só o item 1 foi respondido por ele; os itens 3, 4 e 5 foram feitos pela recomendação depois de "quero ser completamente surpreendido" e **continuam sem "sim" explícito**. Depois: visual com ícones do jogo, "quem usa" (genérico ou único), aba VFX com clipes reais (`tools/build_move_forge_vfx.py`) e, a pedido ("me surpreenda"), remix de Move do jogo, orçamento de poder (pesos heurísticos da IA, limite = Move mais forte do jogo com o mesmo ATB), frase editável, bloqueio dos blocos que o motor não tem e mapa de ramos das condições. Pesos, limites e cores são palpites da IA, **pendentes de aprovação**. Nada no Godot.

## O que o criador disse (literal)

> pode ser um prototipo em html como o da matrix mas separado por ora ainda com o visual caracteristico do jogo

Pedido original (2026-11-13), literal:

> algo ambicioso, uma aba nova pra criação de move
>
> mas com uma interface, algo como um drag&drop com parâmetros e depois uma exportação completa pra você implementar
>
> leve em conta todos moves presentes até o momento e até os que não estão no jogo ainda como o splitter fire por conta de suas características
>
> aplicação de efeitos visuais já existentes, aplicações de efeitos de status já existentes, seja com imediato ou com chance ou com condição tipo interrupção, fraqueza, critico, quantidade especifica de vida seja do usuario ou do alvo, e outros

## Decisão (item 1)

- A ferramenta é um **protótipo HTML próprio em `prototypes/`, separado da matriz de afinidades**, com o **visual característico do jogo** (mesma linguagem visual da matriz/HUDs).
- Drag&drop de blocos com parâmetros e **exportação completa** para o Claude implementar.

## Em aberto (aguardando "sim" do criador, item a item)

2. Formato do export: campos reais do `MoveData` + lista de efeitos e gatilhos (recomendação: sim; detalhe técnico).
3. Blocos "Falta no motor" (multi-golpe, refletir/contra, vampirismo, autodano, "vida do usuário abaixo de X", "alvo tem status X") montáveis, com o briefing marcando-os como pendentes (recomendação: sim).
4. Visual só com VFX já existentes (famílias, flipbooks, shaders do Motion Composer), sem criar efeito novo na aba (recomendação: sim).
5. A ferramenta preenche também os textos de ficha por fase (`phase_visuals`), editáveis (recomendação: sim).
6. Divisão: Claude faz a interface; `deepseek-code` só entra depois, no código GDScript de importação do JSON (recomendação: sim; processo).

## Levantamento do código (2026-11-13)

Não existem no motor: multi-golpe, cooldown, refletir/contra, vampirismo, autodano, condições "vida do usuário abaixo de X" e "alvo tem status X". Crítico, fraqueza e interrupção são sinalizadores avaliados dentro dos comportamentos (`info.weak/crit/interrupted`); chances usam `status_application_chance`. Splitter Flames já existe como Move só visual; o modo duplo, o retarget, MP 20, fórmula e Burn estão pendentes (D-236, D-335, D-337).
