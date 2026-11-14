<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-048 — R40-Q8 (8A): Recompensas únicas por condição em AoE

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R40; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 8A — Recompensas de ATB nos ataques em área: Basta um alvo sofrer fraqueza ou crítico para conceder a recompensa correspondente uma vez.

## Regra aprovada

Em cada Move AoE, conceder no máximo uma recompensa de fraqueza e uma de crítico por ação, quando pelo menos um alvo satisfizer a condição respectiva; não multiplicar pelo número de alvos.

## Relações e questões de compatibilidade

- **Referências:** D-010; R39-Q6.
- **Observação:** Preservar os valores preexistentes até decisão explícita de mudança; esta resposta não estabelece novos números.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
