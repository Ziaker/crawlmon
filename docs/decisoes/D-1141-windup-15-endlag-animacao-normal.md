<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1141 — Wind-up de 0,15 s e endlag com a animação em velocidade normal

- **Data:** 2026-11-10.
- **Área:** Overworld 3D / lab Murky Forest / ataque / animação.
- **Relacionadas:** D-1135 (2,0 m), D-1139 (animação na duração do dash, **substituída** para o jogador), D-1115 (impacto), D-1112.
- **Status:** **implementado/provado**; código na árvore de trabalho; **sem push**.

## O que o criador disse (literal)

> traga devolta o wind-up de .15 segundos e dê um endlag pro dash com a animação terminando na velocidade normal

## Regra

1. **Wind-up de 0,15 s:** o Z do jogador volta a esperar **0,15 s** antes de mover. A animação `attack` começa no início do wind-up e roda a **1,0×**.
2. **Dash:** continua com teto de **2,0 m** e duração de até **0,18 s** (D-1135), com a animação ainda a 1,0×.
3. **Endlag:** depois do dash, o jogador fica **travado** até o clipe `attack` terminar, também a **1,0×**. O endlag é a diferença entre o comprimento do clipe e o tempo já decorrido (wind-up + dash). Com o clipe atual de **1,9667 s**, o endlag fica em ~**1,64 s** depois de um dash completo.
4. **Acerto:** o VFX de impacto continua no contato, mas a transição de batalha espera o endlag terminar (o maior entre 0,5 s de impacto e o endlag).
5. **Ataque livre:** sem inimigo, o mesmo wind-up + dash + endlag; não inicia batalha.
6. **D-1139 fica substituída para o jogador:** a animação não é mais acelerada para caber no dash; ela termina naturalmente no endlag.
7. **Inimigo:** continua com telegraph de 0,4 s + pré-avanço de 0,12 s e clipe a 2,0×.
8. **O que não muda:** distância de 2,0 m, impacto de 0,5 s, Z ataca sempre, câmera/movimento, cômodo/Gible e o resto.

## Implementação

- `overworld_attack_controller.gd`: `PLAYER_WINDUP_TIME = 0.15`; fase `ENDLAG`; `_player_endlag_left = clip.length - (wind-up + dash)`; `set_player_attack_length()`; a batalha espera o endlag.
- `murky_forest_3d_lab.gd`: passa o comprimento do clipe `attack`; velocidade **1,0** no início.

## Provas

- Log do ataque livre: `clip=1,9667`, `endlag=1,5167` após 0,45 s, `attacking=true`; depois de mais 1,67 s, `attacking=false`, cooldown 0,58; deslocamento **2,037 m**.
- `tests/overworld/test_overworld_attack.gd`: **PASS** (wind-up 0,15, dash após 0,15, animação a 1,0×, batalha após o endlag).
- `docs/referencias/exploracao/3d/d1141_free_attack.png` — ataque livre.

## O que foi verificado

- O jogador não se move durante o wind-up; anda no dash e fica parado no endlag.
- A animação roda a 1,0× e termina no fim do endlag.
- O ataque com alvo espera o endlag antes da batalha; o impacto continua no contato.
- O ataque livre não inicia batalha.

## O que não foi verificado

- A sensação de um ataque de ~1,97 s (0,15 + 0,18 + ~1,64); se ficar longo, o caminho é encurtar/trimar o clipe, não acelerar de novo.
- O inimigo (mantido a 2,0×) e o gamepad.

## Estado

Implementado e provado. Código na árvore de trabalho; **sem push**.
