# D-350 — Rodada 86B Q3 (3A): configuração visual ausente/incompatível impede aprovar a migração

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / validação pré-migração / incompletude.
- **Origem:** aprovação expressa na Rodada 86B, questão 3.
- **Estado:** critério de aprovação de migração homologado; não implementado.

## Declaração literal do criador

> 3A — Considerar incompleta a configuração do Move com arquivo visual obrigatório ausente ou referências incompatíveis, impedindo aprovar sua migração até corrigir o problema.

## Regra aprovada

- Considerar **incompleta a configuração** de um Move quando o **Resource visual obrigatório estiver ausente** ou houver **incompatibilidade nas referências necessárias** (identidade do Move, variantes ou gatilhos, conforme D-349).
- **Não aprovar a migração desse Move** para a nova engine até que o problema seja identificado e **corrigido e validado**. A comunicação de diagnóstico deve identificar a ausência ou incompatibilidade encontrada, sem ocultar a causa.
- **Exemplo hipotético:** um recurso mecânico de Fire Bullet está presente, mas seu visual referencia um gatilho de impacto que não corresponde ao contrato mecânico. A migração de Fire Bullet **não é aprovada** até correção e nova validação; nenhum evento mecânico deve ser inventado para fazer o VFX parecer válido.
- Preservar **D-342** (migração incremental e equivalência), **D-343** (dois arquivos por Move) e **D-348/D-349** (autoridade mecânica e vínculo explícito), além de **D-235** (independência de atacante/lado).

## Limite fundamental e pendências

- Esta escolha aprova um **bloqueio de aprovação da migração**, **não uma nova regra de bloqueio da execução durante o combate** nem substituição automática por VFX genérico ou uso da mecânica sem visual. O tratamento em runtime para casos não migrados, falhas após aprovação, builds de produção e comportamento de fallback **continua sem aprovação**.
- Ainda não estão definidos canal/formato de diagnóstico, política de dependências opcionais, exclusões visuais específicas e resposta operacional a recursos ausentes depois da migração.
- Somente documentação; nenhum código, Resource, Move, teste, VFX ou cena modificado.
