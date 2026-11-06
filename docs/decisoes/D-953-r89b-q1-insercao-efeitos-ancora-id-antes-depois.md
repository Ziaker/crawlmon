# D-953 — Rodada 89B Q1 (1A): inserção de efeitos em variantes por ID âncora e posição explícita

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / Resources de efeitos / mesclagem de variantes.
- **Origem:** aprovação expressa da Rodada 89B, questão 1.
- **Estado:** contrato documental aprovado; implementação, classes e validação executável pendentes.

## Declaração literal do criador

> 1A — Inserir efeitos em variantes por referência explícita ao ID estável de outro efeito, indicando antes ou depois; referências inexistentes impedem validar a variante, sem reordenar os demais efeitos.

## Regra aprovada

- Ao **acrescentar um efeito em uma variante**, declarar uma **referência explícita ao ID estável de outro efeito** da lista efetiva e indicar se a inserção ocorre **antes** ou **depois** da entrada referenciada.
- **Referências a efeitos inexistentes impedem validar a variante**; não inventar posição padrão nem corrigir automaticamente a referência ausente.
- **Preservar a ordem relativa dos demais efeitos** não modificados. O contrato complementa D-373 (identidades estáveis e operações explícitas de adicionar/substituir/remover efeitos), D-360 (variantes somente com diferenças reais) e D-361 (ordem explícita dos efeitos).
- **Exemplo abstrato, não conteúdo novo de Move:** lista A, B, C; variante acrescenta D *antes do ID de B*. Resultado A, D, B, C, sem reordenar A, B ou C. IDs e efeitos são ilustrativos.
- As referências de **efeitos da ficha** não substituem IDs de Move, índices de **ocorrências mecânicas reservadas** (D-218/D-222/D-226) ou IDs de **diagnóstico de excedentes** (D-256/D-266). Preservar D-235 (independência de personagem/lado) e D-349 (validação de variantes/gatilhos).

## Pendências e limitações

- **Não definidos:** formato dos IDs e referências, ordenação quando múltiplos acréscimos apontam para a mesma âncora, ancoragem relativa a efeito removido pela mesma variante, ciclos/conflitos de operações, esquema do Resource e algoritmo de mesclagem. Tais casos permanecem pendentes; não resolver por inferência.
- **Somente documentação; nenhum código, Resource, Move, teste, cena ou VFX alterado.**
