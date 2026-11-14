<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-965 — Gravação limpa, esfera que cresce no pós-wind-up, carga centrada e cores mais claras

- **Data:** 2026-11-07.

## Frases literais do criador

> vc tem que tirar os huds e os props do ambiente pra poder ver melhor também...

> e por sinal, durante o pós wind-up (no caso da animação de intervalo que o personagem faz para então realizar o disparo, após o wind-up, o prelude do release), eu queria que a esfera de choque crescesse.

> o problema se mantém, não da pra ver direito o move ainda e também n parece que está na frente do personagem (além de não estar alinhado centralmente a frente dele), o problema maior está nas cores, shaders e iluminação do efeito visual, é dificil de ver, precisa ser mais claro (em ambas cores e entendimento)

## Decisão

1. **Gravação de conferência limpa:** a sala de VFX ganhou `--clean`, que esconde o HUD da batalha e os props da arena (pilares, paredes, detritos, poeira). Chão, luzes e personagens ficam. `record_move_video.py` aceita `--clean` e `--cam N`. Só ferramenta de debug; o jogo não muda.
2. **Pós-wind-up (prelúdio do release):** a esfera de choque continua **crescendo** durante a carga segurada, de 0,32 m até 0,62 m em 0,8 s (o tempo medido), e então vira o disparo.
3. **Centrada:** a carga fica no eixo do tiro, a partir da **origem do próprio modelo**, não do centro da caixa (a cauda desviava a caixa).
4. **Mais claro:** núcleo amarelo-pálido largo, meio amarelo elétrico (em vez de âmbar), sem borda translúcida escura, halo mais forte (alpha 0,45), cintilação que quase não escurece e luzes 1,5× mais fortes. Continua sem Glow.
