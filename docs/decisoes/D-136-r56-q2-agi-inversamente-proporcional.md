# D-136 — Rodada 56 Q2: Tempo de trajeto inversamente proporcional à AGI efetiva

- **Data:** 2026-11-03
- **Área:** Atributos e combate / Rodada 56.
- **Proveniência:** resposta **expressamente enviada** pelo criador, aceitando a alternativa previamente recomendada pelo assistente.
- **Estado:** decisão de design aprovada e documentada, sem implementação nesta atividade.

## Declaração literal da escolha do criador

> 2A — Como a AGI deve reduzir numericamente o tempo de deslocamento? Usar proporcionalidade inversa à AGI efetiva, com uma AGI de referência comum a todos os Pokémon. (recomendação aceita)

## Regra aprovada e compatibilidades

- O tempo de deslocamento **próprio de cada Move** é reduzido por uma **relação inversamente proporcional à AGI efetiva** do Pokémon, comparada a uma **AGI de referência comum a todas as espécies**.
- **AGI efetiva** deve refletir a Agility atual e os efeitos que aumentam AGI, preservando D-117 e D-119. A relação inversa escolhida faz a duração diminuir quando a AGI efetiva aumenta, enquanto outras condições se mantêm.
- A relação pode ser descrita simbolicamente, apenas para **AGI efetiva positiva**, como `T_apos_AGI = T_base_do_Move × (AGI_referencia / AGI_efetiva)`; **não há número aprovado** para `AGI_referencia` nem definição do tratamento de valores não positivos.
- **Manter a ordem de D-133** e o ajuste de D-018: depois da redução inversa por AGI, aplicar `−0,10 s × (passo_atacante + passo_alvo)` e respeitar o tempo mínimo de `0,25 s`.
- **Não confundir a referência comum** de AGI para o trajeto com a escolha de um número já definido: o valor de referência numérico para o ATB também continua pendente e não foi explicitamente equiparado ao da função de trajetória.
- **Exemplo ilustrativo:** com um Move de 0,80 s e AGI efetiva exatamente duas vezes a AGI de referência, a duração após a etapa de AGI será 0,40 s, **antes dos passos e piso**. Nenhum valor de atributo/tempo de espécie foi atribuído ao jogo.
- Não alterar a velocidade de projéteis, frequência de animações externas ao trajeto, mecânicas de Evade ou qualquer outro domínio sem decisão específica.

## Pormenores não definidos

- Número de AGI de referência, arredondamento, tratamento da AGI igual a zero ou não positiva, interação com debuffs de AGI e calibração de cada Move.
- **Sem alteração de código, cenas, dados de personagens, fichas de Moves, VFX ou testes** nesta atividade.
