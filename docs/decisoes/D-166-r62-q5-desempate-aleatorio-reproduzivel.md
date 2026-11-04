# D-166 — Rodada 62 Q5 (5A, versão prevalente): sorteio reproduzível entre alvos empatados

- Data: 2026-11-03.
- Origem: resposta expressa do criador e confirmação de prevalência desta versão da Rodada 62.
- Estado: decisão aprovada, não implementada.

## Declaração literal

> 5A — Sortear entre os alvos empatados usando a aleatoriedade reproduzível do combate.

## Regra vigente

- Ao redirecionar um ataque durante **WINDUP** quando o alvo morre (D-108), escolher o **inimigo vivo mais próximo**.
- Se **dois ou mais candidatos vivos estiverem igualmente próximos**, **sortear entre os empatados usando a aleatoriedade reproduzível do combate**. Não sortear entre candidatos mais distantes.
- Esta escolha **substitui expressamente o desempate por identificador estável de combate da D-158**, publicado na versão divergente; a D-158 é preservada como histórico.
- Exemplo ilustrativo: Abra e Pancham, ambos vivos e a 4 m do atacante, empatam como mais próximos; sorteio reproduzível determina qual será selecionado, sem preferência fixa por ID.
- Para cada troca de alvo efetiva durante WINDUP, manter um único recálculo de duração (D-155); preservar fim definitivo de combate (D-105/D-107), regra de investida (D-113), projéteis e AoE.
- Reprodutibilidade do sorteio **não significa** escolher o mesmo alvo sempre nem impor ordem fixa por ID.

## Pendências e escopo

- Definir futuramente tolerância geométrica de igualdade, seed, algoritmo e ordem de consumo do RNG; nenhuma escolha técnica foi presumida.
- Documentação somente; nenhum código, teste, cena ou VFX alterado.

## Complemento posterior — Rodada 63 / D-171 (2026-11-03)

**D-171 (R63-Q5B):** considerar empate de proximidade quando a **diferença de distâncias for até 0,01 unidade da arena, inclusive o limite**. O grupo sorteável continua sendo o conjunto de **inimigos vivos mais próximos dentro dessa tolerância**, mantendo **sorteio reproduzível**, não desempate por ID. Critério geométrico concreto de distância, seed e ordem de sorteios permanecem por definir. Preservado o histórico; sem código.

## Complemento posterior — Rodada 66 / D-186 (2026-11-03)

**D-186 (R66-Q5A)** define que o sorteio reproduzível de desempates em **retarget durante WINDUP** usa **um fluxo próprio de números pseudoaleatórios, separado dos demais sorteios do combate**. Rolagens de crítico, esquiva, status e outras mecânicas não avançam esse fluxo de retarget. Permanecem pendentes seed, algoritmo e ordem de consumo do fluxo; não declarar RNG implementado. Preservar a D-171 (tolerância 0,01), D-176/D-181 (distância horizontal entre posições lógicas) e o histórico de substituição da D-158.
