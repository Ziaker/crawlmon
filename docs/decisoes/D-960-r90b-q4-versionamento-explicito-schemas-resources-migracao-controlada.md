# D-960 — Rodada 90B Q4 (4A): versionamento explícito de Resources e migração controlada sem sobrescrever originais

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / contratos de dados / compatibilidade de esquemas / migração.
- **Origem:** resposta expressa do criador à Rodada 90B, questão 4.
- **Estado:** requisito de versionamento aprovado; esquemas e migrador não implementados.

## Declaração literal do criador

> 4A — Versionar explicitamente os esquemas dos Resources mecânico e visual, detectar incompatibilidades e exigir migração de dados controlada e verificável, sem reescrever automaticamente fichas originais.

## Regra aprovada

- **Versionar explicitamente os esquemas** dos **Resources mecânico e visual** da engine de Moves, permitindo identificar a versão sob a qual cada dado foi definido.
- **Detectar incompatibilidades** entre dados/versões e o contrato vigente. Quando uma versão necessitar conversão, exigir uma **migração controlada, verificável e rastreável**, sem **reescrever automaticamente os arquivos originais das fichas**.
- Preservar **D-339/D-343** (Resources separados por Move), **D-349** (vínculos e variantes), **D-955** (não autocorrigir erros de validação), **D-957** (revalidar depois de mudança/recarga) e **D-342/D-351** (migração de Moves com equivalência e testes). **Migração de esquema de dados** e **migração de execução do Move legado à nova engine** são operações distintas.
- **Exemplo ilustrativo:** um Resource visual antigo que não possua um campo obrigatório da versão atual deve produzir incompatibilidade identificável, até que uma conversão controlada e validada seja autorizada. Não preencher silenciosamente valores de VFX.
- Preservar **D-235**: diferenças de formato não justificam arquivos de comportamento exclusivos por personagem ou lado.

## Limites e pendências

- **Não definidos:** formato de versão, compatibilidade retroativa, tolerância a versões antigas, localização do registro, ferramenta de migração, mecanismo de cópia/backup/diff, escopo de aprovação de cada conversão, procedimento de testes e política de distribuição/rollback. Não impor autocorreção nem refatoração do projeto.
- A decisão **não autoriza executar conversões nem criar classes, scripts ou Resources**.
- **Somente documentação; nenhum código, Resource, Move, VFX, teste, cena ou asset modificado.**
