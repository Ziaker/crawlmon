# D-160 — Lançamento de K.O. sempre para longe de onde os jogadores estão

- **Data:** 2026-11-03
- **Área:** Combate / Visual / Game Feel
- **Origem:** Conversa

## O que o criador disse (literal)

> o inimigo estar sendo lançado pra frente ao invés de pra trás quando leva o hit final, é pra ele sempre ser lançado pra direção oposta de onde os jogadores estão, no caso pra trás.

## Decisão

O inimigo derrotado é lançado **sempre** na direção oposta à de onde os jogadores estão (para trás), qualquer que seja o golpe ou a posição do atacante. A direção é a linha do centro da equipe do jogador até o ponto de origem do inimigo. Isso **substitui D-079 para inimigos**, que mandava afastar de quem aplicou o golpe fatal.

## Causa no código

`FxMotion.launch_ko` usava a direção do golpe. O Teleport bate por trás do alvo, então o inimigo voava em direção aos jogadores (reproduzido: `delta z = +20,5`, `dot = -0,97`).

## Ambiguidades em aberto

Nenhuma. A leve deflexão lateral de D-157 permanece. Aliados não têm lançamento no código; D-068/D-079 continuam valendo para eles quando for implementado.

## Estado no código

Implementado (`fx_motion.gd`, `battle_fx.gd`, `tests/battle/test_d160_d164_combat_fixes.gd`).
