# D-140 — Rodada 57 Q2 (A): AGI efetiva mínima de 1 apenas para o cálculo inverso do Move

- **Data:** 2026-11-03
- **Área:** Personagens / atributos / combate / Rodada 57.
- **Origem:** escolha enviada expressamente pelo criador; as alternativas das questões 2–4 haviam sido recomendadas pelo assistente.
- **Estado:** regra aprovada e registrada em documentação; não implementada nesta atividade.

## Declaração literal do criador

> 2A — O que acontece quando a AGI efetiva chega a zero? Usar AGI efetiva mínima de 1 exclusivamente para o cálculo, sem alterar o atributo permanente. (recomendação aceita)

## Regra aprovada

- Se AGI efetiva chegar a zero ou for não positiva, usar **1 como valor mínimo exclusivamente na fórmula inversa de tempo de trajeto** (D-136), evitando divisão por zero. **Não modificar o atributo permanente** ou persistir uma elevação de AGI.
- Preservar a referência AGI comum entre espécies, ainda não definida numericamente (D-136), a ordem AGI → passos (D-133), a subtração `0,10 s × (passo_atacante + passo_alvo)` e o piso final **0,25 s** (D-018).
- O piso de cálculo desta decisão não se estende automaticamente à regeneração ATB ou a outras mecânicas de AGI. Exemplo: AGI efetiva 0 usa 1 para calcular trajeto, mas continua 0 no estado, caso assim esteja registrado.

## Limitações

- Detalhes quantitativos não contidos na declaração literal continuam pendentes. Sem alterações de código, dados, testes, VFX ou assets.
