# D-267 — Rodada 82 Q4 (4A): elegibilidade e chance antes da matriz de incompatibilidades

- **Data:** 2026-11-04.
- **Área:** Combate / status probabilísticos / ordem de resolução / matriz de prioridades.
- **Origem:** decisão expressa do criador na Rodada 82.
- **Estado:** ordem de resolução aprovada; matriz e pares concretos ainda pendentes; não implementada.

## Declaração literal do criador

> 4A — Resolver primeiro elegibilidade e chance de aplicação; somente após o sucesso efetivo consultar a matriz, eliminando o status de menor prioridade.

## Regra aprovada

- Para status de **Moves diferentes** potencialmente incompatíveis, **resolver primeiro a elegibilidade da tentativa de aplicação** (acerto, sobrevivência, número de tentativas etc., conforme regras já aprovadas) e a **chance final de aplicação**; **somente após sucesso efetivo de aplicação consultar a matriz aprovada por pares de status incompatíveis** (D-239/D-243/D-253), se houver conflito aplicável.
- Apenas diante de uma **entrada concreta da matriz expressamente aprovada** e de **sucesso efetivo**, aplicar **D-257**: eliminar o status de menor prioridade, **removendo-o caso já esteja ativo** ou **impedindo sua aplicação caso seja o novo efeito**, sem retorno posterior ao encerrar o vencedor.
- Se o status novo **falhar na elegibilidade ou na chance**, **não eliminar outro status ativo com fundamento nessa tentativa malsucedida**. A ordem da matriz não é filtro prévio que dispensa o sorteio de chance só porque o novo status poderia perder.
- Preservar D-143/D-234: chance final **exatamente 0% falha e 100% tem sucesso sem consumir RNG**; entre os extremos, preservar o **fluxo próprio de RNG de status** com seed registrada (D-227), consumo ordenado por ID do alvo e depois atacante/declaração/ocorrência (D-219/D-223), e a ordem de efeitos declarados na ficha (D-213), sem converter **ordem de RNG** em prioridade lógica entre status.
- **Exemplo hipotético sem declarar incompatibilidade real:** X está ativo e um Move diferente tenta aplicar Y com 20% de chance final válida. **Se Y falhar na rolagem, X permanece**. **Se Y tiver sucesso** e **uma entrada futura aprovada da matriz** declarar X/Y incompatíveis e prioritizar Y, remove-se X; se prioritizar X, impede-se a aplicação de Y. **Nem a chance de 20% nem a precedência X/Y foram aprovadas para qualquer Move real.**
- Preservar D-095 (KO simultâneo) e D-235 (independência de Move, personagem e lado); para status incompatíveis **na mesma ficha**, preservar D-215/D-217 e não ampliar esta regra automaticamente para casos distintos sem aprovação.

## Pendências e escopo

- **Não há nenhum par real de status ou prioridade concreta aprovado na matriz.** Permanecem em aberto o tratamento da ausência de entrada, critérios concretos de incompatibilidade, ordem de comparação de múltiplos sucessos contra diversos status já ativos e detalhes de remoção/reaplicação além de D-257.
- A regra não altera fórmula de chance, escala de LUK, critérios de acerto/elegibilidade, efeitos declarados garantidos nem consumo de RNG fora do status.
- Somente documentação; nenhum código, teste, Move, ficha, IA, cena, asset ou VFX modificado.
