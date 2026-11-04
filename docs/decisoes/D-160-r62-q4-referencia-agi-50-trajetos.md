# D-160 — Rodada 62 Q4 (4A): AGI de referência para trajeto fixada em 50

- **Data:** 2026-11-03
- **Área:** Combate / tempo de deslocamento / calibração AGI
- **Origem:** resposta expressa do criador, Rodada 62 Q4
- **Estado:** decisão de design aprovada; não implementada nesta atividade

## Declaração literal do criador

> 4A — Adotar AGI 50 como referência numérica comum para o tempo dos trajetos.

## Regra aprovada

- O valor numérico de **AGI de referência para duração do trajeto é 50**, **comum a todas as espécies** de Pokémon (D-136).
- Continuar usando **uma única AGI efetiva por Pokémon**, mas com referência de ATB independente (D-145). **O número 50 se aplica apenas ao subsistema de trajeto.**
- Com a relação inversa da D-136, mínimo de AGI de cálculo 1 da D-140, ordem AGI antes dos passos da D-133 e piso temporal da D-018, a expressão documental para Moves com trajeto é:
  `T_trajeto = max(0,25 s, T_base_do_Move × (50 / max(1, AGI_efetiva)) − 0,10 s × (passo_atacante + passo_alvo))`.
- O **tempo-base é próprio de cada ficha de Move**, e os efeitos que modificam AGI entram na AGI efetiva quando o tempo é calculado (D-119/D-154/D-155/D-157).
- **Exemplo ilustrativo da questão, antes dos passos e piso:** Move com tempo-base de 1,0 s; AGI efetiva 50 → 1,0 s; AGI efetiva 100 → 0,5 s. A posição pode alterar o resultado segundo D-018; não fixar tempos individuais de Moves neste exemplo.

## Conciliação

- D-126 preserva a intenção de calibrar ritmos. A escolha 4A fornece um número previamente pendente, sem afirmar que tenha sido testado no jogo.
- **D-161 (R62-Q5B)**: a referência numérica de AGI para ATB **continua pendente** de avaliação de ritmo e não recebe automaticamente 50.
- Esta escolha **não altera** velocidade de projéteis ou ondas AoE, fórmula de regeneração ATB ou custos de ações.
- Arredondamento, precisão de cálculo e eventual apresentação na interface não foram decididos nesta questão.

## Escopo

Somente documentação. Nenhum código, ficha de Move, cena, VFX, asset ou teste alterado.
