<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-968 — Esfera do wind-up maior, sem encolher no release, some 0,6 s depois do disparo

- **Data:** 2026-11-08.

## Frase literal do criador

> pode me dizer se está usando as skills de melhora de vfx do godot e o flipbook? aumente o tamanho final da esfera do wind up e não faça ela perder o tamanho durante o release, ela deve sumir naturalmente .6 segundos depois do disparo.

Pediu também as skills `/scenario-godot-animation`, `/scenario-godot-rendering-lighting` e `/scenario-godot-shaders`.

## Resposta honesta sobre as skills (registrada)

- `scenario-godot-vfx` e `scenario-godot-shaders` estavam carregadas, mas as ferramentas delas **não** eram usadas. Agora rodou o lint de shader: só avisos informativos de transparência, intencional. A compilação por renderizador da skill **não rodou**, porque exige copiar o kit dela para `addons/agentkit/` no projeto; isso não foi feito sem autorização.
- **Flipbook: nenhum** no efeito atual (malhas, shader próprio e sprites aditivos).

## Decisão

1. A esfera de choque chega a **0,95 m** de raio no fim do pós-wind-up (antes 0,62).
2. No disparo ela **não encolhe**: mantém o tamanho e **some naturalmente em 0,6 s** depois do disparo (dissolve, junto com o brilho).
