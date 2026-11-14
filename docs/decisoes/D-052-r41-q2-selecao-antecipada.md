<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-052 — R41-Q2 (2B): Seleção antecipada e execução enfileirada

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
