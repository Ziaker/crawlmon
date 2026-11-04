# D-192 — Rodada 68 Q1 (1A): ordenar sorteios simultâneos de retarget pelo ID estável do atacante

- **Data:** 2026-11-04.
- **Área:** Combate / retarget / reprodutibilidade de RNG.
- **Origem:** decisão expressa do criador na Rodada 68, aceitando a recomendação.
- **Estado:** regra de design aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 1A — Ordenar eventos simultâneos pelo ID estável do atacante antes de consumir o RNG exclusivo.

## Regra aprovada

- Se **dois ou mais eventos de retarget simultâneos** precisarem consumir o **fluxo exclusivo de RNG de retarget**, ordenar esses eventos pelo **identificador estável do atacante dentro do combate**, antes de consumir os sorteios.
- Exemplo ilustrativo: Gible atacante ID **2** e Abra atacante ID **5** sofrem retarget no mesmo instante lógico, ambos com pelo menos dois candidatos empatados; o evento de Gible consome RNG primeiro e o de Abra em seguida. IDs e resultados são fictícios.
- Isto complementa **D-188**, que ordena os **candidatos empatados dentro de cada evento**, e **D-189**, que impede consumir RNG quando não há dois ou mais candidatos empatados elegíveis. A ordem por ID **não escolhe o alvo diretamente**, que continua sorteado entre os elegíveis (D-166/D-186–D-189).
- **D-095 permanece intocada:** a ordem dos sorteios não estabelece prioridade para dano, morte, desempate de vitória/derrota ou processamento de outras classes de eventos; duas equipes eliminadas no mesmo instante lógico ainda empatam.

## Limites e pendências

- Se dois eventos simultâneos vierem do **mesmo atacante**, a regra aprovada não escolhe um critério adicional de desempate entre esses eventos.
- Não define granularidade do instante lógico, criação de IDs, algoritmo do PRNG, representação da seed, quantidade de chamadas internas ou mecanismo de replay. Preservar D-171/D-176/D-181 e D-187.
- Somente registro documental. Nenhuma mudança em código, testes, cenas, fichas, assets ou VFX.
