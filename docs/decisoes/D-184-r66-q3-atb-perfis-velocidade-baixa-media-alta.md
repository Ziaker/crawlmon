# D-184 — Rodada 66 Q3 (3B): calibrar ATB com perfis reais de velocidade baixa, média e alta

- **Data:** 2026-11-03.
- **Área:** Combate / ATB / amostragem para calibração.
- **Origem:** aprovação expressa do criador, Rodada 66.
- **Estado:** protocolo aprovado; perfis concretos e medições ainda não determinados.

## Declaração literal do criador

> 3B — Medir combatentes representativos das faixas baixa, intermediária e alta de velocidade existentes no código, com as mesmas condições controladas.

## Regra aprovada

- Na calibração da referência de AGI para ATB baseada no ritmo atualmente existente (D-169), selecionar **combatentes representativos das faixas baixa, intermediária e alta de velocidade efetivamente existentes no código**.
- Medir **cada perfil representativo** nos **dois intervalos de regeneração natural, 3→5 e 0→5 blocos** (D-175), sob as **mesmas condições controladas** (D-180): regeneração natural ativa, sem buffs, ações, recompensas instantâneas ou pausas.
- A seleção das faixas e combatentes exige **inspeção dos valores reais de velocidade**; não fixar limiares numéricos hipotéticos ou inventar nomes de representantes. Esta decisão não iguala `base_speed` de código à futura AGI permanente sem calibração.
- **Exemplo meramente ilustrativo:** perfis fictícios de 0,6, 1,0 e 1,4 blocos/s poderiam representar três faixas em um jogo, mas **não foram verificados como velocidades presentes no Crawlmon**.
- **D-185 (R66-Q4B)** fixa repetição e consolidação de tempos; **D-169** continua exigindo apresentar a referência numérica resultante ao criador **antes de implementar**.

## Pendências e escopo

- Identificar combatentes e velocidades realmente disponíveis no código, comprovar representatividade das faixas e efetuar as medições em ambiente controlado. Não houve gameplay ou medição nesta atividade.
- Apenas documentação; nenhum código, cena, arquivo de testes ou parâmetros de ATB alterado.
