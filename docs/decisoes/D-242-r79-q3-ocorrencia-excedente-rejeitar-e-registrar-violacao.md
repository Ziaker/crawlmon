# D-242 — Rodada 79 Q3 (3A): rejeitar ocorrência excedente e registrar violação do plano

- **Data:** 2026-11-04.
- **Área:** Combate / plano determinístico / ocorrências condicionais / diagnóstico.
- **Origem:** aprovação expressa do criador na Rodada 79.
- **Estado:** regra de rejeição aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 3A — Impedir a execução da ocorrência excedente e registrar violação do plano, preservando os eventos válidos já resolvidos.

## Regra aprovada

- Quando a execução de um Move **solicitar ocorrência condicional além do máximo explícito aprovado para esse Move** (D-233), **impedir a execução dessa ocorrência excedente** e **registrar uma violação do plano determinístico**.
- **Preservar integralmente os eventos válidos já resolvidos**: a detecção do excedente **não deve desfazer acertos, danos, status, recursos ou resultados previamente resolvidos de maneira válida**.
- **Exemplo hipotético, sem definir Move real:** um Move tem **máximo 3** ocorrências condicionais na ficha, e durante a execução tenta produzir uma **quarta**. A quarta **não ocorre**; uma violação do plano deve ser registrada, enquanto as três ocorrências já resolvidas corretamente permanecem resolvidas. **Máximo 3 é meramente ilustrativo**, não parâmetro aprovado para qualquer Move.
- Preservar D-218/D-222/D-226/D-233: o plano reserva as possíveis ocorrências na **declaração**, os índices são estáveis, não são renumerados nem reutilizados quando ocorrem cancelamentos, e nenhuma ocorrência pode consumir RNG apenas porque havia um índice reservado. Rejeitar a ocorrência excedente **não autoriza criar outro índice**.
- Preservar D-095: a rejeição não altera retroativamente o veredito de eliminacões simultâneas já resolvidas conforme as regras existentes. Preservar D-235: aplicação independente de personagem e lado.

## Pendências e escopo

- **Não foi aprovado** o formato/canal do registro da violação (log, evento de diagnóstico, telemetria etc.), reação do Move para eventos posteriores ao excedente, eventual interrupção do restante da execução ou política de investigação/recuperação. **Não interpretar a rejeição apenas do excedente como aprovação automática de continuar ou cancelar o Move inteiro**.
- Nenhuma alteração de código, tests, fichas, Moves, cenas, assets ou VFX nesta atividade documental.
