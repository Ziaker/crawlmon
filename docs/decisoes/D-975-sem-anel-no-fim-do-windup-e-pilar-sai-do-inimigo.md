<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-975 — Sem anel no fim do wind-up; o pilar do Electric sai do inimigo em 0,25 s

- **Data:** 2026-11-08.

## Frase literal do criador

> ok agora uma remoção que não tem haver com o move, tem um anel que surge nas costas dos personagens quando eles terminam a wind-up dos seus moves, tem como remover isso? não precisa criar video para este caso.
>
> depois disso eu quero que vc faça com que no contato, ao invés do pilar de eletricidade/coroa simplesmente surgir, ele sair do inimigo ao longo de .25 segundos e realizar seu tempo de vida normalmente até sumir

## Decisão

1. **Removido** o anel vertical na cor do elemento que fechava (1,8 → 0,3) na altura do corpo do atacante no fim do wind-up dos moves à distância (`fx_motion.gd`, fase do disparo). Vale para todos os moves. Sem vídeo, a pedido.
2. **Pilar do Electric:** no contato, as coroas **saem de dentro do inimigo** ao longo de 0,25 s (nascem pequenas no centro do corpo e crescem até a volta dele); depois seguem a vida normal (D-973/D-974) até sumir. Duração total: 0,25 s + 1,0 s.

## Estado

Implementado.
