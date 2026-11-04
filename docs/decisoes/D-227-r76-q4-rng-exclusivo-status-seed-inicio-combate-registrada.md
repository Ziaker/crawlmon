# D-227 — Rodada 76 Q4 (4A): RNG próprio para status, com seed gerada no início do combate e registrada

- **Data:** 2026-11-04.
- **Área:** Combate / status probabilístico / RNG determinístico / replay.
- **Origem:** escolha expressa do criador na Rodada 76.
- **Estado:** política de fluxo e seed aprovada; algoritmo, formato e implementação pendentes.

## Declaração literal do criador

> 4A — Usar fluxo de RNG próprio para status, com seed gerada no início do combate e registrada para reprodução, separado do fluxo exclusivo de retarget.

## Regra aprovada

- Os **sorteios de aplicação de status** devem usar **fluxo próprio de RNG**, com **seed própria gerada ao iniciar cada combate** e **registrada para permitir reprodução**. Esse fluxo deve permanecer **separado do RNG exclusivo de desempates de retarget** aprovado em D-186/D-187.
- Preservar **D-219/D-223**: rolagens simultâneas de status consomem esse RNG na ordem por **ID estável do alvo**; para mesmo alvo, desempatar por **ID do atacante**, **ordem da declaração** e **índice da ocorrência**. Isso determina **ordem de consumo**, não prioridade lógica entre efeitos; manter D-095 para KO simultâneo.
- Preservar **D-213** quanto à ordem de status distintos explicitamente prevista na ficha, D-210 quanto ao teto de tentativas por efeito distinto/alvo/execução e D-199/D-202/D-207/D-211 quanto a acerto, sobrevivência e momento de aplicação. Preservar as regras anteriores para efeitos garantidos e chances alteradas por LUK (D-134/D-143/D-146/D-156).
- **Exemplo puramente ilustrativo:** no início do combate são registradas separadamente uma seed do fluxo de **status** e outra do fluxo de **retarget**. Reproduzir os mesmos eventos e os respectivos consumos em ordem permite reproduzir os sorteios sem que um sorteio de retarget consuma o fluxo de status. **Nenhum valor real de seed, algoritmo ou formato de log foi aprovado.**

## Limites e pendências

- Não escolher algoritmo PRNG, dimensão/representação de seed, origem da aleatoriedade, formato de persistência, checkpoint do estado, mecanismo de replay ou política de consumo para resultados de chance **0%/100%** sem nova decisão.
- A aprovação de uma seed exclusiva para status **não equivale a uma implementação de replay completo** nem autoriza alterar outros fluxos de RNG.
- Nenhum código, testes, Moves, fichas, cenas, assets ou VFX alterado; registro documental somente.
