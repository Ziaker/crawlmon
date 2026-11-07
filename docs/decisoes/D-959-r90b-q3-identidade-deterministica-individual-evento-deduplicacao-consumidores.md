# D-959 — Rodada 90B Q3 (3A): identidade determinística por evento e detecção de entregas repetidas

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / transmissão de eventos / deduplicação / rastreabilidade.
- **Origem:** resposta expressa do criador à Rodada 90B, questão 3.
- **Estado:** contrato aprovado; não implementado.

## Declaração literal do criador

> 3A — Atribuir identidade determinística própria a cada evento emitido, distinguindo eventos múltiplos da mesma ocorrência e permitindo que consumidores detectem entregas repetidas sem reproduzir VFX ou diagnósticos duplicados.

## Regra aprovada

- **Cada evento mecânico emitido terá uma identidade própria e determinística**, distinguindo eventos diferentes até quando pertencem à **mesma ocorrência**.
- Consumidores independentes do fluxo deverão poder **reconhecer uma entrega repetida do mesmo evento** e **evitar a reprodução de VFX ou diagnósticos duplicados** por essa repetição. Eventos legitimamente distintos da mesma ocorrência **não podem ser colapsados** como duplicação.
- Preservar **D-362** (identidades de Move, declaração, ocorrência, variante quando aplicável, tipo, tempo e participantes), **D-956** (fluxo determinístico com consumidores independentes), **D-348** (autoridade mecânica), **D-363** (cancelamento/interrupção), **D-375** (resultados terminais) e as regras existentes de ordenação e RNG; não exigir RNG adicional para gerar IDs.
- **Exemplo abstrato:** uma ocorrência pode emitir eventos de disparo e impacto, cada um com identidade própria; se o transporte repetir **a mesma entrega de impacto**, o visual não deve criar um segundo impacto nem o monitoramento duplicar o registro. Não implica criar eventos em Moves reais.
- Preservar **D-235**: IDs e consumidores não assumem protagonista, espécie, time, lado ou posição.

## Limites e pendências

- **Não definidos:** composição/representação dos IDs, escopo de unicidade (batalha/declaração/global), contador ou hash, política de reentrega e armazenamento do conjunto de eventos já consumidos, reinício de batalha, replay, persistência, limites de memória e distinção técnica entre reenvio/reemissão.
- Identidade determinística **não autoriza nova ordenação mecânica** nem consumo de RNG por eventos ou diagnósticos.
- **Somente documentação; nenhum código, evento executável, Move, VFX, teste ou cena modificado.**
