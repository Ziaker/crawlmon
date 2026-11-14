<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-966 — Electric: raio em zigue-zague e brilho falso (sem Glow)

- **Data:** 2026-11-08.

## Frases literais do criador

> tem como fazer o raio de choque seguir um movimento em zigue-zague? inclusive a iluminação e as cores do move ainda não me apetecem, tá dificil de ver ainda, me diz o que propõe

> vou com o que propõe, opção A, siga com a ideia do movimento em zigzague também

## Decisão

1. **Zigue-zague:** o feixe vira um raio com quebras anguladas que **alternam de lado** a cada 1,2 m, com desvio de até 0,6 m. O caminho muda de repente 15 vezes por segundo. No trajeto, a ponta avança desenhando o caminho quebrado. Os fios finos acompanham as mesmas quebras.
2. **Opção A, brilho falso:** sprites suaves somados à luz, sempre de frente para a câmera (`shaders/lib_glow_sprite.gdshader`, MultiMesh). Ficam ao longo do raio, na carga, no estouro do disparo e no impacto. **Não** liga o Glow da cena (D-957 preservada); funciona no GL Compatibility.
3. As opções B (contorno escuro), C (paleta em três tons), D (escurecer a tela) e E (tamanho mínimo na tela) **não** foram escolhidas.
