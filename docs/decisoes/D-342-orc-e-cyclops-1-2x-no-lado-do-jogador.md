<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-342 — Orc e Cyclops 1,2× maiores no lado do jogador

- **Data:** 2026-11-06
- **Área:** Visual / Piloto DQT
- **Origem:** Conversa

## O que o criador disse (literal)

> "o orc e o cyclope estão um pouco baixinhos demais pro tamanho deles no lado do jogador, faça eles terem 1.2x (que já tem no lado do oponente, sem mudar o tamanho nesse lado) no lado do jogador"

## Decisão

1. Quando o Orc ou o Cyclops estão no **lado do jogador**, o modelo fica **1,2×** maior.
2. No lado do oponente nada muda (lá já vale o aumento de inimigos da D-339).
3. Slime e Pokémon não mudam.

## Ambiguidades em aberto

Nenhuma.

## Estado no código

`dqt_model_profiles.gd` (`ally_scale` nos perfis do Orc e do Cyclops) e `battle_scene.gd` (`_spawn`).
