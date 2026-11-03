# D-41 — R40-Q1 (1A): Fim do golpe antes do retorno

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R40; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 1A — Quando o ataque original é considerado terminado?: Assim que o golpe acerta e o dano é aplicado.
> 
> Observações: 1 - quando o golpe é efetuado, e a animação acaba, antes de pular/teleportar devolta pra posição original

## Regra aprovada

A observação posterior esclarece o término: golpe efetuado e animação do golpe concluída, antes do pulo/teleporte de volta à posição original. Não equiparar automaticamente esse término ao instante de dano se a animação ainda não acabou.

## Relações e questões de compatibilidade

- **Referências:** R39-Q5; R41-Q1; R41-Q2.
- **Observação:** Tempo de retorno não faz parte da espera obrigatória para iniciar o golpe extra.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
