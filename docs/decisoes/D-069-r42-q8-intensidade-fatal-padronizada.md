<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-069 — R42-Q8 (8A): Lançamento fatal de intensidade uniforme

- **Data:** 2026-11-03
- **Área:** Combate
- **Fonte:** declaração expressa do criador na Rodada 42.
- **Estado:** decisão de design aprovada; implementação não verificada.

## Declaração literal do criador

> 8A — O que determina a intensidade do lançamento fatal?: Lançamento padronizado, com intensidade igual para todos os Moves.

## Decisão aprovada

O **lançamento visual por hit fatal possui intensidade padronizada**, idêntica para todos os Moves, sem aumentar por dano, crítico ou fraqueza, nem variar por tipo de Move.

## Relações e questões abertas

- **Referências:** D-045, D-055, D-056, D-068.
- Valores numéricos, distância, arco, duração e efeitos ainda não foram especificados.
- **Escopo:** este documento registra a regra, sem autorizar alteração de código ou testes.
