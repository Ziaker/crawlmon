<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1054 — Cyclops em 4 m

- **Data:** 2026-11-09
- **Área:** Visual / Modelos / Escala / D-1053
- **Origem:** resposta do criador depois de Cyclops em 3,58 m.

## Frase literal do criador

> "deixe o cyclops com 4m"

## Decisão

1. O Cyclops passa de 3,58 m para **4,00 m** de altura visível.
2. Slime continua em **1,43 m**; Orc, Abra, Pancham e Gible não mudam.
3. O Cyclops segue como exceção ao antigo teto de 2,5 m.
4. Nenhuma outra regra ou personagem é alterado.

## Ambiguidades em aberto

Nenhuma.

## Estado

Implementado em `battle_scene.gd`; medido em **4,005 m** e testado no DQT normal/espelhado. Vídeo: `test_captures/scale_test/cyclops4m_normal_mirror.mp4`. Sem commit/push.
