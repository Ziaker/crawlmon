# D-52 — R41-Q2 (2B): Seleção antecipada e execução enfileirada

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R41; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 2B — É possível selecionar o contra-ataque enquanto o ataque original ainda está acontecendo?: Sim. O jogador pode selecionar antecipadamente o Move, que fica aguardando sua vez.

## Regra aprovada

O Move extra pode ser escolhido durante o ataque original; fica na fila e não executa até o ataque original terminar.

## Relações e questões de compatibilidade

- **Referências:** R40-Q3; R41-Q1; R41-Q3.
- **Observação:** Complementa a R40-Q3 quanto ao momento da seleção, sem permitir execução simultânea.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
