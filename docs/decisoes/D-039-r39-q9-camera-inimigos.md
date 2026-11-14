<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-039 — R39-Q9 (9A): Todos os inimigos enquadrados

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R39; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 9A — Visibilidade dos inimigos na câmera: Todos os inimigos visíveis sempre, inclusive nos momentos cinematográficos.

## Regra aprovada

Todos os inimigos devem permanecer visíveis na câmera, inclusive durante momentos cinematográficos.

## Relações e questões de compatibilidade

- **Referências:** D-015; D-020; R40-Q10.
- **Observação:** Zoom e deslocamento permitidos por R40-Q10; tremor continua proibido.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
