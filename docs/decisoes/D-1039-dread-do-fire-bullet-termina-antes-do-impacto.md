# D-1039 — Dread do Fire Bullet termina antes do impacto

- **Data:** 2026-11-09.
- **Área:** VFX / Combate / Processo.
- **Origem:** correção pedida pelo criador sobre D-1029; resposta à pergunta de timing.

## Frase literal do criador

> a animação do efeito do dread deve ser consistente, ela não finaliza antes de causar o impacto, corrija NESSE move em específico
>
> ainda existe antes de chegar no impacto, acelere sua duração ainda mais

Resposta à pergunta "o que você quer que aconteça com o Dread do Fire Bullet em relação ao impacto?": **"Terminar antes do impacto"** — "O Dread completa a animação e some antes do impacto; o impacto começa sem o Dread em cima."

## Decisão

1. **Só no Fire Bullet**, o Dread completa a animação e some **antes do impacto**. O quadro do impacto começa **sem** o Dread em cima.
2. O efeito fica visível por no máximo **0,13 s** a partir do início da janela: a animação do anel completa **0,14 s antes** do impacto (`FIRE_END_GAP + FIRE_FADE`) e o fade de **0,02 s** termina **0,12 s antes** do impacto (`FIRE_END_GAP`). O Dread não existe mais quando a bala chega ao alvo.
3. O tempo até o impacto vem de `Incoming.eta()` (a lógica é dona do relógio, D-019/D-1037); não é um timer visual independente decidindo quando o ataque chega.
4. Os demais Moves mantêm D-986/D-987/D-989: animação ao longo da janela e fade de 0,1 s **depois** que a janela fecha.
5. Vale para qualquer atacante, time, lado e câmera (D-235). A ponta continua vindo do projétil real (D-1029).

## Ambiguidade

- Os valores `FIRE_END_GAP = 0,12 s` e `FIRE_FADE = 0,02 s` são o ajuste desta rodada para "acelere ainda mais". Se o criador quiser o Dread ainda mais cedo (ou um intervalo visível maior), os dois valores devem ser rediscutidos.

## Estado

**Implementado para revisão em 2026-11-09.** No Fire Bullet, o Dread é visível por ~2–3 quadros (51–53 na câmera do jogo), some no 54 e o clarão/impacto só vem nos quadros 59–60; usa `Incoming.eta()` e `FIRE_END_GAP = 0,12 s` + `FIRE_FADE = 0,02 s`. Evidência principal, **POV do jogador na câmera automática do jogo** (`--cam=0`, Cyclops inimigo → Abra): `test_captures/vfx_tools/fire_bullet_player_pov.mp4` (1280×720, 75 quadros, 2,5 s). Evidência complementar: `test_captures/vfx_tools/fire_bullet_dread_tip_final.mp4` (normal em cima, espelhado embaixo) e `test_captures/vfx_tools/fire_bullet_dread_gamecam.mp4`. Teste extra com atacante inimigo no lado normal: `test_captures/vfx_tools/fire_bullet_dread_tip_enemy_normal.mp4`. Para conseguir gravar, foi completado o wrapper `battle_fx._hit_react(c, slow_time)` para a chamada nova da alteração D-1043 de outra sessão; nada commitado. Não verificado: DQT espelhado (timeout de 180 s no carregamento), alvos de tamanhos realmente diferentes e as ferramentas de D-1044 (`--audit-leaks`, `--proof-sheet`, etc. não estão presentes neste checkout, apesar de a decisão dizer implementadas). Nada commitado.
