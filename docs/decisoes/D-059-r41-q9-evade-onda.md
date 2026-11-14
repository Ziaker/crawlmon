<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-059 — R41-Q9 (9B): Janela compartilhada de Evade da onda AoE

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R41; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 9B — Qual é a janela de Evade para cada alvo de uma onda AoE?: Todos os alvos compartilham uma única janela de Evade durante o voo da onda.

## Regra aprovada

Todos os alvos possuem a mesma janela geral de Evade durante o voo da onda AoE, mantendo as decisões de esquiva individual e de efeitos individuais.

## Relações e questões de compatibilidade

- **Referências:** D-007; D-009; D-030.
- **Observação:** Pendente: como conciliar essa janela comum com os últimos 0,22 s do Evade perfeito de cada impacto e chegadas em momentos diferentes.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
