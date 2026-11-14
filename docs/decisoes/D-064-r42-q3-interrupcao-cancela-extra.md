<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-064 — R42-Q3 (3A): Interrupção do original cancela contra-ataque

- **Data:** 2026-11-03
- **Área:** Combate
- **Fonte:** declaração expressa do criador na Rodada 42.
- **Estado:** decisão de design aprovada; implementação não verificada.

## Declaração literal do criador

> 3A — Se o ataque original for interrompido depois de enfileirar o contra-ataque?: Cancelar também o contra-ataque enfileirado.

## Decisão aprovada

Se o ataque original for interrompido após a seleção do golpe extra, **cancelar o contra-ataque enfileirado**; ele não pode executar posteriormente.

## Relações e questões abertas

- **Referências:** D-035, D-051, D-052, D-062.
- **Ressarcimento de custo já descontado** pela R42-Q1 permanece pendente.
- **Escopo:** este documento registra a regra, sem autorizar alteração de código ou testes.
