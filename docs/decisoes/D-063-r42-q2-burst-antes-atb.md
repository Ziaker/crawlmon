<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-063 — R42-Q2 (2A): Prioridade de Burst ao pagar Moves

- **Data:** 2026-11-03
- **Área:** Combate
- **Fonte:** declaração expressa do criador na Rodada 42.
- **Estado:** decisão de design aprovada; implementação não verificada.

## Declaração literal do criador

> 2A — Se o personagem tiver Burst e ATB suficientes, qual recurso paga o Move?: Consumir Burst primeiro, preservando ATB.

## Decisão aprovada

Quando **Burst e ATB são ambos suficientes**, consumir **Burst primeiro**, preservando o ATB. Manter que **1 Burst paga a ação inteira**, no máximo 5 unidades acumuladas.

## Relações e questões abertas

- **Referências:** D-033, D-053, R42-Q1.
- Não modificar custos-base dos Moves nem presumir qualquer nova fonte de Burst.
- **Escopo:** este documento registra a regra, sem autorizar alteração de código ou testes.
