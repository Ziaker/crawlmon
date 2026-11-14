<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1003 — Boulder Smash é o Tackle do Cyclops; rastro mais suave e contato 0,15 s depois

- **Data:** 2026-11-08.

## Frase literal do criador

> o cyclips só poderia ter um pouco menos de opacidade nos seus rastros, e o hit está ocorrendo antes dele fazer o movimento completo, ao esmagar no caso, é uma mudança bem pequena nessa, tipo .15 segundos de diferença
> ok, mantenha como o tackle gimmick dele assim como o do orc, vamos mexer na sua mecânica depois, faça o que eu pedi originalmente

## Decisão

1. **Boulder Smash** é a variante de Tackle do Cyclops (D-998); a trait/mecânica será definida depois.
2. O rastro de arma grossa fica menos opaco (borda 0,95 → 0,55; interior 0,35 → 0,2).
3. O contato do Boulder Smash acontece **0,15 s mais tarde**, depois da esmagada completa (muda o tempo do golpe desse move).
4. Orc (Spear Thrust) aprovado.

## Estado

Implementado.
