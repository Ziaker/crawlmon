<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1114 — Intervalo de 0,2 s antes do avanço, sem congelar a animação

- **Data:** 2026-11-10
- **Área:** Overworld 3D / lab / ataque / animação
- **Origem:** pedido do criador sobre o timing do avanço.
- **Status:** **substituída por D-1120** na parte do intervalo (agora 0,12 s); o clipe `attack` a 2,0× e os VFX começando no dash continuam.

## O que o criador disse (literal)

> Dê um intervalo de .2 segundos antes dos personagens darem o avanço, sem congelar a animação

## Decisão

1. Jogador e inimigos esperam **0,2 s** antes de começar a mover no avanço.
2. O clipe `attack` começa no **início do intervalo** e continua rodando normalmente, a **2,0×** (D-1112), **sem congelar**.
3. Os VFX de corrida (speedlines, rastro no chão e dust) começam no **dash**, não no intervalo.
4. O telegraph de **0,4 s** do inimigo continua; o intervalo de **0,2 s** vem depois dele.
5. Timing, dano e transição não mudam além do atraso; vale para qualquer ator/lado (D-235).

## Implementação

- `OverworldAttackController`: nova fase `PRE_DASH` de 0,2 s para o jogador e para cada inimigo; o sinal de início toca o `attack`, e o `begin_dash` dos VFX só ocorre quando a fase vira `DASH`.
- `murky_forest_3d_lab.gd`: usa `is_player_attacking()` para travar o movimento e manter o clipe de ataque durante o intervalo.
- Testes: **65/65** controlador (inclui o pré-avanço de 0,2 s e o clipe a 2,0×); Gible no ponta a ponta.
- Vídeos: `overworld_attack_player/enemy/contact` e o combinado `overworld_attack_3cases` regravados com o intervalo.

## Estado

Implementado e testado; vídeos regravados; pendente aprovação visual. Sem commit e sem push.
