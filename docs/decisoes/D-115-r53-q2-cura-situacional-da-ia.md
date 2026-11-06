# D-115 — Rodada 53, Q2: cura com poções entra na decisão tática situacional da IA

- **Data:** 2026-11-03
- **Origem:** o criador aceitou as recomendações do assistente sobre a IA, sem escolher letras individualmente. O assistente recomendou **2B** após comparar alternativas e código.
- **Estado:** recomendação do assistente aceita por delegação expressa; decisão de design documentada, **não implementada**.

## Declaração literal do criador

> sigo suas recomendacoes quanto a forma que a IA deve agir, ate mesmo para as proximas perguntas

## Pergunta e recomendação aceita (redação do assistente, não do criador)

- **R53-Q2:** A IA deve continuar usando poção automaticamente quando estiver com 50% de HP ou menos?
- **Recomendação do assistente: 2B —** Integrar poções à decisão tática: avaliar se vale mais curar ou usar um Move, conforme a situação do combate.

## Regra consolidada

- Personagens controlados pela IA (**aliados e inimigos**) **avaliam situacionalmente a escolha entre curar com uma poção disponível e usar um Move**, em vez de priorizar sempre a poção ao alcançar um limiar de HP.
- Na avaliação tática, considerar as condições verificáveis do combate, incluindo risco da unidade, benefício de curar e oportunidade de executar um Move relevante. Não definir peso numérico, limite novo de HP ou estratégia fixa sem regra adicional.
- A decisão mantém os **itens existentes**, custos em ATB, disponibilidade real de poções, restrições de ações e **Tactics do personagem**. Não cria novos itens nem uso ilimitado de poções.
- Manter D-021 (simetria) e D-112/D-114 (escolha tática de Move e ordem alvo → Move) sem transformar a seleção do alvo em preferência tática.

## Fonte e limites

- Atualmente `Battle._run_ai()` em `scripts/combat/battle.gd` prioriza poção com `hp <= max_hp * AI_HEAL_BELOW` (`AI_HEAL_BELOW := 0.5`) e ATB suficiente, **antes** de avaliar a escolha de Move ou a Tactic de ataque. A recomendação aceita é **requisito de comportamento futuro**, não estado atual.
- A resposta não especifica novo valor de limiar, pesos, regras de empate ou priorização exata entre cura e ataque. **Não inventar**.
- **Escopo:** documentação somente; não modificar código nem testes.

## Complemento posterior (2026-11-03)

**D-911:** implementado em `scripts/combat/battle_ai.gd`; a Tactic "Segurar" mantém a regra antiga de 50%.
