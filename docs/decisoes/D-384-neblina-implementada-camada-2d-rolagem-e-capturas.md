# D-384 — Neblina implementada: camada 2D, rolagem de 20% e capturas

- **Data:** 2026-11-06
- **Área:** Exploração / visual / clima
- **Origem:** execução da primeira leva aprovada em D-381/D-382/D-383, com a ordem do criador de usar as skills Godot instaladas.
- **Status:** **neblina implementada e com vídeo**; densidade ajustada em D-385 (vídeos regravados); calor, chuva/neve, cinza e distorção temporal ainda não. Nada publicado.

## O que foi implementado

1. **Shader `shaders/weather_mist.gdshader`:** véu 2D de tela cheia, com `mist` (0–1), `mist_color` vindo do ambiente do bioma, ruído do próprio bioma, drift lento, densidade e borda fechada (D-385). Fade de 2 s na entrada e na saída. É uma camada de ambiente, **fora do Motion Composer** (D-383).
2. **`scripts/dungeon/weather_controller.gd`:** rolagem determinística de **20% por andar** (1 em 5) usando `dungeon_seed` + `visual_floor`; no máximo **um evento por andar**; duração **20–40 s**; início **0,8 s** depois de o andar carregar; `_played` evita repetir o mesmo evento ao voltar de uma batalha. O tipo sai do mapa de D-362; **só a neblina está implementada**.
3. **`scripts/dungeon/exploration.gd`:** instancia o controller depois da névoa de guerra e antes da vinheta. A camada fica em `CanvasLayer` 1, abaixo do diálogo (15) e dos menus (10), com `light_mask = 0`.
4. **Sem regra:** não altera movimento, combate, colisão, câmera, geração, raio de visão 7,5, LOS nem o explorado permanente. A neblina é um véu de **tela cheia**; ela não mexe na máscara de explorado, apenas cobre a cena com baixa alpha.
5. **Debug de captura/vídeo:** `debug_force = "mist"` força a neblina; `debug_disable = true` desliga o clima para o "antes"; `debug_duration = 10.0` encurta o evento para o vídeo. Nenhum é usado pelo jogo normal (duração real 20–40 s).

## Testes

- `tests/exploration/test_weather_roll.gd` (headless): **194/1000 = 19,4%** de rolagens em 1000 andares; seed 2/andar 1 passa e escolhe neblina em Temporal Tower; os seis biomas testados retornam um tipo; **WEATHER TESTS: OK**.
- `scratch/test_weather_roll.gd` (auxiliar): mesma rolagem e tipos por bioma.
- Captura forçada: `scratch/weather_mist.png`.
- Captura pela **rolagem real** (seed 2, andar 1): `scratch/weather_mist_roll.png`.
- Antes/depois: `docs/referencias/exploracao/weather_mist_before_after.png` (mesmo seed/andar, sem clima × com neblina).
- O shader compilou e desenhou no **GL Compatibility** durante a captura; não houve erro de shader.
- A captura de rolagem real e a de "sem clima" foram feitas no **worktree principal** (seed 2, andar 1); a cena abriu e desenhou sem erro de shader.
- As capturas de bioma/tileset usam `debug_disable = true` para não misturar clima com o atlas.

## Vídeos

Regravados em D-385 (densidade e cantos).

- `docs/referencias/exploracao/weather_mist_cycle.mp4` — 12 s, 1280×720, 30 fps; ciclo completo com `debug_duration = 10 s` (2 s de fade-in + 6 s de espera + 2 s de fade-out).
- `docs/referencias/exploracao/weather_mist_before_after.mp4` — 12 s, 1280×360, lado a lado sem clima × neblina.
- `docs/referencias/exploracao/weather_mist_cycle.gif` — 12 s, 480×270, 8 fps, preview leve.
- `docs/referencias/exploracao/weather_mist_cycle_contact.png` — 6 quadros: 0, 1,5, 3, 5, 9 e 11 s.

## O que não foi verificado

- **O worktree continua misto:** a cena de exploração rodou no worktree principal e as capturas foram feitas nele, mas o worktree tem alterações não commitadas de outras sessões (combate/heal). Nada dessas sessões foi tocado.
- Calor ondulado, chuva/neve, cinza e distorção temporal não implementados.
- Performance não medida; é um `ColorRect` de tela cheia com uma amostragem de ruído.
- O vídeo usa `debug_duration = 10 s`; o ciclo real de 20–40 s não foi gravado inteiro.
- As duas gravações do antes/depois não têm o mesmo enquadramento exato (câmera/suavização); a comparação é de cor/nevoeiro.
- A neblina cobre a tela inteira, não só as células exploradas; a máscara/LOS/explorado continuam intactos.

## Estado

Código e documentação no worktree; commits locais; **nada publicado**. O worktree compartilhado segue misto, com alterações de outras sessões.
