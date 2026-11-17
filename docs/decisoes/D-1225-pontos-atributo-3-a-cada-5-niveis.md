<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1225 — Pontos de atributo: 3 pontos a cada 5 níveis (substitui marco de 10 em D-394)

- **Data:** 2026-11-15
- **Área:** Personagens / progressão
- **Relacionadas:** D-394 (regra anterior de pontos de nível), D-392 (marcos de +25 HP a cada 10 níveis — inalterada; MP não tem marco: `10 + 2×WIS + nível`, D-391), D-1223 (distribuição automática em aliados), D-235.
- **Status:** **implementada e verificada.**

## O que o criador disse (literal)

> vamos fazer uma mudança no jogo, agora ganha 3 pontos a cada 5 niveis não mais a cada 10

## Decisão

1. **Pontos de atributo por nível:** ao atingir um nível múltiplo de **5** (`5, 10, 15, 20, 25...`), o personagem (líder e aliado, D-235) ganha **3 pontos** de atributo (`new_level % 5 == 0`), substituindo o marco anterior de 10 em 10 níveis da **D-394**. Nos demais níveis, continua ganhando **1 ponto**.
2. **Escopo preservado:** o salto de HP máximo da **D-392** (`+25 HP` adicional nos marcos a cada 10 níveis) não foi alterado por esta decisão. O MP máximo não tem salto por marco: é `10 + 2×WIS + nível` (D-391; `crawlmon_attribute_math.calculate_max_mp`).
