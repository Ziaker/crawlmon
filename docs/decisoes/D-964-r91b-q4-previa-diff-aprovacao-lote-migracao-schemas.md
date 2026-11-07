# D-964 — Rodada 91B Q4 (4A): prévia por Resource e aprovação explícita do lote de migração de schema

- **Data:** 2026-11-07.
- **Área:** Engine de Moves / evolução dos schemas / migração controlada.
- **Origem:** resposta **“Tudo A continue”**, aprovando a alternativa A da questão 4 da Rodada 91B.
- **Estado:** processo aprovado; **nenhuma conversão executada**.

## Declaração literal

> Tudo A continue

## Alternativa 4A aprovada (texto apresentado ao criador)

> Gerar uma prévia de migração de esquema com diferenças por Resource, permitir aprovação explícita do lote e só então produzir versões migradas separadas, preservando originais e revalidando os pares.

## Regra aprovada

- Antes de converter schemas de Resources de Moves, **gerar prévia de migração mostrando diferenças por Resource**, para que o criador possa **aprovar explicitamente o lote** abrangido.
- **Somente após a aprovação específica** produzir **versões migradas separadas** dos Resources afetados, **preservando todos os originais**.
- **Revalidar os pares mecânico/visual** migrados, incluindo identidade estável, variantes, gatilhos e compatibilidade do schema, conforme D-349/D-955/D-957/D-960. Não declarar migração concluída por uma simples cópia ou transformação sem verificação.
- Preservar D-343 (arquivos separados), D-342 (migração gradual de execução de Moves, distinta da migração de schemas), D-235 (neutralidade quanto à espécie/lado) e D-351 (testes de equivalência e integração pertinentes).
- **Exemplo não normativo:** cinquenta Resources podem receber uma prévia individual de alterações; se o conjunto for aprovado explicitamente, podem ser geradas novas versões separadas e validadas. A decisão **não aprova** a conversão de cinquenta arquivos reais nem novos valores padrão.

## Limites e pendências

- **Não definidos:** ferramenta de migração, formato do diff, segmentação técnica dos lotes, alcance de aprovação quando houver conflitos entre Resources, critérios específicos de rollback, versão exata do schema, nomes/caminhos ou política de publicação das cópias. Não executar conversões nem gravar alterações por aprovação genérica da arquitetura.
- **Somente documentação; nenhum código, Resource, Move, VFX, teste ou arquivo de dados executável modificado.**
