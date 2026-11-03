# D-038 — R39-Q8 (8A): Pausa de Moves de status na ativação

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R39; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 8A — Pausa dos Moves de status: Pausar na ativação do efeito; congelar demais ações, executar FX de status e retomar ao fim.

## Regra aprovada

A pausa começa na ativação do efeito de status; as outras ações congelam enquanto o FX é executado; retomam ao fim.

## Relações e questões de compatibilidade

- **Referências:** D-014; D-019; R41-Q10.
- **Observação:** R41-Q10 preserva animações ociosas e permite à câmera acompanhar o status.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
