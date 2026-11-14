<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-111 — Rodada 51, Q2 (2C): seleção aleatória de adversário vivo pela IA, preservando engajamento

- **Data:** 2026-11-03
- **Área:** Combate / IA e Tactics / Rodada 51
- **Origem:** escolha expressa do criador.
- **Estado:** decisão de design aprovada e registrada; implementação não declarada.

## Declaração literal do criador

> 2C — Como a IA escolhe qual inimigo atacar? Escolher aleatoriamente entre adversários vivos, respeitando o engajamento.

## Regra aprovada

- Ao selecionar um alvo para um ataque **não amigável**, se o personagem controlado pela IA **não estiver engajado com um adversário vivo**, o alvo deve ser **escolhido aleatoriamente entre os adversários vivos elegíveis**, em vez de selecionar sempre o primeiro adversário vivo da lista.
- **Respeitar o engajamento:** se o personagem controlado pela IA estiver engajado com um adversário vivo, a escolha de alvo desse ataque permanece **restrita ao adversário engajado**, conforme a validação existente de `Battle.use_skill()`.
- **Simetria:** aplicar aos personagens conduzidos pela IA, tanto **aliados quanto inimigos**, sem mudar as Tactics atuais, o Move escolhido, as regras de itens, de alvo de ações amigáveis ou o controle manual do líder.
- **Base verificada:** `Battle._run_ai()` em `scripts/combat/battle.gd` seleciona atualmente `c.engaged_with` ou `_first_alive(foes)`; o novo requisito **substitui somente a seleção determinística do primeiro vivo por escolha aleatória**, mantendo a prioridade do engajamento. D-021 preservada.

## Limites

- O criador não definiu uma política de pesos ou probabilidades diferentes entre alvos vivos; não impor preferência por HP baixo, proximidade, fraqueza ou outra avaliação estratégica não solicitada.
- Não altera a política de escolha de Moves (`_pick_skill()`), de cura (`AI_HEAL_BELOW`), de passo tático ou de contra-ataque, que obedecem às decisões próprias.
- **Escopo:** registro documental somente. Nenhum código, testes, VFX ou dados modificados.

## Complemento posterior — Rodada 52

**D-112 (R52):** selecionar aleatoriamente o **alvo vivo** respeitando engajamento continua válido (D-111). A seleção de **qual Move usar** passa a ser tática, considerando dano, fraqueza, efeitos e situação do combate. Não confundir alvo com Move.

## Complemento posterior — Rodada 53

**D-114 (Rodada 53):** preserva a escolha aleatória de **alvo** entre adversários vivos elegíveis, respeitando engajamento. Na hora de decidir qual habilidade executar, a IA primeiro fixa esse alvo e depois avalia taticamente o **Move** adequado a ele (D-112/D-114). Não se transforma a escolha do alvo em decisão tática.

## Complemento posterior (2026-11-03)

**D-168:** implementado em `scripts/combat/battle_ai.gd`.
