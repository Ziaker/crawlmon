# D-271 — Rodada 83 Q3 (3A): ordenar excedentes simultâneos por índice do evento gerador e ID do alvo

- **Data:** 2026-11-05.
- **Área:** Combate / eventos condicionais / diagnóstico determinístico / simultaneidade.
- **Origem:** aprovação expressa do criador na Rodada 83.
- **Estado:** regra de ordenação diagnóstica aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 3A — Ordenar solicitações excedentes simultâneas primeiro pelo índice estável do evento gerador no plano e depois pelo ID estável do alvo, atribuindo a sequência diagnóstica nessa ordem.

## Regra aprovada

- Para **solicitações simultâneas de ocorrência condicional excedente associadas à mesma declaração**, **ordenar primeiro pelo índice estável do evento gerador no plano determinístico do ataque**; havendo igualdade nesse índice, **desempatar pelo ID estável do alvo**.
- **Atribuir a sequência de identificadores diagnósticos de excedentes nessa ordem**, preservando **D-266**: o identificador de cada solicitação rejeitada é derivado da **identidade da declaração e de uma sequência determinística de excedentes**, **separada dos índices válidos do plano**.
- Preservar **D-218/D-222/D-226/D-233** (índices de ocorrências válidas fixados na declaração, sem reutilização), **D-242/D-252** (rejeitar e registrar apenas o excedente, continuar eventos posteriores válidos), **D-256** (registro estruturado com Move, atacante, declaração, máximo aprovado e solicitação excedente) e **D-095** (resultados de KO simultâneo não são afetados pela ordem de diagnóstico).
- **Exemplo ilustrativo, não eventos reais:** duas solicitações excedentes simultâneas da mesma declaração provêm de eventos com índices geradores `#2` e `#1`, visando alvos IDs `5` e `7` respectivamente. Ordenar pela origem `#1`, depois `#2`, antes de atribuir seus IDs de diagnóstico; se o índice gerador for igual, ordenar pelo ID do alvo. A numeração de eventos e de alvos é fictícia.
- A ordem aprovada é **apenas diagnóstica**. **Não cria índices válidos para solicitações rejeitadas, não executa o excedente, não consome RNG por esse motivo e não altera a simultaneidade lógica de combate**.

## Pendências e limites

- Se duas solicitações tiverem **mesmo índice do evento gerador e mesmo ID de alvo no mesmo instante lógico**, a D-271 **não define critério residual**; não escolher ordem incidental de callbacks. Permanecem pendentes formato exato do identificador, granularidade de simultaneidade, serialização, replay e política de rollback.
- A decisão não amplia automaticamente a ordenação para solicitações de declarações distintas nem para outras classes de eventos.
- Somente documentação; nenhum código, teste, sistema de logs, ficha, Move, IA, VFX, cena ou asset modificado.
