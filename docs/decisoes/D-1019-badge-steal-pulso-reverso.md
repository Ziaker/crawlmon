<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1019 — Badge Steal: pulso reverso

- **Data:** 2026-11-09.

## Frase literal do criador

> perfeito em ambos, agora vamos para o overhaul do efeito visual alternativo pelo badge steal
> opção 3

## Decisão

Quando há roubo, no lugar das 8 luzes/correntes (D-441, D-1014): uma onda de choque azul sai do alvo para trás (0,15 s), é "rebobinada" e se contrai numa esfera no ponto de contato (0,25 s), é puxada pela linha da lança até o atacante deixando um rastro (0,45 s) e estoura numa aura curta em volta dele (0,35 s). Medidas pelo contato e pelo centro real do atacante (D-235). Leque reverso e badges da HUD continuam.

## Estado

Implementado para revisão.
