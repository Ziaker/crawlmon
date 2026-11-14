<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1070 — ATB cheio acelera a recuperação de MP em 1,75x

- **Data:** 2026-11-09.
- **Área:** Combate / MP / HUD / debug.
- **Altera:** a D-413 e a D-1062 (o pulso de MP continua de 8 s; o relógio dele corre mais rápido com o ATB cheio).

## Frase literal do criador

> faca com que estar com atb cheio acelere o ritmo de recuperacao de MP em 1.75x e deixe claro com 2 V (de pe) juntos acima do bloco de MP, inclusive adicione no debug opcoes de adicionar atb, atb cheio, atb zerado, reducao de atb tambem

Esclarecimentos do criador:

> (formato do ícone) "Seta p/ cima (^^)" · "sao assim ⌃ ⌃ so que mais juntos"

## Decisão

1. **ATB cheio** = os 5 blocos cheios. Enquanto isso valer, o cronômetro do pulso de MP corre **1,75x** mais rápido (8 s viram ~4,57 s). Vale para todos (aliados e oponentes). Sem ATB cheio, tudo como antes.
2. **Sinal no cartão:** dois chevrons para cima (⌃ sobre ⌃), bem juntos, acima do bloco de MP, enquanto o ATB estiver cheio; pulsam em sequência para cima. Os textos "+N in Xs" mostram o tempo restante já com o ritmo.
3. **Debug:** adicionar ATB (+1 bloco), reduzir ATB (-1 bloco), ATB cheio e ATB zerado.
   - Painel F1 no jogo: `]` +1, `[` -1, `Shift+]` cheio, `Shift+[` zerado, no lutador escolhido com Tab. O F2 (ATB cheio para todos) continua.
   - Sala de VFX: quatro botões na grade de status ("ATB +1", "ATB -1", "ATB cheio", "ATB zerado").

## Ambiguidades (escolhas do assistente, a confirmar)

- As teclas do debug e o "1 bloco" por passo foram escolha do assistente.
- O sinal aparece só no cartão do jogador/aliado (as etiquetas dos oponentes não têm o bloco de MP).

## Estado

Implementado (2026-11-09). Teste: `tests/battle/test_d1070_atb_full_mp_regen.gd`.
