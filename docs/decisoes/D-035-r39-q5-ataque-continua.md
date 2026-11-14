<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-035 — R39-Q5 (5B): Evade perfeito preserva ataque original

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R39; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 5B — Evade perfeito e contra-ataque: Ataque continua; golpe extra só começa quando terminar.

## Regra aprovada

O ataque próprio não é cancelado após o Evade perfeito aplicável; o golpe extra não começa antes de terminar o ataque original.

## Relações e questões de compatibilidade

- **Referências:** D-027; R40-Q1; R40-Q2; R40-Q3; R41-Q1; R41-Q2.
- **Observação:** Término: fim da animação do golpe antes do retorno. A seleção antecipada é permitida pela R41.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
