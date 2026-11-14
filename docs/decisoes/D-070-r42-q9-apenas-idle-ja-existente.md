<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-070 — R42-Q9 (9A): Somente idle existente durante FX de status

- **Data:** 2026-11-03
- **Área:** Combate
- **Fonte:** declaração expressa do criador na Rodada 42.
- **Estado:** decisão de design aprovada; implementação não verificada.

## Declaração literal do criador

> 9A — Quais animações ociosas continuam durante o efeito de status?: Apenas as animações idle já existentes, sem deslocamento pelo cenário.

## Decisão aprovada

Durante o FX de status, **somente as animações idle já existentes continuam**; não há **deslocamento pelo cenário**. Outras ações ficam congeladas e a câmera acompanha o efeito, conforme R41-Q10.

## Relações e questões abertas

- **Referências:** D-014, D-019, D-020, D-038, D-060.
- Não reintroduzir locomoção ociosa removida; não autoriza novas animações idle ou mudanças na posição lógica.
- **Escopo:** este documento registra a regra, sem autorizar alteração de código ou testes.
