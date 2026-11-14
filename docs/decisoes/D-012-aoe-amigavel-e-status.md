<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-012 — AoE amigável inclui o lançador; golpes de status não são esquiváveis

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> sim padrão, não, são efeitos de status

## Decisão

**9:** AoE amigável (Media, Tarukaja) afeta a equipe toda, **incluindo o lançador**. **10:** os debuffs de alvo único (Rakunda, Sukunda) **não** podem ser desviados: "são efeitos de status".

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma.

## Estado no código

Parcial: golpes amigáveis já não são esquiváveis no código; debuffs de alvo único não têm trajeto, então não são desviáveis.
