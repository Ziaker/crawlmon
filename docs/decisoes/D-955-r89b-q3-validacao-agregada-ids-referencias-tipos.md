# D-955 — Rodada 89B Q3 (3A): rejeição agregada de IDs duplicados, referências e parâmetros inválidos

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / validação de Resources / diagnóstico de configuração.
- **Origem:** aprovação expressa da Rodada 89B, questão 3.
- **Estado:** política de validação documental aprovada; validador não implementado.

## Declaração literal do criador

> 3A — Rejeitar a configuração que contenha IDs de efeitos duplicados no mesmo escopo, referências inválidas ou parâmetros incompatíveis com seus tipos, relatando conjuntamente os erros detectados sem corrigi-los automaticamente.

## Regra aprovada

- **Rejeitar configuração** de Move/variante com **IDs de efeito duplicados no mesmo escopo**, **referências inválidas** ou **parâmetros incompatíveis com seus tipos**.
- **Relatar conjuntamente todos os erros detectados na validação**, sem corrigir, renumerar ou substituir dados automaticamente. Não mascarar erros posteriores por um primeiro erro que já seja conhecido.
- Preservar D-373 (IDs estáveis por entrada), D-953 (âncora inexistente invalida variante), D-374 (condições tipadas) e D-349 (vincular Resources e validar variantes/gatilhos). D-255/D-265 já exigem diagnóstico conjunto de omissões de bloqueio **específicas anteriormente aprovadas**; este registro trata adicionalmente de **integridade estrutural de dados** e não altera as causas anteriores.
- **Exemplo abstrato:** dois efeitos de mesmo ID no mesmo escopo e outro com referência a efeito ausente devem ter **ambas as causas identificadas na mesma validação**, sem renomear IDs arbitrariamente.
- A **rejeição de configuração** não atribui automaticamente novo consumo de oportunidade/ATB/MP nem define comportamento específico da IA/UI além do que já foi aprovado. Para recursos visuais ausentes ou inválidos, preservar D-350/D-376, sem fallback silencioso após migração.

## Pendências e limitações

- **Não definidos:** o escopo técnico exato em que IDs devem ser únicos, lista exaustiva de tipos/campos, momento exato da validação, formato e ordenação dos diagnósticos, tratamento de cascatas de erros e recuperação/revalidação. Não escolher políticas de correção implícita.
- **Somente documentação; nenhum código, Resource, Move, teste, IA ou VFX modificado.**
