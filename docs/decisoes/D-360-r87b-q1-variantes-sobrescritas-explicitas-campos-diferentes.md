# D-360 — Rodada 87B Q1 (1A): variantes com substituições explícitas de parâmetros comuns

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / Resource mecânico / variantes / dados compartilhados.
- **Origem:** aprovação expressa da Rodada 87B, questão 1.
- **Estado:** contrato conceitual aprovado; não implementado.

## Declaração literal do criador

> 1A — Manter parâmetros comuns na definição principal do Move e representar cada variante somente com substituições explícitas dos campos que realmente mudam.

## Decisão aprovada

- A definição principal de **cada Move** mantém os **parâmetros compartilhados**. Cada variante que exista expressamente declara **somente substituições explícitas para os campos que realmente mudam**, mantendo os campos não substituídos conforme a definição comum.
- Preservar **D-333**: **uma ficha lógica única por Move**, com blocos de variantes somente onde existirem diferenças efetivas de efeitos, valores, alvos e visuais. Preservar **D-343/D-349**: recursos executáveis mecânico e visual em arquivos distintos, relacionados pelo mesmo ID estável, validando também as variantes e gatilhos correspondentes.
- **Exemplo ilustrativo:** Splitter Flames pode manter elementos realmente comuns no Move e registrar nos blocos de um e dois alvos apenas números, condições ou visuais que já sejam distintos nas respectivas especificações aprovadas. **Nenhuma variante, valor ou regra adicional é aprovada por este exemplo.**
- Substituições de parâmetros não autorizam mudar efeitos, tempos, custos, seleção ou condição sem decisão individual do Move; respeitar **D-244–D-249, D-258–D-263, D-340 e D-348**.

## Pendências e limites

- Não foram escolhidos o esquema de campos, o mecanismo técnico de mesclagem, operações de substituição de listas, regras para tipos incompatíveis, IDs concretos de variantes ou arquivos/caminhos físicos. Essas escolhas exigem nova aprovação.
- Somente documentação; nenhum Resource, código, Move, VFX, cena ou teste criado/alterado.
