# D-155 — Rodada 61 Q4 (4A): recalcular uma vez por troca automática de alvo no WINDUP

- **Data:** 2026-11-03.
- **Área:** Combate / retarget / duração de trajeto.
- **Origem:** escolha literal do criador na Rodada 61.
- **Estado:** decisão aprovada e registrada documentalmente; não implementada.

## Declaração literal do criador

> 4A — recalcular uma vez em cada troca automática de alvo durante o WINDUP.

## Regra aprovada

- Se o alvo de um ataque morrer durante **WINDUP**, manter a troca automática para o **inimigo vivo mais próximo** (D-108).
- Cada **evento efetivo de troca automática de alvo durante o mesmo WINDUP** autoriza **exatamente um novo cálculo** da duração do trajeto, substituindo a duração anteriormente fixada (D-149).
- A duração mais recente permanece fixa durante TRAVEL; **não** recalcular continuamente por distância ou variações de AGI enquanto o trajeto transcorre.
- Exemplo ilustrativo: ataque contra Pancham; Pancham morre no WINDUP → troca para Abra e calcula a duração novamente; Abra morre ainda durante o mesmo WINDUP → troca para Gible e calcula mais uma vez; ao entrar em TRAVEL a última duração calculada permanece fixa.
- A regra contempla um número não previamente limitado de **eventos distintos de troca durante WINDUP**, apenas enquanto houver um novo alvo elegível e a D-108 autorizar o redirecionamento. Não impõe custos extras, reinício da preparação ou mudança de alvos AoE.

## Preservações

- D-105: morte do último inimigo encerra o combate, sem exigir novo alvo.
- D-113: morte do alvo após o início da investida corpo a corpo não provoca retarget durante TRAVEL.
- D-047/D-109: projéteis já em voo conservam regras próprias.
- Empate entre adversários igualmente próximos continua sem critério geométrico aprovado.

## Escopo

Somente documentação; sem implementação.
