# D-187 — Rodada 67 Q1 (1B): gerar seed própria de retarget no início do combate e registrá-la

- **Data:** 2026-11-03.
- **Área:** Combate / retarget / reprodutibilidade.
- **Origem:** aprovação expressa do criador, Rodada 67.
- **Estado:** regra aprovada, não implementada.

## Declaração literal do criador

> 1B — Gerar uma seed própria para retarget ao iniciar o combate e registrá-la para reprodução.

## Regra aprovada

- **Ao iniciar cada combate**, gerar uma **seed própria para o fluxo de RNG de desempates de retarget**, separado dos demais sorteios do combate, conforme D-186.
- **Registrar essa seed** para permitir reproduzir a sequência de desempates quando as demais entradas e a ordem dos eventos forem idênticas. Não exigir que a seed venha de outra seed geral do combate ou seja informada manualmente na partida comum.
- Para **reproduzir** um combate, a seed registrada precisa poder ser utilizada novamente; a presente escolha **não define formato de registro, mecanismo de persistência, API de replay, algoritmo de derivação ou gerador pseudoaleatório**.
- **Exemplo hipotético:** a seed própria de um combate é `84271`; registrar esse valor permite reinicializar a sequência de RNG de retarget em reprodução, desde que entradas e ordem de consumo sejam equivalentes. **84271 não é seed real nem número fixado para o Crawlmon.**
- Preservar D-166 (sorteio entre empatados), D-171 (tolerância horizontal inclusiva 0,01), D-181 (posições lógicas), D-186 (isolamento) e as futuras especificações D-188/D-189 de ordem de candidatos e consumo de RNG.

## Pendências e escopo

- Escolha do PRNG e formato de seed, serialização, integridade de replay e tratamento de dois eventos simultâneos permanecem pendentes.
- Somente documentação, sem código, testes, cenas ou sistema de replay implementado.
