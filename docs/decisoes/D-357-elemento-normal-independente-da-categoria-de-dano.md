# D-357 — Elemento Normal separado da categoria de dano e da execução

- **Data:** 2026-11-06.
- **Área:** Sistema elemental / fichas de Moves.
- **Origem:** escolha explícita da alternativa A no questionário da Drain Spear.
- **Estado:** design aprovado; enumeração, migração e tabela de afinidades pendentes.

## Declarações literais do criador

> eu nao sei se e realmente necessario haver 2 elementos, um que seja fisico e um que seja magico, entao normal foi criado pra nao ter que haver necessidade de criar isso, ja que nao se enquadram nos elementos estabelecidos, mesmo que Almighty ainda nao seja considerado um ja que estamos usando referencias de smt e pokemon, o que me recomenda?
>
> Crawlmon Drain Spear — confirmações: elemento A; mid-range A; badges A.

## Alternativa A aceita

> Adotar Normal como elemento neutro, separado da categoria física/mágica (recomendado).

## Regra aprovada

- **Normal** é um **elemento neutro próprio**, **distinto da categoria de dano** e do **modo de execução** do Move.
- Assim, Drain Spear pode ser **Normal** (elemento), provocar **dano mágico por MAG/SPI** (categoria e atributos) e executar uma **estocada de contato** (modo), sem exigir elementos distintos chamados «Físico» e «Mágico».
- A escolha é conceitual e **não homologa ainda a tabela de vantagens, fraquezas, Null, Repel, Drain ou comportamento especial de Normal**. Também **não cria Almighty** nem estabelece que Normal seja sinônimo de Almighty.
- A `main` consultada ainda declara `Element.Type.FISICO` em `scripts/data/element.gd` e não declara `Element.Type.NORMAL`. Preservar os elementos e o comportamento legado até receber autorização de migração; **não renomear em massa ou reinterpretar Moves existentes por inferência**.
- Preservar D-122/D-244/D-258: MAG escala dano mágico e SPI faz mitigação natural mágica; o tipo de execução não converte a categoria de dano.

## Pendências

- Política de migração de `FISICO` legado para `NORMAL` ou eventual convivência temporária, sem alterar o significado dos Moves existentes sem decisão própria.
- Efeitos elementais concretos de Normal e eventual lugar de Almighty.
- Nenhum código, enum, ficha operacional, IA ou tabela de afinidades alterado.

## Relações

D-001, D-003, D-061, D-122, D-235, D-244, D-258, D-276, D-352 e D-356.
