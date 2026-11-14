<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-988 — A janela de Evade fica no momento em que o atacante se ergue (corrige D-987)

- **Data:** 2026-11-08.

## Frase literal do criador

> ainda está acontecendo mt cedo o efeito, está ocorrendo antes do personagem se erguer, antes do prelude, está incorreto

## Medição

No Tackle do Abra a fase de golpe dura 0,88 s: agacha (0–0,35 s), **se ergue** com os braços para cima (~0,37–0,63 s), desce o golpe e faz o contato (0,88 s). D-987 pôs a janela no agachamento (0–0,25 s), cedo demais.

## Decisão

1. A janela de Evade (0,25 s, sempre perfeita) é a que **termina 0,25 s antes do contato** (`Battle.PRELUDE_GAP`): no Tackle, de 0,38 a 0,63 s, quando o atacante se ergue.
2. Golpe mais curto que 0,5 s: a janela recua até começar no início do golpe (nunca fica vazia).
3. A IA e o efeito estilo Dread seguem a mesma janela.

## Ambiguidade

- A regra é uma posição fixa em relação ao contato, medida num golpe (Tackle). Outros clipes podem se erguer em outro momento; conferir em outros moves.

## Estado

Implementado.
