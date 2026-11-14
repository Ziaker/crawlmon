<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1112 — Animação de ataque no início do avanço

- **Data:** 2026-11-10
- **Área:** Overworld 3D / lab / animação / ataque
- **Origem:** pergunta do criador sobre a animação de ataque durante o avanço.
- **Status:** **implementado e testado** (66/66 controlador + Gible no ponta a ponta); demo em slow motion regravada; o intervalo do pré-avanço foi ajustado para **0,12 s** pela D-1120, mantendo o clipe a 2,0×. Pendente só a aprovação visual do clipe.

## O que o criador disse (literal)

> Eles realizam a animação de ataque? No avanço?
>
> no inicio

## Decisão

1. O jogador e os inimigos tocam o clipe **`attack` no início do avanço** (dash), não apenas `walk`/`idle`.
2. O clipe continua durante o avanço e é interrompido pela transição/retorno normal; o timing do avanço, o dano e a transição **não mudam**.
3. Se um modelo não tiver `attack`, cai no `walk`/`idle` atual (fallback).
4. D-235: qualquer ator, de qualquer lado, usa o mesmo hook.
5. O Slime DQT usa o alias `attack` → `11` do `DQT_PROFILES`; Abra e Gible têm `attack` nativo.

## Atualização — velocidade 1,55× (2026-11-10)

> deixe a velocidade da animacao durante o avanco 1.55x mais rapida

O clipe `attack` toca a **1,55×** durante o dash; a velocidade normal volta no fim do avanço. O timing do dash, o dano e a transição **não mudam**.

## Atualização — 2,0× (2026-11-10)

> mais rapido ainda
>
> 1

O clipe `attack` passa a **2,0×** durante o dash (substitui 1,55×). A velocidade normal volta no fim do avanço. O timing do dash, o dano e a transição **não mudam**.

## Implementação

- `OverworldAttackController`: novo sinal `enemy_dash_started`; o `player_dash_started` já existia.
- `murky_forest_3d_lab.gd`: toca `attack` no jogador/Slime/Gible no início do dash a **2,0×**; `_player_attack_anim_active` impede o `_play_move` de sobrescrever; `_update_enemy`/`_update_second_enemy` já são pulados durante o dash; a velocidade normal volta no fim.
- `third_person_3d_lab.gd`: hook `_is_attack_animation_locked()` para o lab base.

## Estado

Implementado e testado; vídeos `overworld_attack_player/enemy/contact` e o combinado `overworld_attack_3cases` regravados com a pose de ataque no início a **2,0×**; pendente aprovação visual. Sem commit e sem push.
