# D-191 — Rodada 67 Q5 (5C): registrar tempo simulado e tempo real separadamente nas medições ATB

- **Data:** 2026-11-03.
- **Área:** Combate / ATB / instrumentação de medição.
- **Origem:** aprovação expressa do criador, Rodada 67.
- **Estado:** requisito de registro aprovado; não implementado e sem medições.

## Declaração literal do criador

> 5C — Registrar ambos, tempo simulado e tempo real, de maneira separada para diagnosticar discrepâncias.

## Regra aprovada

- Em **cada medição controlada** de regeneração natural de ATB prevista em D-175/D-180/D-184/D-185, registrar **ambos os tempos**: **tempo simulado** (acumulado pelo avanço lógico do combate) e **tempo real transcorrido**, **separadamente**.
- A finalidade é **diagnosticar diferenças** entre o ritmo lógico e o relógio de execução. **Não substituir um pelo outro, misturá-los ou tratar divergências como mudança de regra sem análise**.
- As cinco medições por intervalo e combatente (D-185) continuam obrigatórias. As **seis combinações de perfis × intervalos** permanecem separadas (D-190); quando consolidar resultados, manter distinguíveis os valores de cada tipo de tempo, evitando mesclar observações de relógios diferentes.
- **Exemplo hipotético:** uma execução acumula `2,00 s` simulados enquanto o relógio real marca `2,08 s`. **Não são valores medidos do Crawlmon**; ambos devem ser registrados como campos distintos da mesma observação.
- Esta decisão **não fixa** relógio específico, API de instrumentação, granularidade temporal, política de tempo de renderização, mecanismo de captura ou tolerância aceitável entre os relógios; não autoriza alterar a temporização do motor.
- Preservar as condições controladas de D-180, os dois intervalos da D-175 e a obrigação de não propor a referência ATB antes de conversão verificável da D-190.

## Pendências e escopo

- Definir como observar tecnicamente os dois relógios, preservando a execução sem interferências e a rastreabilidade por perfil/intervalo/repetição.
- Somente documentação; nenhum código, teste, medição ou integração implementada.
