# D-307 — Fusão do laboratório de VFX (`tests/fx_lab`) com o laboratório do Motion Composer

- **Data:** 2026-11-05
- **Área:** VFX / Laboratório / Motion Composer
- **Origem:** Conversa (a partir da proposta D-274, ainda pendente)

## O que o criador disse (literal)

> é pra teoricamente vc fundir ambos ou só colocar o motion composer encima se ele ser completamente superior, faça o pr commit e merge do que ainda falta

Respostas às perguntas (literais): primeiro passo da D-274 → "Item 6 (medição e avaliação)"; onde → "tests/fx_lab (laboratório do jogo)"; formato da fusão → "Lab do composer ganha os efeitos".

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

1. Como tocar os efeitos existentes: eles são "dispare e esqueça" (tweens e temporizadores em tempo real) e **não aceitam seek nem pausa pelo relógio do laboratório**. Possibilidades: sobreposição em tempo real que reinicia com o Play, ou outra.
2. Quais efeitos entram (os 9 do `fx_lab` que usam `BattleFx`; os efeitos do Abra que vivem só no `fx_lab`).
3. Receita do estudo com M19 (pergunta anterior, D-306): ainda sem resposta.
4. O número D-274 da proposta e a relação com esta decisão.

## Estado

Decisão registrada; **nenhum código escrito**. Aguardando respostas às ambiguidades 1 e 2.
