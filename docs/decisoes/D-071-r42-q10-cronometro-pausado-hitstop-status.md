<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-071 — R42-Q10 (10B): Pausar cronômetro do contra-ataque em hit-stop e status

- **Data:** 2026-11-03
- **Área:** Combate
- **Fonte:** declaração expressa do criador na Rodada 42.
- **Estado:** decisão de design aprovada; implementação não verificada.

## Declaração literal do criador

> 10B — O cronômetro de 2 segundos do contra-ataque continua durante pausas do combate?: Não. Suspender o cronômetro durante hit-stop e pausas de status, retomando depois.

## Decisão aprovada

**Suspender o cronômetro dos dois segundos para selecionar o golpe extra durante hit-stop e pausas de Moves de status**. Retomar a contagem quando a pausa terminar, sem perder o tempo restante.

## Relações e questões abertas

- **Referências:** D-019, D-024, D-038, D-042, D-051, D-052.
- Não estender automaticamente a suspensão para outros tipos de pausa. Permanecem válidas a seleção antecipada e execução após o golpe original.
- **Escopo:** este documento registra a regra, sem autorizar alteração de código ou testes.
