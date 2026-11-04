# D-188 — Rodada 67 Q2 (2A): ordenar candidatos empatados por ID estável antes do sorteio

- **Data:** 2026-11-03.
- **Área:** Combate / retarget / entrada reprodutível do RNG.
- **Origem:** aprovação expressa do criador, Rodada 67.
- **Estado:** regra aprovada, sem implementação.

## Declaração literal do criador

> 2A — Ordenar os candidatos empatados por identificador estável do combatente dentro da batalha antes do sorteio.

## Regra aprovada

- Quando **dois ou mais inimigos vivos forem candidatos empatados** pela menor distância horizontal com tolerância **inclusiva de até 0,01 unidade da arena** (D-171/D-176/D-181), **ordenar esses candidatos por identificador estável do combatente dentro da batalha antes do sorteio**.
- Essa ordem é **somente para estabilizar a lista apresentada ao RNG exclusivo da D-186**, não para determinar diretamente o vencedor. **Não restaurar a regra histórica de escolher o menor ID da D-158**, expressamente substituída pela D-166.
- **Exemplo hipotético:** candidatos empatados com IDs estáveis `8, 3, 5` são oferecidos ao sorteio na ordem `3, 5, 8`, mas cada candidato elegível continua sujeito à escolha pseudoaleatória; o ID mais baixo **não é vencedor automático**.
- O ID deve ser **estável durante o combate** e distinguir os participantes da batalha. O esquema de criação, persistência, comparação, cobertura de reinicializações e interação com replays **não foi escolhido aqui**.
- Preservar D-187 (seed própria registrada), D-189 (não consumir RNG quando não há empate), D-108 (retarget durante WINDUP) e D-155 (recálculo de duração por troca efetiva).

## Pendências e escopo

- Verificar no repositório a disponibilidade de um identificador lógico estável adequado, ou especificá-lo antes de implementar; nenhuma arquitetura de IDs foi aprovada.
- Somente documentação; nenhum código ou RNG alterado.
