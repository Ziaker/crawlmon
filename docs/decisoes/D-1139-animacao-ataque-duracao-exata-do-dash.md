<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1139 — Animação de ataque preenche exatamente a duração do dash

- **Data:** 2026-11-10.
- **Área:** Overworld 3D / lab Murky Forest / ataque / animação.
- **Relacionadas:** D-1112, D-1135 (2,0 m sem wind-up), D-1137 (Z ataca sempre).
- **Status:** **implementado/provado**; código na árvore de trabalho; **sem push**.

## O que o criador disse (literal)

> tem como fazer com que a animação de ataque siga na exata mesma duração do dash mas que seja executada por completo?

## Regra

1. **Duração exata:** a animação `attack` do **jogador** toca do primeiro ao último quadro exatamente durante a duração planejada do dash (`plan["time"]`, entre 0,06 s e 0,18 s).
2. **Executada por completo:** a velocidade é `clip.length / dash_duration`; o clipe não é cortado nem reiniciado no meio. Se o clipe for mais curto que o dash, ele desacelera para preencher; se for mais longo, acelera.
3. **Sem loop:** a animação roda uma vez e termina no fim do dash.
4. **Fallback:** sem clipe `attack`, continua o `ATTACK_ANIM_SPEED = 2,0×`.
5. **Escopo:** vale para o Z do jogador (com alvo e ataque livre). O inimigo continua com o clipe a 2,0× e o pré-avanço de 0,12 s (D-1112/D-1114).
6. **O que não muda:** distância de 2,0 m, impacto de 0,5 s, ataque sem alvo, câmera, movimento, cômodo/Gible e o resto.

## Implementação

- `overworld_attack_controller.gd`: `_player_dash_duration` + `get_player_dash_duration()`; `player_dash_started` é emitido **depois** do plano do dash, para o lab saber a duração.
- `murky_forest_3d_lab.gd`: `_attack_anim_speed(ap, duration) = clip.length / duration` aplicado no `_on_attack_player_dash`.

## Provas

- Log do ataque livre: clipe `attack` = **1,9667 s**, dash = **0,18 s**, `speed_scale` = **10,9259** e esperado **10,9259**; deslocamento **2,037 m**, sem batalha.
- `tests/overworld/test_overworld_attack.gd`: **PASS**, incluindo `player attack clip fills the exact dash duration (D-1139)`.

## O que foi verificado

- A velocidade é matematicamente a razão entre o clipe e a duração do dash; o clipe toca completo.
- O sinal de animação continua sendo emitido no início do dash.
- O ataque com alvo e o ataque livre usam a mesma regra.
- Os testes de ataque continuam passando.

## O que não foi verificado

- A leitura visual a 10,9× (o clipe tem ~1,97 s; num dash de 0,18 s ele fica muito rápido). Se ficar ilegível, o caminho é encurtar/trimar o clipe ou aumentar a duração do dash — não mudar a regra de duração exata.
- O inimigo (mantido em 2,0×) e o gamepad.

## Estado

Implementado e provado. Código na árvore de trabalho; **sem push**.
