# D-1052 — Dread do Fire Bullet 1,2× maior

- **Data:** 2026-11-09.
- **Área:** VFX / Combate.
- **Origem:** ajuste final pedido pelo criador sobre D-1029/D-1039.

## Frase literal do criador

> aumente o tamanho do efeito do dread nesse move e pronto ficou perfeito

## Decisão

1. **Só no Fire Bullet**, o Dread é **1,2× maior** que o tamanho derivado do corpo (D-986/D-989).
2. A posição continua na ponta do projétil (D-1029) e o timing continua terminando antes do impacto (D-1039); só o raio do anel/estrela muda.
3. Vale para qualquer atacante, time, lado e câmera (D-235); o multiplicador é do Move, não do personagem.
4. Os demais Moves mantêm o tamanho normal de D-986.

## Ambiguidade

- O criador não deu um número; **1,2×** foi o ajuste escolhido para o POV do jogador (depois de 1,8× ter ficado grande demais). Se ele quiser maior ou menor, o multiplicador deve ser rediscutido.

## Estado

**Implementado para revisão em 2026-11-09.** Multiplicador final **1,2×** (o criador rejeitou 1,8×: "1.2x nao 1.8"). Evidência principal no POV do jogador, câmera automática do jogo (`--cam=0`, Cyclops inimigo → Abra): `test_captures/vfx_tools/fire_bullet_player_pov.mp4` (1280×720, 75 quadros, 2,5 s); o Dread aparece em ~1,70–1,80 s (quadros 50–53), some em 1,83 s e o clarão/impacto só vem nos quadros 59–60. Posição/timing de D-1029/D-1039 intactos. Não verificado: outros atacantes/alvos, DQT e aprovação visual final. Nada commitado.
