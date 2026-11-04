# D-222 — Rodada 75 Q3 (3A): preservar índices reservados de ocorrências canceladas

- **Data:** 2026-11-04.
- **Área:** Combate / identidade de eventos / retarget e reprodutibilidade.
- **Origem:** decisão expressa do criador na Rodada 75.
- **Estado:** regra de design aprovada; **não implementada** nesta atividade.

## Declaração literal do criador

> 3A — Preservar os índices reservados das ocorrências canceladas, sem reutilizá-los ou renumerar as restantes na mesma declaração.

## Regra aprovada

- Para índices de ocorrência atribuídos a partir do **plano determinístico na declaração de um ataque** (D-218), o cancelamento de uma ocorrência **não libera o índice para reutilização dentro da mesma declaração** e **não renumera as demais ocorrências**.
- Preservar a identidade estável de cada ocorrência até sua resolução, conforme D-214/D-218; o cancelamento não faz ocorrer o evento nem cria automaticamente novo consumo de RNG. As regras de ordenação/consumo de retarget **D-188/D-189/D-192/D-214** permanecem.
- **Exemplo apenas ilustrativo:** o plano declara `A#1`, `A#2`, `A#3`, `A#4`; após cancelar `A#2`, as ocorrências restantes conservam `#1`, `#3` e `#4`. `#2` não pode ser atribuído a outra ocorrência **dessa declaração**. Os números e nomes são fictícios, não formato de implementação.
- Essa regra de índices **não altera a lógica de derrota/empate simultâneo (D-095)**, nem atribui prioridades gerais de dano ou resolução de outros eventos.

## Limites e pendências

- Não foi aprovado o formato de serialização/replay, valor inicial de índice, política entre declarações de ataques distintas, estrutura do plano de eventos ou tratamento de ocorrências geradas dinamicamente além do plano; não inferir regras para esses casos.
- Somente documentação; nenhum código, testes, cenas, Move, asset ou VFX modificado.
