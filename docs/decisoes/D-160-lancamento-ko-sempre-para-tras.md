<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

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
