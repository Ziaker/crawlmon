<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-387 — Calor ondulado implementado: distorção de tela, tom âmbar e poeira

- **Data:** 2026-11-07
- **Área:** Exploração / visual / clima
- **Origem:** o criador aprovou os três eventos em D-381; depois da neblina (D-384/D-385) e da chuva (D-386), pediu para seguir com o calor e disse "me surpreenda".
- **Status:** implementado com vídeos; nada publicado.

## O que o criador disse (literal)

> sim, me surpreenda

E, na proposta original (D-362):

> um overlay de calor ondulado meio earthbound

## Decisão

1. **Mesmo controller:** o calor é um evento visual de ambiente com **20% por andar**, no máximo um por andar, **20–40 s**, fade de 2 s e o mapa de biomas de D-362. Não altera nenhuma regra (D-381).
2. **Overlay 2D de tela cheia**, fora do Motion Composer (D-383): shader com duas senoides de UV (uma larga, uma fina), deslocamento horizontal e um pouco vertical, **mais forte perto do chão**, RGB shift leve e color grade âmbar/rosado. `amount` 0–1 faz o fade.
3. **A surpresa:** uma **poeira de calor** bem esparsa (`CPUParticles2D`, ~32 partículas) subindo devagar, em espaço de mundo, com fade. É puramente visual, não tem regra e é distorcida pelo próprio overlay; fica abaixo da névoa de guerra.
4. **Biomas de calor:** barren valley, dark wasteland, deep boulder quarry, deep limestone cavern, limestone cavern. O vídeo força calor em Temporal Tower para demonstração.
5. **Sem regra:** movimento, combate, colisão, câmera, geração, raio de visão 7,5, LOS e explorado permanecem intactos. Sem áudio.
6. Ordem: neblina (D-384/D-385) → chuva (D-386) → calor (D-387); neve, cinza e distorção temporal continuam pendentes.

## Testes

- `tests/exploration/test_weather_roll.gd` (headless): o bioma de calor escolhe `heat`; as demais checagens continuam; **WEATHER TESTS: OK**.
- Vídeo do ciclo: `docs/referencias/exploracao/weather_heat_cycle.mp4` — 12 s, 1280×720, 30 fps, com `debug_duration = 10 s` (2 s fade-in + 6 s calor + 2 s fade-out). No jogo, 20–40 s.
- Antes/depois: `weather_heat_before_after.mp4`; GIF `weather_heat_cycle.gif`; contato `weather_heat_cycle_contact.png`; PNG `weather_heat_before_after.png`.
- Sem erro de shader/script na captura.

## O que não foi verificado

- Performance do screen texture + senoides + poeira; não medido.
- O vídeo força calor em **Temporal Tower**; no jogo ele sai nos biomas de calor de D-362.
- O ciclo real de 20–40 s não foi gravado inteiro; o vídeo usa 10 s.
- O screen texture foi testado no GL Compatibility nesta captura, não em outras GPUs.
- Neve, cinza e distorção temporal continuam pendentes.

## Estado

Código, docs e vídeos no worktree; commits locais; **nada publicado**.
