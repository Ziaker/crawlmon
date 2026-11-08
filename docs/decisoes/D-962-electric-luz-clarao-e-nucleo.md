# D-962 — Electric: luz real, clarão no alvo e núcleo mais quente

- **Data:** 2026-11-07.
- **Frase literal do criador:** "1, 2 e 3" (sugestões de iluminação e cor da D-961).

## Decisão

1. **Luz real** (OmniLight3D dourada, sem sombra, alcance 4,5 m): cresce com a carga, tem um pico no disparo junto com o estouro de 0,2 s, fica fraca durante o voo e some no Post-impact. No impacto, uma luz por alvo, com pico que cai em 0,35 s.
2. **Clarão no alvo:** o corpo atingido pisca branco-dourado por cerca de 0,1 s (2 a 3 quadros), com o overlay de flash do jogo (`VfxLib.ensure_flash`). A cor do overlay volta a branco depois, porque é compartilhada com os outros golpes.
3. **Núcleo mais quente:** o núcleo fica quase branco (1,0; 0,99; 0,93) e o meio vira âmbar saturado (1,0; 0,68; 0,06), com mais contraste entre os dois.

Continua sem Glow (D-957). Nenhuma regra de jogo muda.
