<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1157 — Fase 2: schema de afinidade com `WEAK` ativo

- **Data:** 2026-11-11
- **Área:** Combate / elementos / dados / arquitetura.
- **Origem:** o criador mandou auditar a Fase 1 e começar a Fase 2.
- **Estado:** implementado e testado; comportamento de dano preservado (D-1152 passa 44/44).

## Declaração literal do criador

> "comece a fase 2 depois de auditar a fase 1 por completo em busca de erros"

## Regra aprovada

- Criar o vocabulário `Affinity { NEUTRAL, WEAK, RESIST, NULL, REPEL, DRAIN }`.
- Cada espécie pode declarar `affinities: Dictionary` (elemento int → `Affinity.Type`).
- Nesta fase **só `WEAK` altera dano**. `RESIST`, `NULL`, `REPEL` e `DRAIN` existem no schema, mas são neutros até a Fase 3.
- `Combatant.affinity_for(element)` e `is_weak_to(element)` são a porta de leitura.
- `DamageMath.affinity_multiplier(kind)` traduz a afinidade em multiplicador; `offense()` e `resolve_offense()` recebem esse multiplicador em vez do antigo `weak: bool`.
- **Transição:** `affinities` é preenchido a partir de `weaknesses` (cada fraqueza vira `WEAK`), mas a leitura de `WEAK` ainda usa a lista `weaknesses`. Isso mantém VFX room, testes e ferramentas de debug que editam `weaknesses` funcionando. A Fase 3 inverte a fonte.
- Nenhum `.tres` de espécie precisou ser editado: a tabela é derivada no `CharacterFactory`.
- `weaknesses` continua existindo para UI, texto e compatibilidade.

## O que a Fase 2 NÃO faz

- Não implementa Resist/Null/Repel/Drain.
- Não muda o multiplicador de fraqueza (continua 1,5).
- Não muda VIT física.
- Não corrige a divergência `info.dmg` × HP perdido.
- Não corrige o bug pré-existente do Brick Break/Guard break (D-272), que não é da Fase 2.

## Auditoria da Fase 1 e correções feitas antes da Fase 2

- `BattleAI._damage_to` tinha ganhado mínimo 1 e mudava o valor antigo em `estimate=1` contra `def_buff +5` (0 → 1). Corrigido com `final_damage(..., min_one=false)`; golden cobre o caso.
- `status_panel.gd` passou a usar `DamageMath.DEF_STAGE` em vez de `0.25` hardcoded.
- `move_inspection_modal.gd` deixou de usar a heurística antiga `kind == CAST` em variáveis internas.
- `Skill.legacy_catalog_skills()` teve Megido corrigido para `MYSTIC`, alinhado à D-1144; o teste de catálogo voltou a passar.
- O bug pré-existente de Guard break do Brick Break foi registrado, mas **não** alterado sem decisão.

## Complemento D-1158 (Fase 3)

- `affinities` passou a ser autoritativo para entradas explícitas, inclusive `NEUTRAL` e `WEAK`; `weaknesses` é fallback.
- `RESIST` entrou ativo a 0,5×. `NULL`, `REPEL` e `DRAIN` continuam schema-only.
- Ver `docs/decisoes/D-1158-fase-3-resist.md`.

## Estado no código

- `scripts/data/affinity.gd` — enum, nomes e multiplicador (só WEAK).
- `scripts/data/character_data.gd` — `affinities: Dictionary`.
- `scripts/combat/combatant.gd` — `affinities`, `affinity_for()`, `is_weak_to()`.
- `scripts/combat/character_factory.gd` — preenche a tabela a partir de `data.affinities` + `weaknesses`.
- `scripts/combat/damage_math.gd` — `affinity_multiplier()`; `offense`/`resolve_offense` usam multiplicador.
- `scripts/combat/battle.gd`, `battle_ai.gd`, `battle_scene.gd`, `skill_info_panel.gd` — leem `is_weak_to()`.
- Teste: `tests/battle/test_d1157_affinity_schema.gd` — **D1157_PASS** (32 asserções).
- Golden: `tests/battle/test_d1152_damage_golden.gd` — **D1152_PASS** (44 asserções, incluindo os dois casos de IA e o caso RESIST).
- Regressões: D-1140, D-1142, D-1143, D-1144, D-1145, D-032, D-1005, Drain Spear, D-1073, D-1025, D-977, D-159, D-1062, catálogo, fábrica, encounter generation, attribute math, UI e LevelUpHUD passaram.
- Falha pré-existente fora do escopo: `test_experience_and_victory.gd` (piso de 20 MP do Abra, D-413).
- Nada de commit/push sem autorização (D-022).
