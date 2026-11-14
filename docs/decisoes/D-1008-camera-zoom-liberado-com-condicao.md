<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1008 — Câmera: zoom/aproximação liberados, sem tirar nada de quadro; começar pela área segura

- **Data:** 2026-11-08.

## Frase literal do criador

> 1 - eu libero DESDE QUE NÃO FAÇA COISAS FICAREM FORA DA CAMERA, o jogador precisa estar vendo o ambiente
> 2 - 1

## Decisão

1. **Altera D-020 em parte:** zoom/aproximação da câmera passam a ser permitidos **desde que nada fique fora de quadro** (inimigos, aliados, ambiente da luta). O tremor continua só no K.O. (D-049).
2. O plano começa pela **etapa 1: enquadramento pela área segura** (a parte da tela não coberta pela HUD).

## Estado

Registrado; implementação a seguir.
