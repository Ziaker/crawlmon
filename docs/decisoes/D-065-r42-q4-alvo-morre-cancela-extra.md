<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-065 — R42-Q4 (4A): Morte do alvo cancela golpe extra

- **Data:** 2026-11-03
- **Área:** Combate
- **Fonte:** declaração expressa do criador na Rodada 42.
- **Estado:** decisão de design aprovada; implementação não verificada.

## Declaração literal do criador

> 4A — Se o alvo do contra-ataque morrer antes de o golpe extra começar?: Cancelar o contra-ataque extra.

## Decisão aprovada

Se o **alvo do Move extra morrer antes de começar sua execução**, **cancelar** o contra-ataque de alvo único; não selecionar outro alvo automaticamente.

## Relações e questões abertas

- **Referências:** D-051, D-052, D-062, D-064.
- O cancelamento não define se ocorre restituição do ATB/Burst consumido na seleção.
- **Escopo:** este documento registra a regra, sem autorizar alteração de código ou testes.
