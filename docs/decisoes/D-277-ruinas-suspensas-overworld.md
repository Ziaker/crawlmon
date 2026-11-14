<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-277 — Ruínas suspensas e passagens do overworld

- **Área** — Exploração / visual / colisão
- **Estado** — Direção aprovada pelo criador.

## O que o criador disse

> inclusive corrija o espaçamento dos blocos, tem coisa que o boneco não consegue passar mesmo aparentemente sendo capaz, prossiga com as 5 ideias

## Decisão

Aplicar as cinco ideias aprovadas ao overworld 2D: plataformas e pontes suspensas, ruínas e portais, grandes lajes gastas, frisos ciano e braseiros coral, e ruínas distantes em camadas. Corrigir a folga de passagem onde o personagem aparenta caber. Mantêm-se a geração do mapa, o movimento cardinal e a visibilidade da D-033.
