<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1083 — Iluminação do lab menos clara e menos contrastada

- **Data:** 2026-11-09.
- **Área:** Exploração / lab da Murky Forest / iluminação.
- **Relacionadas:** D-1082 (luz/folhagem/oclusão), D-1028 (paleta), D-1023 (lab).
- **Status:** **teste implementado e verificado** no lab isolado; HUD/status/cards, NPCs, batalha, 2D e regras não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> tem como deixar a iluminação menos clara e contrastada

## Decisão

1. **Menos brilho geral:** baixar exposição, ambiente, lua e preenchimentos.
2. **Menos contraste:** lua mais fraca e sombra direcional mais suave (`shadow_opacity`), mantendo um preenchimento ambiente baixo para as áreas escuras não virarem buracos.
3. **Luzes locais mais discretas:** preenchimento central, luzes frias do início/curva, cogumelos, saída e aproximação quente com energias menores.
4. **Glow/fog mais contidos:** menos bloom e um pouco mais de névoa, para reduzir o “estourado” sem apagar a leitura do corredor.
5. **Sem azul novo.** A paleta verde/teal/âmbar de D-1028 continua.
6. **O que não muda:** geometria, vinhas/galhos, fade de oclusão D-1082, câmera, NPCs, HUD/status, cards, batalha, 2D e regras.

## Valores implementados

- ambiente: `1.05 → 0.95`; exposição: `0.95 → 0.88`;
- lua: `0.72 → 0.45`, `shadow_opacity = 0.55`;
- preenchimento central: `1.2 → 0.85`;
- preenchimento inicial: `0.55 → 0.32`; curva: `0.38 → 0.22`;
- luzes verdes: `0.55 → 0.40`; saída: `0.65 → 0.45`; aproximação: `0.5 → 0.30`;
- cogumelos: `0.65 → 0.45`;
- glow: `0.35 → 0.22`; bloom: `0.04 → 0.02`;
- névoa: `0.018 → 0.022`;
- ajuste de ambiente: brilho `0.98`, contraste `0.82`, saturação `0.88`.

## Teste implementado (2026-11-09)

- **Captura:** o mapa ficou mais escuro, com sombras mais suaves e verde/roxo menos estourados; o caminho, os NPCs e os cards continuam legíveis.
- **O que não mudou:** geometria, vinhas/galhos, fade de oclusão D-1082, câmera, HUD/status D-1075, cards, NPCs, Slime, batalha, 2D e renderer.
- **Auditoria:** a câmera/caminho continuam iguais (`wall_hits=0`, `cam_inside=0`, `path_min=2`, `stack_pairs=0`).
- **Provas/vídeos:** `murky_forest_hud_sugimori.png`, `murky_forest_status_hidden.png`, `murky_forest_status_party.mp4/.gif`, `murky_forest_status_solo.mp4/.gif` e `murky_forest_status_contato.png` regravados.

## O que não foi verificado

- Performance/ajuste de cor em 60 fps/mobile e outras resoluções.
- A cena principal em headless continua bloqueada pelos erros de VFX de outra sessão; teste no lab isolado.

## Estado

Teste implementado e verificado no lab isolado; iluminação mais baixa, menos contrastada e menos saturada. Provas/vídeos regravados; commit local; **sem push**. Nada de combate/2D/HUD mudou.
