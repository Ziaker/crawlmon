<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-989 — Efeito da janela de Evade: mais contraste e brilho, um pouco à esquerda do alvo

- **Data:** 2026-11-08.

## Frase literal do criador

> está otimo, mas devia ser ter ainda mais contraste e brilho, não é pra ser algo difícil de se ver, deixe um pouquinho mais pra esquerda (no pov do gible)

## Decisão

1. Mais brilho e contraste: anel mais grosso e dobrado, brilho em volta mais largo, preenchimento suave dentro do anel (como no Dread), raios mais largos e longos com espinha branca, núcleo maior e dobrado.
2. Posição um pouco **à esquerda do alvo** (do ponto de vista de quem recebe o golpe, olhando para o atacante). Calculado pelo eixo real atacante→alvo, nunca por espécie ou lado (D-235): vale igual na vista normal e na espelhada.

## Estado

Implementado para revisão.
