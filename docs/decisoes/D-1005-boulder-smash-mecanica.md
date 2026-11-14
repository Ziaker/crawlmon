<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1005 — Boulder Smash (Tackle do Cyclops): mecânica

- **Data:** 2026-11-08.

## Frase literal do criador

> tem 20% de chance + LK de causar -1DEF ao contato com os efeitos visuais de tarunda no impacto caso o efeito seja acionado com sucesso. De resto funciona como um tackle normal

Respostas: visual = **Rakunda** (o de -DEF que existe no jogo); "1,2 fisico".

## Decisão

1. Poder **1,2**, elemento **Físico** (antes 1,5 Terra); o resto como o Tackle (corpo a corpo, wind-up 1,5 s, 2 ATB).
2. No contato com sucesso: chance de **20% + diferença de LUK** (regra D-143/D-146) de **-1 DEF** no alvo.
3. Quando o efeito acontece, toca o **visual do Rakunda** no alvo. Se a DEF já está no mínimo, não aplica nem toca.
4. Mantém o contato 0,15 s mais tarde (D-1003).

## Estado

Implementado.
