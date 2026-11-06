# D-361 — Rodada 87B Q2 (2A): efeitos tipados e ordenados com parâmetros, condições e abrangência

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / definição declarativa / interpretador mecânico.
- **Origem:** aprovação expressa da Rodada 87B, questão 2.
- **Estado:** contrato conceitual de efeitos aprovado; não implementado.

## Declaração literal do criador

> 2A — Representar cada efeito por uma entrada tipada e ordenada, com parâmetros, condições e abrangência próprios quando declarados, usando componentes genéricos reutilizáveis.

## Decisão aprovada

- Representar os efeitos de cada Move como **entradas tipadas em ordem explícita**, interpretadas por **componentes mecânicos genéricos reutilizáveis**, conforme **D-340**.
- Cada entrada descreve seus **parâmetros**, **condições** e **abrangência próprias quando a ficha as declarar**, sem impor diferenças não existentes nem preencher condições faltantes por suposição.
- Preservar **D-260** e demais decisões de M3: na falta de exceção expressa por efeito, **herdar seleção/facção/abrangência padrão da ficha**, sem criar seleção nova. Preservar ordem, elegibilidade, chances, status e resolução de efeitos conforme as decisões normativas vigentes, inclusive D-213/D-215/D-217/D-234 e D-257/D-267, sem reinterpretá-las como prioridade nova.
- Preservar **D-348**: o plano mecânico é autoridade de eventos e tempos, e a lista de efeitos não transfere autoridade mecânica ao VFX.
- **Exemplo hipotético:** um Move pode declarar uma entrada de dano e uma entrada distinta de tentativa de status. A ordem, as condições e a chance da ficha determinam o comportamento. O exemplo não define um Move novo ou prioridade não homologada.

## Pendências e limites

- Tipos concretos de operadores, seu conjunto exaustivo, validação dos parâmetros por tipo, expressão das condições, avaliação de dependências e representação de listas/ramos continuam pendentes de aprovação. Não inferir uma linguagem de scripts, grafo, ordem adicional ou regra especial de composição.
- Nenhum código, Resource, interpretador, Move, VFX, asset ou teste implementado.
