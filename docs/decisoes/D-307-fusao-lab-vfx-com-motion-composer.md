# D-307 — Fusão do laboratório de VFX (`tests/fx_lab`) com o laboratório do Motion Composer

- **Data:** 2026-11-05
- **Área:** VFX / Laboratório / Motion Composer
- **Origem:** Conversa (a partir da proposta D-274, ainda pendente)

## O que o criador disse (literal)

> é pra teoricamente vc fundir ambos ou só colocar o motion composer encima se ele ser completamente superior, faça o pr commit e merge do que ainda falta

Respostas às perguntas (literais): primeiro passo da D-274 → "Item 6 (medição e avaliação)"; onde → "tests/fx_lab (laboratório do jogo)"; formato da fusão → "Lab do composer ganha os efeitos"; como tocar os efeitos do jogo (que não aceitam pausa nem busca) → "melhore o debug até ser capaz de fazer tudo isso e até mais"; quais efeitos → "Os 9 via BattleFx".

## Decisão

- O **laboratório do Motion Composer** (`scenes/motion_lab/`, `scripts/motion_composer/lab/`) passa a poder **tocar os efeitos existentes do jogo** como referência, ao lado das composições.
- O Motion Composer **não** substitui o `fx_lab`: não é "completamente superior" (não tem os efeitos do jogo). O `fx_lab` permanece até o criador decidir o contrário.
- O primeiro passo da D-274 é o **item 6** (medição e avaliação), aplicado também aos efeitos de referência.
- Os PRs e merges pedidos: o PR #1 do Motion Composer foi mergeado na `main` em 2026-11-05 (`ad1fe8ff`).

## Regras que continuam valendo

- D-003, D-019, D-020: sem alterar combate, `VfxLib`, `BattleFx`, cenas nem VFX existentes. O acesso aos efeitos existentes é **somente leitura/uso**, sem editá-los.
- D-235 / AGENTS §7: origem, alvo, direção, tamanho e lado derivados de atacante e alvo reais do laboratório; nenhum personagem, time, lado ou coordenada fixa (o `fx_lab` atual usa `ABRA_POS`/`GIBLE_POS`; **não** copiar isso). Teste espelhado obrigatório.
- D-042–D-046 (laboratório): tempo explícito, pausa, reinício e inspeção.

## Ambiguidades em aberto

1. **Busca no tempo (seek) e pausa dos efeitos do jogo:** o criador pediu "melhore o debug até ser capaz de fazer tudo isso e até mais". Fatia 1: disparo, reinício e ritmo. **Fatia 2 (2026-11-05): busca no tempo** por reinício com a mesma semente e avanço em passos de 1/60 s, aproximada (ver §34.1). Faltam: lado a lado com a composição e o que mais o criador pedir, uma fatia por vez, sem editar `BattleFx`.
2. Os efeitos do Abra que vivem só no `fx_lab` (Raio Psíquico, Onda de Choque, Confusão): fora da 1ª fatia.
3. Receita do estudo com M19 (pergunta anterior, D-306): ainda sem resposta.
4. O número D-274 da proposta e a relação com esta decisão.

## Estado

**Fatia 1 implementada** (2026-11-05): `lab/game_fx_bridge.gd` (ponte só de uso), seção "Efeitos do jogo" no painel direito do laboratório; os 9 efeitos entre atacante e alvo derivados (distância, alturas, espelhar), ritmo por `Engine.time_scale`, métricas (nós, partículas, malhas, draw calls, primitivas, objetos, pico). 16 verificações novas, 819 no total. **Fatia 2 (busca no tempo) implementada**; 831 verificações no total. **Aguardando a aprovação visual do criador** das duas fatias. Nada em `scripts/combat`, `scripts/vfx` ou cenas de combate foi alterado.
