# D-384 — Neblina implementada: camada 2D, rolagem de 20% e capturas

- **Data:** 2026-11-06
- **Área:** Exploração / visual / clima
- **Origem:** execução da primeira leva aprovada em D-381/D-382/D-383, com a ordem do criador de usar as skills Godot instaladas.
- **Status:** **neblina implementada** no worktree; calor, chuva/neve, cinza e distorção temporal ainda não. Nada publicado.

## O que foi implementado

1. **Shader `shaders/weather_mist.gdshader`:** véu 2D de tela cheia, com `mist` (0–1), `mist_color` vindo do ambiente do bioma, ruído do próprio bioma, drift lento, densidade e vinheta. Fade de 2 s na entrada e na saída. É uma camada de ambiente, **fora do Motion Composer** (D-383).
2. **`scripts/dungeon/weather_controller.gd`:** rolagem determinística de **20% por andar** (1 em 5) usando `dungeon_seed` + `visual_floor`; no máximo **um evento por andar**; duração **20–40 s**; início **0,8 s** depois de o andar carregar; `_played` evita repetir o mesmo evento ao voltar de uma batalha. O tipo sai do mapa de D-362; **só a neblina está implementada**.
3. **`scripts/dungeon/exploration.gd`:** instancia o controller depois da névoa de guerra e antes da vinheta. A camada fica em `CanvasLayer` 1, abaixo do diálogo (15) e dos menus (10), com `light_mask = 0`.
4. **Sem regra:** não altera movimento, combate, colisão, câmera, geração, raio de visão 7,5, LOS nem o explorado permanente. A neblina é um véu de **tela cheia**; ela não mexe na máscara de explorado, apenas cobre a cena com baixa alpha.
5. **Debug de captura:** `debug_force = "mist"` força a neblina; `debug_disable = true` desliga o clima para o "antes". Nenhum dos dois é usado pelo jogo normal.

## Testes

- `tests/exploration/test_weather_roll.gd` (headless): **194/1000 = 19,4%** de rolagens em 1000 andares; seed 2/andar 1 passa e escolhe neblina em Temporal Tower; os seis biomas testados retornam um tipo; **WEATHER TESTS: OK**.
- `scratch/test_weather_roll.gd` (auxiliar): mesma rolagem e tipos por bioma.
- Captura forçada: `scratch/weather_mist.png`.
- Captura pela **rolagem real** (seed 2, andar 1): `scratch/weather_mist_roll.png`.
- Antes/depois: `docs/referencias/exploracao/weather_mist_before_after.png` (mesmo seed/andar, sem clima × com neblina).
- O shader compilou e desenhou no **GL Compatibility** durante a captura; não houve erro de shader.

## O que não foi verificado

- **O jogo no worktree principal não rodou:** há erros de parse de outras sessões em `scripts/ui/battle_hud.gd` (`_slant`) e `scripts/combat/fx/heal_gain_mark.gd` (`_fit_to_camera`). A captura foi feita num **worktree descartável em HEAD**, com um patch de teste somente em `heal_gain_mark.gd`; os arquivos de batalha do worktree principal **não** foram tocados.
- Calor ondulado, chuva/neve, cinza e distorção temporal não implementados.
- Performance não medida; é um `ColorRect` de tela cheia com uma amostragem de ruído.
- Não há vídeo; as provas são capturas estáticas.
- O ciclo completo de 20–40 s não foi observado até o fade-out numa captura; o Tween é padrão.
- A neblina cobre a tela inteira, não só as células exploradas; a máscara/LOS/explorado continuam intactos.

## Estado

Código e documentação no worktree; commits locais; **nada publicado**. O worktree compartilhado segue misto, com alterações de outras sessões.
