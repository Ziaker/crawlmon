# D-175 — Rodada 64 Q4 (4C): medir preenchimento natural ATB de 3 a 5 e de 0 a 5 blocos

- **Data:** 2026-11-03.
- **Área:** Combate / ATB / protocolo de calibração.
- **Origem:** escolha expressa do criador na Rodada 64.
- **Estado:** escopo de comparação aprovado; **medições não executadas**, sem referência numérica fixada.

## Declaração literal do criador

> 4C — Medir ambos os intervalos, de 3 a 5 e de 0 a 5, para comparar com o comportamento atual.

## Regra aprovada

- Para determinar a referência numérica de AGI usada na **regeneração natural de ATB** pela calibração do ritmo existente (D-169), **medir e comparar ambos os intervalos de preenchimento natural**: **3 → 5 blocos** e **0 → 5 blocos**.
- Usar os resultados para comparar o **comportamento atual** antes de apresentar ao criador uma referência numérica proposta; não definir o valor por suposição e não implementar antes da validação já exigida em D-169.
- O intervalo 3 → 5 corresponde ao cenário com **3 blocos iniciais** aprovado em **D-031** e observado no código consultado; o intervalo 0 → 5 permite observar a barra integralmente vazia. A escolha **não altera ATB inicial, máximo, bloqueios, recompensas, Burst ou taxa de geração** do jogo atual.
- **Exemplo não normativo:** sob taxa constante puramente hipotética de 1 bloco/s, 3 → 5 levaria 2 s e 0 → 5 levaria 5 s. **Nenhum desses tempos foi medido ou aprovado para o Crawlmon.**
- Preservar D-163 (tempo inversamente proporcional à AGI efetiva), D-164 (piso AGI 1 somente no cálculo) e D-170 (reler AGI a cada atualização da regeneração natural).

## Pendências e escopo

- Definir condições reproduzíveis da medição, fontes e equivalência de velocidade atual com AGI, interrupções/pausas, repetição e análise das medições; **nenhuma medição foi realizada nesta atividade**.
- Somente documentação; não criar testes, scripts ou alterações de código sem autorização específica.

## Complemento posterior — Rodada 65 / D-180 (2026-11-03)

**D-180 (R65-Q4A):** medir **ambos os intervalos 3→5 e 0→5** sob **condições controladas**, com regeneração natural ativa e **sem buffs, ações, recompensas instantâneas ou pausas**. O protocolo não autoriza alterar permanentemente o ATB inicial de 3/5 nem inventar resultados de medição. Valor de referência numérica de ATB só poderá ser implementado após avaliação e apresentação ao criador (D-169). Histórico preservado; sem código ou testes.
