<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-068 — R42-Q7 (7C): Derrota fatal de aliado sem desaparecimento

- **Data:** 2026-11-03
- **Área:** Combate
- **Fonte:** declaração expressa do criador na Rodada 42.
- **Estado:** decisão de design aprovada; implementação não verificada.

## Declaração literal do criador

> 7C — Como os personagens aliados devem reagir a um hit fatal?: O aliado é lançado para trás e cai, mas não desaparece.

## Decisão aprovada

No hit fatal de um **aliado**, ele é **lançado para trás e cai no chão**, **sem desaparecer**. Para **inimigos**, conservar D-056: lançamento, queda e desaparecimento.

## Relações e questões abertas

- **Referências:** D-024, D-025, D-056, R42-Q8.
- Tempo, percurso, posição final e animação específica não foram definidos numericamente.
- **Escopo:** este documento registra a regra, sem autorizar alteração de código ou testes.
