# D-349 — Rodada 86B Q2 (2A): vínculo explícito por ID e validação de variantes e gatilhos

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / recursos mecânico e visual / validação de integridade.
- **Origem:** aprovação expressa na Rodada 86B, questão 2.
- **Estado:** contrato de integridade aprovado; não implementado.

## Declaração literal do criador

> 2A — Vincular os Resources mecânico e visual pelo ID estável do Move e validar também variantes e gatilhos referenciados.

## Regra aprovada

- Os **Resources mecânico e visual próprios por Move** (D-339/D-343) devem ter **vínculo explícito pelo identificador estável do mesmo Move**, mantendo **uma única ficha lógica** conforme D-333.
- A **validação de integridade** deve conferir **a identidade do Move**, a correspondência das **variantes declaradas** e a existência/compatibilidade dos **gatilhos referenciados** entre a definição mecânica e a visual. Não confiar apenas em igualdade de nomes de arquivos como substituto da identidade aprovada.
- **Exemplo hipotético:** a definição de Splitter Flames possui modos de um e dois alvos; o recurso visual referente à variante de dois alvos não pode apontar para um gatilho inexistente ou variante de outro Move e ainda passar como íntegro. Não criar ou alterar variantes concretas nesta decisão.
- Preservar **D-348**: os gatilhos visuais seguem marcos do plano mecânico. Preservar **D-235/D-334/D-338**: validação não depende de espécie, lado, pose fixa ou modelo específico. Preservar **D-342/D-343**: o vínculo íntegro é necessário à avaliação de equivalência durante a migração.

## Pendências e limites

- **Não foram aprovados** nomes físicos, diretórios, esquema dos Resources, representação de ID, identificadores das variantes/gatilhos, algoritmo/estágio preciso de validação, tolerância de versionamento nem política de reimportação.
- A D-349 **não autoriza construir catálogo, arquivo-manifesto ou mecanismo de resolução de dependências sem decisão posterior**, além do vínculo explícito exigido.
- Somente documentação, sem implementar Resource, alterar Move, código, HUD, VFX ou testes.
