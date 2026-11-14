<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-041 — R40-Q1 (1A): Fim do golpe antes do retorno

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
