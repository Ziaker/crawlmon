<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1241 — BOOST no cartão do inimigo: variante 3

**Data:** 2026-11-16
**Área:** HUD de combate (visual)
**Estado:** escolhida pelo criador; o BOOST em si (atributos, duração, gatilho) é a D-1242 (implementada); o visual final é a D-1243.
**Relacionadas:** D-1229, D-984, D-240.

## Frase literal do criador

> "Boost precisa de prototipo visual no cartão do jogo"

> "variante 3"

## Decisão

Entre os 3 protótipos (`--boost=all`), vale a variante 3: brilho âmbar que sobe da base do cartão e faíscas subindo pela face, em baixa opacidade, atrás de retrato, nome, barras e badges, mais o badge "BOOST" do lado direito (D-984). Cores e ritmo exatos são os do protótipo e ainda podem ser ajustados por pedido dele.

## Estado no código

Protótipo só de HUD: `BattleHud.boost_preview` e `draw_boost_card()` (`scripts/ui/components/battle_hud_draw.gd`), atalho `--boost=3`. As variantes 1 e 2 continuam no código até ele mandar remover. Nada liga isso a um estado de BOOST real.
