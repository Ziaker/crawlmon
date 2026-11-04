# D-200 — Rodada 70 Q1 (1A): IDs por slots da equipe do protagonista, seguidos pelos inimigos

- **Data:** 2026-11-04.
- **Área:** Combate / identificação estável / retarget e RNG reproduzível.
- **Origem:** escolha expressa do criador na Rodada 70.
- **Estado:** regra de design aprovada, ainda não implementada nesta atividade.

## Declaração literal do criador

> 1A — Atribuir sequencialmente pelos slots da equipe do protagonista, depois pelos slots da equipe inimiga, na composição inicial da batalha.

## Regra aprovada

- Na **composição inicial de cada combate**, atribuir os IDs estáveis **sequencialmente**, primeiro segundo a **ordem dos slots da equipe do protagonista** e depois segundo a **ordem dos slots da equipe inimiga**.
- Esta escolha concretiza a ordem antes pendente da **D-196**, sem revogar as regras de IDs **únicos por combate**, atribuídos no início e **não renumerados durante a batalha**. Não reutilizar IDs nem alterar seu valor automaticamente quando outro combatente morrer.
- Os IDs servem à **D-188** (ordem estável da lista de candidatos empatados antes do sorteio) e à **D-192** (ordem dos eventos simultâneos de retarget pelo ID do atacante), sem transformar o sorteio de alvo em seleção determinística por ID (D-166/D-186–D-189).
- Exemplo puramente ilustrativo: Gible e Abra ocupam slots 1 e 2 da equipe do protagonista; Pancham e outro inimigo ocupam slots 1 e 2 dos inimigos. Uma sequência de IDs `1, 2, 3, 4` **exemplifica a ordenação das equipes e slots**, mas **não fixa o número inicial nem o formato concreto do ID**.
- Preservar **D-095:** eliminar ambas as equipes no mesmo instante lógico ainda produz empate; a ordem dos IDs não atribui prioridade de vitória.

## Limites e pendências

- Não foram especificados o número inicial ou representação técnica dos IDs, tratamento de **combatentes que entrem somente depois da composição inicial**, persistência no replay, nem critério de ordem entre dois retargets simultâneos do mesmo atacante.
- Nenhum código, teste, cena, dado de personagem, asset ou VFX modificado; registro documental somente.
