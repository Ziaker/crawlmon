<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1009 — Arco próprio do Swing: por cima da cabeça, inclinado 20° para a esquerda

- **Data:** 2026-11-08.

## Frase literal do criador

> vamos continuar tentando criar o efeito visual do ataque do pancham como eu queria ver
> Está quase perfeito a única coisa q precisa ser feita é ajustar o angulo do efeito, deitar ele para a esquerda da orientação da imagem uns 20 graus

## Decisão

1. O arco sai do lado direito da cabeça (na tela), passa por cima dela e desce pelo lado esquerdo até o alvo (giz branco). Segue o osso da cabeça (o corpo pula no golpe). "Direita" é a da câmera, igual nas duas vistas.
2. Todo o arco inclinado **20° para a esquerda da tela**, girando em torno do ponto de contato.
3. Quem usa o arco: mão que anda menos de 0,8 m no próprio referencial do corpo nos primeiros 0,2 s (medido: Pancham 0,38–0,60; Abra 1,00 → continua seguindo a mão). Antes a medida variava entre execuções.

## Estado

Implementado para revisão.
