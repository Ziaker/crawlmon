<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1143 — Dano físico acompanha a STR alocada no level-up

- **Data:** 2026-11-10
- **Área:** Combate / atributos / progressão.
- **Origem:** ordem direta do criador.
- **Estado:** regra aprovada; implementação nesta rodada.

## Declaração literal do criador

> "ENTÃO CORRIJA"

## Regra aprovada

- Personagens normais (criados pelo catálogo) derivam o ataque físico da **STR efetiva**, não de um valor congelado na criação.
- `sync_effective_stats()` passa a atualizar `base_attack` quando o personagem é "attribute-driven".
- Investir pontos em STR no level-up aumenta o dano físico; buffs de ATK continuam aplicando os estágios por cima.
- **Overrides de teste** (`Combatant.new` direto, `opts["attack"]`, `test_bare`) preservam o ataque explícito e não são sobrescritos pelo sync.
- MAG já era dinâmica desde a D-1140; esta decisão corrige a assimetria do lado físico.

## Ambiguidades em aberto (perguntar antes de agir)

- Nenhuma para o escopo desta correção. A fórmula de dano físico continua a mesma; só o valor-base passa a acompanhar a STR efetiva.
- A resistência física por VIT continua pendente (D-125/D-130).

## Estado no código

- Flag `uses_effective_strength` no `Combatant`.
- `CharacterFactory` liga a flag no caminho normal e desliga em overrides de teste.
- `sync_effective_stats()` atualiza `base_attack = str` quando a flag está ligada.
- Teste dedicado `tests/battle/test_d1143_str_levelup.gd` — **D1143_PASS**.
