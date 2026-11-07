# D-386 — Chuva implementada: gotas no mundo, respingos no chão e fade

- **Data:** 2026-11-07
- **Área:** Exploração / visual / clima
- **Origem:** o criador pediu para prosseguir para a chuva agora, depois da neblina.
- **Status:** implementada com vídeos; nada publicado.

## O que o criador disse (literal)

> prossigamos pra chuva agora

E, na proposta original (D-362):

> uma animação de chuva caindo no chão com efeitos visuais

## Decisão

1. **Mesmo controller:** a chuva é um evento visual de ambiente com **20% por andar**, no máximo um por andar, **20–40 s**, fade de 2 s e o mapa de biomas de D-362. Não altera nenhuma regra (D-381).
2. **Gotas:** `CPUParticles2D` em espaço de mundo (`local_coords = false`), emissor acima da câmera/posição do jogador, retângulo largo, textura de risco azul-claro e gravidade. O emissor acompanha o jogador para cobrir a tela, mas as gotas já emitidas ficam no mundo.
3. **Respingos:** `CPUParticles2D` com `EMISSION_SHAPE_POINTS`; os pontos são as células de **chão** em volta do jogador (paredes ficam fora), com anéis curtos. Não há colisão real de partícula com o tilemap; o respingo é dirigido pelo mapa.
4. **GL Compatibility:** `CPUParticles2D`; sem GPUParticles, trails ou sub-emitters (D-308).
5. **Fora do Motion Composer** (D-383). Sem áudio; só visual.
6. A ordem de D-362 era neblina → calor → chuva; o criador pediu chuva agora; o calor foi implementado em D-387.

## Testes

- `tests/exploration/test_weather_roll.gd` (headless): 4th Station escolhe **chuva**; as demais checagens continuam; **WEATHER TESTS: OK**.
- Vídeo do ciclo: `docs/referencias/exploracao/weather_rain_cycle.mp4` — 12 s, 1280×720, 30 fps, com `debug_duration = 10 s` (2 s fade-in + 6 s chuva + 2 s fade-out). No jogo, 20–40 s.
- Antes/depois: `weather_rain_before_after.mp4`; GIF `weather_rain_cycle.gif`; contato `weather_rain_cycle_contact.png`; PNG `weather_rain_before_after.png`.
- A cena rodou no worktree principal; sem erro de script ou de shader.

## O que não foi verificado

- Performance: 220 gotas + 90 respingos em CPU; não medido.
- Colisão real das gotas com paredes/teto; o respingo é aproximado pelas células de chão.
- O vídeo força chuva em **Temporal Tower** (bioma de demonstração); no jogo ela sai nos biomas de chuva de D-362.
- O ciclo real de 20–40 s não foi gravado inteiro; o vídeo usa 10 s.
- Neve, cinza e distorção temporal continuam pendentes.

## Estado

Código, docs e vídeos no worktree; commits locais; **nada publicado**.
