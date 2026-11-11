# D-1142 — Inimigos com o mesmo wind-up, endlag e animação normal

- **Data:** 2026-11-11.
- **Área:** Overworld 3D / lab Murky Forest / ataque / inimigos / animação.
- **Relacionadas:** D-1141 (jogador), D-1135 (2,0 m), D-1112, D-1115, D-1100.
- **Status:** **implementado/provado**; código na árvore de trabalho; **sem push**.

## O que o criador disse (literal)

> vc só mencionou o jogador, não mencionou os inimigos, é pros inimigos também ter as mesmas caracteristicas

## Regra

1. **Wind-up de 0,15 s:** o inimigo mantém o **telegraph de 0,4 s** (D-1100) e depois espera **0,15 s** antes de mover — o mesmo wind-up do jogador (antes eram 0,12 s).
2. **Dash de 2,0 m:** continua o teto de **2,0 m** para o inimigo (D-1135).
3. **Animação a 1,0×:** o clipe `attack` do inimigo começa no wind-up e roda em **velocidade normal**, não mais a 2,0×.
4. **Endlag:** depois do dash, o inimigo fica travado até o clipe `attack` terminar, também a **1,0×**. O endlag é `clip.length − (wind-up + dash)`, usando o comprimento do clipe de cada inimigo.
5. **Batalha:** no acerto, o impacto do Tackle continua no contato, mas a transição espera o **maior entre 0,5 s e o endlag**.
6. **Cada inimigo tem seu comprimento:** Slime e Gible passam seus clipes ao controller; se um não tiver `attack`, o endlag é 0 e vale o comportamento antigo.
7. **O que não muda:** 2,0 m, ataque do jogador (D-1141), Z ataca sempre, câmera/movimento, cômodo/Gible e o resto.

## Implementação

- `overworld_attack_controller.gd`: `ENEMY_WINDUP_TIME = 0.15`; fase `ENDLAG` para inimigos; `set_enemy_attack_length()`; `attack_elapsed`/`endlag_left` por entrada; batalha espera o endlag.
- `murky_forest_3d_lab.gd`: passa o comprimento de `attack` do Slime e do Gible; velocidade **1,0** no `_on_attack_enemy_dash`.

## Provas

- `test_overworld_attack.gd`: **PASS** com `enemy attack clip runs at normal speed (D-1142)` e o telegraph de 0,4 s.
- `test_end_to_end_attack_flow.gd`: **END_TO_END_ATTACK: OK** com `Gible entered the 0.15 s pre-advance` e `Gible plays the attack clip at normal speed (D-1142)`.

## O que foi verificado

- O inimigo mantém 0,4 s de telegraph e passa a 0,15 s de pré-avanço.
- O clipe do inimigo roda a 1,0× e o controller espera o endlag antes da batalha.
- Slime e Gible usam o comprimento do próprio clipe.
- Os testes de ataque e ponta a ponta passam.

## O que não foi verificado

- A sensação visual de cada inimigo com o endlag completo (o clipe do Slime/Gible pode deixar o ataque longo).
- Gamepad e todos os ângulos de câmera.

## Estado

Implementado e provado. Código na árvore de trabalho; **sem push**.
