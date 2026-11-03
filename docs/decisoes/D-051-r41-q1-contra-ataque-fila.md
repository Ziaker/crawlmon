# D-051 — R41-Q1 (1B): Contra-ataque escolhido no prazo pode executar depois

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R41; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 1B — O contra-ataque ainda pode acontecer se a animação original durar mais de 2 segundos?: Sim, mas somente se o jogador tiver escolhido o contra-ataque dentro dos 2 segundos; ele será executado depois.

## Regra aprovada

A seleção manual dentro da janela de dois segundos reserva o golpe extra, que executará após terminar a animação original, mesmo que a janela de seleção já tenha encerrado.

## Relações e questões de compatibilidade

- **Referências:** R39-Q5; R40-Q1; R40-Q2; R41-Q2.
- **Observação:** Falta definir o instante de desconto do custo em caso de seleção antecipada.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
