# D-1153 — Fase 1: módulo único de dano (`DamageMath`)

- **Data:** 2026-11-11
- **Área:** Combate / dano / arquitetura.
- **Origem:** o criador mandou auditar a Fase 1 com agentes e começar.
- **Estado:** implementado e testado; comportamento preservado (D-1152 passa 44/44).

## Declaração literal do criador

> "use seus agentes para auditar a fase 1 e comece"

## Regra aprovada

- As etapas puras do dano passam a viver num único módulo, `scripts/combat/damage_math.gd` (`class_name DamageMath`).
- `DamageMath` não rola RNG, não lê estado mutável do `Battle` e não altera `Combatant`. O chamador passa os valores já resolvidos no instante correto.
- Funções:
  - `step_multiplier(attacker_step, target_step)`;
  - `offense(attack_stat, power, weak, crit, step_mult)` — **um único `roundi`**;
  - `drain(flat, mag, spi)` — Drain Spear;
  - `mitigate_magic(amount, wis)` — WIS;
  - `resolve_offense(...)` — entrada única que escolhe Drain ou offense+WIS;
  - `apply_guard(amount, reduction)`;
  - `apply_defense(amount, def_buff)` e `final_damage(amount, def_buff, fixed)`;
  - `base_damage(stat, power, min_one)` — só UI sem alvo.
- Chamadores migrados: `Battle.estimate_damage`, `Battle._hit`, `Combatant.take_damage`, `BattleAI._damage_to`, `battle_debug`, `skill_info_panel`, `move_card`, `move_inspection_modal` e `status_screen`.
- **Exceção da IA:** `BattleAI._damage_to` usa `final_damage(..., min_one=false)` para preservar o cálculo antigo, que podia prever 0 de dano contra `def_buff +5` com estimate 1. `take_damage` continua com mínimo 1.
- `battle_hud` continua consumindo `info["dmg"]`; não foi alterado.
- A ordem atual foi preservada: ofensa → fraqueza/crítico/passos → WIS → Guard → escudo → `def_buff` (em `take_damage`).
- `info["dmg"]` continua **pré-`def_buff`**; a divergência de HUD da D-1152 não foi corrigida nesta fase.
- Constantes de `Battle` (`WEAKNESS_MULT`, `CRIT_MULT`, `DMG_PER_STEP`, `GUARD_REDUCTION`) passaram a apontar para `DamageMath`, para não existirem duas fontes.

## O que NÃO foi feito

- Nenhuma afinidade nova (Resist/Null/Repel/Drain) — isso é a fase seguinte.
- Nenhuma mudança de VIT física.
- Nenhuma mudança de números, ordem, RNG, crítico, esquiva, Guard, ARMOR, escudo, Drain Spear ou Burn.
- Nenhuma mudança de UI além de trocar a fórmula-base duplicada por `DamageMath.base_damage`.

## Estado no código

- `scripts/combat/damage_math.gd` — módulo novo.
- `scripts/combat/battle.gd` — constantes aliases + `estimate_damage`/`_hit` usando `DamageMath`.
- `scripts/combat/combatant.gd` — `take_damage` usando `DamageMath.final_damage`.
- `scripts/combat/battle_ai.gd` — `_damage_to` usando `DamageMath.final_damage`.
- UI: `move_card.gd`, `move_inspection_modal.gd`, `status_screen.gd` usando `DamageMath.base_damage`.
- Teste: `tests/battle/test_d1152_damage_golden.gd` — **D1152_PASS** (44/44) depois da migração.
- Regressões: D-1140, D-1142, D-1143, D-1144, D-1145, D-032, D-1005, Drain Spear, D-1073, attribute math, StatusScreen, HUD badges, Move icons e LevelUpHUD passaram.
- Falha pré-existente fora do escopo: `test_experience_and_victory.gd` espera +1 MP no level-up, mas o piso de 20 MP do Abra (D-413) mantém 20. Não foi alterado.
- Nada de commit/push sem autorização (D-022).
