<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1016 — Drain Spear: lança à frente, deita só no prelúdio, ritmo do clipe, sem aviso Dread

- **Data:** 2026-11-09.

## Frase literal do criador

> faça com que estes circulos sumam .25 segundos depois de surgirem
> o disparo da lança ainda ocorre mt mais cedo do que devia, além disso a posição dela de pé está dificil de se ver, tem que ficar na verdade na frente do personagem um pouquinho pro lado pra aparecer na visão do jogador
> 2 - a lança ainda deita no fim do wind-up, corrige isso também, é pra ela só deitar quando o personagem estiver no preludio do ataque
> 3 - como é um move mid-range não melee, não é necessário haver o efeito de dread
> 4 - o ataque ainda ocorre mt mais rápido do que devia

## Decisão

1. Círculos da coroa giratória somem 0,25 s depois de surgir.
2. Lança em pé **à frente** do corpo (no sentido do alvo), um pouco para o lado da tela; fica em pé durante o wind-up e o deslocamento e só deita no **prelúdio** (0,2 s).
3. O contato segue o tempo do **próprio clipe de ataque** (antes 0,45 s forçados, que cortavam a animação): o golpe fica mais lento e o disparo acompanha.
4. Moves mid-range não mostram o aviso estilo Dread (só corpo a corpo).

## Estado

Implementado para revisão.
