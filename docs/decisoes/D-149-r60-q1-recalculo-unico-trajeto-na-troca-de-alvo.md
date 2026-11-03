# D-149 — Rodada 60 Q1 (1A): recálculo único do trajeto ao trocar de alvo no wind-up

- **Data:** 2026-11-03.
- **Área:** Combate / alvo / tempo do Move.
- **Origem:** escolha expressa do criador, aceitando recomendação.
- **Estado:** regra de design aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 1A — Se o alvo morrer durante o wind-up, devemos recalcular o tempo do trajeto? Recalcular uma única vez ao trocar automaticamente de alvo, mantendo a nova duração fixa. (recomendação aceita)

## Regra aprovada

- Se o alvo morrer durante o **wind-up** e ocorrer a troca automática para o inimigo vivo mais próximo prevista em **D-108**, **recalcular uma única vez a duração do trajeto na troca de alvo**.
- A **nova duração calculada permanece fixa até o término desse trajeto**. A troca não autoriza recálculo contínuo enquanto o personagem se desloca.
- **Exceção expressa à D-148:** em condições normais vale o cálculo fixado ao iniciar o ataque; nesta situação de troca automática durante wind-up, um novo cálculo é autorizado especificamente no evento da troca.
- Preservar a ordem do cálculo de tempo do Move, AGI e posicionamento tático (D-119, D-133, D-136, D-140, D-018), sem definir fórmulas ou parâmetros adicionais.

## Limites e pendências

- Não estender a regra a projéteis já em voo, ondas AoE ou morte do alvo depois que o trajeto começou (D-109, D-037 e D-113).
- Ainda não decidido: política para sucessivas mortes e trocas dentro do mesmo wind-up; instante técnico de captura da AGI quando o alvo é trocado; critério de desempate de alvos igualmente próximos.
- Exemplo ilustrativo: Gible inicia um Move em Pancham, que morre durante o wind-up; o alvo passa a Abra em outra distância. Recalcular a duração para a troca, e mantê-la fixa no trajeto subsequente. **Os valores numéricos de duração não foram aprovados.**

## Escopo

Somente registro documental. Nenhuma alteração de código, cena, ficha de Move, VFX, teste ou configuração.
