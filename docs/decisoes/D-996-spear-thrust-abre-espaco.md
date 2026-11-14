<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-996 — Spear Thrust para mais longe para acertar com a ponta (regra de combate)

- **Data:** 2026-11-08.

## Frase literal do criador

> vc não colocou o que eu pedi do orc deslizar pra trás algumas unidades pra realizar o ataque, pode fazer isso ser uma gimmick mecanica dele de abrir espaço pra realizar o ataque se for necessário

## Decisão

1. **Regra de combate, por move (D-235: por `move_id`, não por personagem):** o Spear Thrust para a 2,6 + **1,4** unidades do alvo (as outras investidas param a 2,6), para a ponta da lança acertar em vez de atravessar.
2. O recuo só visual da D-993/D-994 sai (substituído por esta regra).

## Ambiguidades

- "algumas unidades": 1,4 foi escolhido pelo comprimento da lança (~1,3 m de meia lança); ajustar se preciso.
- "se for necessário": quando o atacante já está engajado colado ao alvo, ainda não recua; só a parada da corrida usa a nova distância.

## Estado

Implementado.
