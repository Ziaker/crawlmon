<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-092 — R45-Q2 (2A): Evade cobre impactos simultâneos

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 45
- **Origem:** decisão expressa do criador, R45-Q2.
- **Estado:** decisão de design aprovada; implementação não verificada.

## Declaração literal do criador

> 2A — Se dois inimigos atacarem o mesmo personagem quase simultaneamente, como funciona o Evade? Um Evade bem-sucedido pode evitar ambos os ataques se seus impactos coincidirem com a esquiva.

## Regra aprovada

Um Evade bem-sucedido pode evitar **ambos os ataques de dois inimigos** quando os impactos dos dois coincidirem com a esquiva do personagem. Isso não exige dois Evades separados para esses impactos coincidentes.

## Referências e limites

- **Decisões relacionadas:** D-006; D-021; D-030; D-034; D-075; D-076.
- **Limite / pendência:** A extensão temporal exata de coincidência e a aplicação a mais de dois atacantes não foram especificadas; não assumir invulnerabilidade irrestrita.
- **Escopo:** registro documental somente; nenhum código, VFX, teste ou dado de jogo modificado.
