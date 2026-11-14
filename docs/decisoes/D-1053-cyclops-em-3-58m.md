<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1053 — Cyclops em 3,58 m

- **Data:** 2026-11-09
- **Área:** Visual / Modelos / Escala / D-1047
- **Origem:** resposta do criador depois do ajuste de Cyclops/Slime.

## Frase literal do criador

> "deixe o cyclops em 3,58"

## Decisão

1. O Cyclops passa a ter **3,58 m** de altura visível.
2. O Slime continua no tamanho reduzido de **1,40 m** (D-1047); Orc, Abra, Pancham e Gible continuam na escala anterior.
3. A exceção de Cyclops ao antigo teto de 2,5 m fica ainda maior: 3,58 m.
4. Nenhum outro personagem muda.

## Ambiguidades em aberto

Nenhuma.

## Estado

**Substituída por D-1054** (Cyclops 4,00 m). O valor 3,584 m foi medido e testado no vídeo `cyclops358_normal_mirror.mp4`, mantido como histórico. Sem commit/push.
