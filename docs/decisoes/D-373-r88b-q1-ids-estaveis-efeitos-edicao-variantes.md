# D-373 — Rodada 88B Q1 (1A): IDs estáveis de efeitos e edição explícita por variante

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / Effects / variantes.
- **Origem:** decisão expressa do criador na Rodada 88B.
- **Estado:** contrato documental aprovado; não implementado.

## Declaração literal do criador

> 1A — Identificar cada efeito declarado por um ID estável dentro da ficha e permitir que a variante substitua, acrescente ou remova entradas explicitamente, preservando as demais e sua ordem.

## Regra aprovada

- Cada efeito declarado recebe **ID estável dentro da ficha** do Move. Variantes podem **substituir, acrescentar ou remover entradas** explicitamente, preservando todas as demais e sua ordem.
- Preservar D-333 e D-360: uma ficha lógica por Move, parâmetros comuns na declaração principal e apenas substituições reais em variantes. D-361 determina que efeitos são tipados e ordenados, com parâmetros/condições/abrangência conforme declaração.
- **Diferenciar IDs de efeito da ficha** dos **índices de ocorrências mecânicas** reservados ao declarar o ataque (D-218/D-222/D-226) e dos IDs de diagnóstico de excesso (D-256/D-266). A nova organização de fichas não renumera ocorrências.
- **Exemplo hipotético:** Splitter Flames pode editar apenas uma entrada de efeito que já difere entre as variantes de um e dois alvos, sem alterar outras entradas; nenhum número, efeito ou variante novo é aprovado.
- Preservar D-235 (execução independente de personagem/lado), D-343/D-349 (Resources mecânico/visual por Move e vínculo por ID) e D-340 (interpretador reutilizável).

## Pendências e limites

- **Não decididos:** formato e namespace dos IDs de efeitos, posição exata de novas entradas acrescentadas, resolução de operações conflitantes, mesclagem de arrays, comportamento para ID duplicado/desconhecido e esquema dos Resources. Não preencher por inferência.
- Apenas documentação. Nenhum código, Resource, Move, teste ou VFX modificado.
