<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1252 — Cascos de bronze, prata e ouro

- **Data** — 2026-11-16
- **Área** — Economia / moedas / recompensas
- **Estado** — Regra de design aprovada. Implementação e balanceamento pendentes.
- **Relacionadas** — [D-1250](D-1250-hub-loja-e-economia-de-expedicao.md), [D-1251](D-1251-moedas-exploracao-e-economia-inicial.md).

## Frase literal do criador

> vao ser 3 tipos de moeda, Cascos de bronze, cascos de prata e cascos de ouro, Bronze Shell Silver Shell e Golden shells
>
> bronze shells dropam de inimigos normais, silver shells sao mais raros em inimigos e golden shells sao apenas de recompensas e valem muito mais

## Decisão

| Tipo | Nome em inglês | Obtenção e valor |
| --- | --- | --- |
| Cascos de bronze | Bronze Shell | Drop de inimigos normais. |
| Cascos de prata | Silver Shell | Drop mais raro de inimigos. |
| Cascos de ouro | Golden shells | Exclusivos de recompensas e com valor muito superior ao dos outros tipos. |

A D-1251 define recompensas e segredos dos mapas como a principal fonte de moedas, com drops de inimigos de baixo rendimento e economia difícil no início.

## Pendências

- Valores de cada tipo. O saldo comum e as equivalências fixas foram aprovados em [D-1253](D-1253-saldo-comum-e-balanceamento-dos-cascos.md).
- Chances, quantidades, inimigos elegíveis para prata e recompensas específicas de ouro.
- Como a loja cobra e como cada tipo de casco aparece no saldo.
