<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

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
