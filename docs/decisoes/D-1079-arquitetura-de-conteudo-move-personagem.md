# D-1079 — Arquitetura de conteúdo: Move e Personagem como pacotes

- **Data:** 2026-11-09
- **Área:** Arquitetura / Dados / Moves / Personagens / VFX / Processo
- **Origem:** resposta do criador à proposta de arquitetura apresentada na conversa.
- **Estado:** aprovada; Etapa 1 autorizada (dados + catálogos, comportamento preservado).

## Frase literal do criador

> "sigo suas recomendações"

## Decisão

1. **Identidade estável:** todo Move tem um `id` próprio (snake_case, estável) e um `display_name` separado. O nome de exibição deixa de ser a chave de roteamento; `BattleSpace.move_id()` e os aliases PT/EN ficam apenas como compatibilidade temporária.
2. **Definições são Resources; estado de runtime é RefCounted/Node.** `MoveData` e `CharacterData` são Resources `.tres` somente-leitura. `Combatant`, `Incoming` e o `Skill` de batalha continuam sendo objetos de runtime.
3. **Um Move = um pacote.** Cada Move fica em `res://content/moves/<id>/` com:
   - `move.tres` (`MoveData`);
   - `behavior.gd` opcional, só para regras próprias;
   - `vfx.gd` opcional, com as fases reais do `Battle`;
   - `icon.svg` e textos.
4. **Um Personagem = ficha + loadout + perfil de modelo.** Cada personagem fica em `res://content/characters/<id>/` com `species.tres` (`CharacterData`), `loadout.tres` e `model_profile.tres`.
5. **Catálogo explícito, sem varredura de pasta em runtime.** `content/catalogs/move_catalog.tres` e `content/catalogs/character_catalog.tres` são gerados/atualizados em tempo de edição. Nada de `DirAccess` em runtime, que quebra no export.
6. **Comportamento por `move_id`, nunca por personagem** (D-235). A variante de Tackle com trait fica no Move da variante (D-998), não no personagem.
7. **A lógica continua dona do relógio** (D-019/D-1040). O dispatcher de comportamento e os módulos de VFX não podem criar relógio paralelo; eles só reagem ao estado do `Battle`.
8. **VFX por `vfx_key`/módulo do Move**, com as quatro fases da D-308 quando a ficha visual pedir. O Motion Composer continua auxiliar e opcional (D-1030).
9. **Ordem de implementação aprovada:**
   - Etapa 0: baseline da suíte atual.
   - Etapa 1: `MoveData`, `CharacterData`, catálogos e wrappers de compatibilidade; **sem mudar regra, tempo, dano ou visual**.
   - Etapa 2: dispatcher de comportamento por `move_id`; remover os `if/matches` de `battle`, `planner` e `battle_ai`.
   - Etapa 3: registro de VFX por Move; unificar `scripts/combat/fx` e `scripts/vfx`; só com aprovação visual e vídeo normal/espelhado.
   - Etapa 4: dividir os arquivos grandes por responsabilidade.
   - Etapa 5: mover pastas, limpar duplicatas de documentação e ajustar filtros de export.
   - Etapa 6: testes-contrato “novo Move” e “novo Personagem”.
10. **Nada de push sem autorização expressa** (D-022). Nenhuma alteração de regra de jogo é autorizada por esta decisão.

## Ambiguidades em aberto

Nenhuma para a Etapa 1. As decisões de detalhe das Etapas 2–6 (nomes finais de classes, divisão exata de arquivos, migração física das pastas) serão perguntadas antes de cada etapa.

## Estado no código

**Etapa 1 implementada e testada** com comportamento idêntico:
- `MoveData`/`MoveCatalog` em `scripts/data/` e `content/moves/<id>/move.tres` (38 Moves).
- `CharacterData`/`CharacterLoadout`/`CharacterModelProfile` e `CharacterCatalog` em `content/characters/<id>/` (6 personagens).
- `CharacterFactory` constrói `Combatant`; `EnemyFactory`, `GameState._build_party` e `DqtTestParty` delegam a ele.
- `Skill` lê `MoveData`; `Skill.all_catalog_skills()` usa o catálogo; `CharacterModelLoader` lê o perfil do catálogo.
- Contrato: `tests/combat/test_content_catalog.gd` compara 1:1 com as definições legadas e valida a fábrica.

**Etapa 2 (núcleo) implementada e testada:**
- `MoveData` ganhou os campos de planejamento (`stand_gap`, `run_base`, `run_fixed`, `hit_offset`, `strike_time`, `hold`, `teleport`, `untargetable`, `status_pause`, `redirectable`, `plan_profile`, `plan_fly`, `plan_return`, `blink_distance`, `magic_flat`, `bypass_def`, `transfer_time`) e `ai_profile`.
- `Incoming.move_data` carrega a ficha canônica; `AttackPlanner` lê os campos em vez de comparar `move_id`.
- `MoveBehavior` (base), `MoveBehaviorRegistry` e `MoveBehaviors` concentram Drain Spear, Tidal Surge, Sand Attack, Karate Chop, Bite, Boulder Smash, Electric Beam, Fire Bullet, Media, Tarukaja, Rakunda, Sukunda, Armored Bulk e Taunt.
- `Battle`, `AttackPlanner` e `BattleAI` não têm mais os `if/matches` de regra por `move_id` (restam apenas fallbacks de compatibilidade para Skills sem `MoveData`).
- `Battle` expõe `apply_hit`, `interrupt_attacks_of`, `steal_badges` e `spawn_bounce_chain` para os behaviors; a lógica continua dona do relógio (D-019/D-1040).

**Limpeza final da Etapa 2 concluída:**
- A cadeia de bounces do Tidal Surge e a busca do próximo alvo foram para o behavior `TidalSurge`; o `Battle` só expõe `add_landing`/`roll_ai_for`.
- `BOULDER_DEF_CHANCE`, `ELECTRIC_BEAM_STUN_CHANCE`, `ELECTRIC_BEAM_STUN_TIME` e `ARMOR_SECONDS` foram para os behaviors correspondentes.
- `GUARD_BREAKERS` virou a tag `guard_break` no `MoveData`; `Battle._hit` e o `SkillInfoPanel` leem a tag.
- Não restam `if/matches` de regra por `move_id` no `AttackPlanner`, no `BattleAI` ou no núcleo do `Battle`; só fallbacks de compatibilidade para Skills sem `MoveData`.

**Etapa 3 (roteamento de VFX) concluída:**
- `MoveData.vfx_key` identifica a família visual de cada Move (abra, electric, tidal, element, fire, media, brick_break, sand_attack, dragon_rage, taunt, drain_spear, armored_bulk ou generic).
- `MoveVfxRegistry` centraliza wind-up, projéteis e impactos; `fx_telegraph`/`fx_projectiles`/`fx_impacts` não têm mais as listas de ids de família.
- Os impactos autorais de Electric/Tidal/Drain continuam nos módulos próprios (`ElectricBeamVfx`/`TidalSurgeVfx`/`FxDrainSpear`), mas o roteamento é do registry; o Drain é desenhado pelo `fx_drain_spear` e não pelo impacto genérico.
- `BattleFx` deixou de comparar `move_id` para Drain, guard break, Burn/Fire Bullet, status com VFX de palco, Shock Wave no miss e Quick Punch no pulso BW; usa tags do `MoveData`.
- `hit_stop_duration` e `bw_pulse` saíram das tabelas do `BattleFx` para o `MoveData`.

**Etapa 4 concluída nos blocos de responsabilidade que não mudam regra:**
- `skill.gd` caiu de **887 para 327 linhas**; os dicionários de texto legado, custos de MP e efeitos curtos foram para `scripts/data/skill_legacy_data.gd` (`SkillLegacyData`, 561 linhas).
- `battle_hud.gd` caiu de **1557 para 1241 linhas**; os helpers estáticos de desenho foram para `scripts/ui/components/battle_hud_draw.gd` (`BattleHudDraw`, 322 linhas). `BattleHud` herda a classe, então `BattleHud.slant()`, `BattleHud.element_icon()` etc. continuam funcionando.
- `battle.gd` caiu de **1153 para 1053 linhas**; a fila de recompensas de ATB/Burst foi para `scripts/combat/battle_rewards.gd` (`BattleRewards`, 58 linhas) e o roubo/transferência de badges para `scripts/combat/battle_badges.gd` (`BattleBadges`, 78 linhas). `Battle` mantém `rewards`, `grant_atb`, `grant_burst` e `steal_badges` como contrato público; o relógio continua sendo um só (D-019/D-1040).
- `vfx_room.gd` caiu de **2736 para 2328 linhas**; o catálogo de cenários foi para `scripts/debug/vfx_room_scenarios.gd` (`VfxRoomScenarios`, 112 linhas) e as ferramentas de análise visual para `scripts/debug/vfx_room_analysis.gd` (`VfxRoomAnalysis`, 442 linhas). A sala mantém wrappers com os mesmos nomes usados pela CLI, pelo painel e pelos testes.
- `Skill` mantém a API e os fallbacks; o contrato `test_content_catalog.gd` continua verde.

**Limite atual da Etapa 4:** `battle.gd` mantém o núcleo coeso de timeline/hit e `vfx_room.gd` mantém o painel e o loop de gravação; dividir esses núcleos exige decidir a fronteira exata (D-1079 pede essa decisão antes de cada etapa).

**Etapa 6 (testes-contrato) concluída:**
- `tests/combat/test_content_contract.gd` monta um `MoveData` e um `CharacterData` novos em memória, injeta catálogos de teste, passa por `Skill.from_data`/`from_id`, `MoveBehaviorRegistry`, `MoveVfxRegistry` e `CharacterFactory.create`, e restaura os catálogos reais; nenhum `.tres` do projeto é alterado.
- Cobre “novo Move” e “novo Personagem” sem branch por nome; verde.

**Etapa 5 (unificação física) concluída com o layout aprovado pelo criador:**
- `scripts/combat/fx/*` foi movido para `scripts/vfx/combat/*`, preservando `projectile_lib/` e todos os `.uid` (33 `.gd` + 33 `.uid`).
- `scripts/vfx/` passa a ser a raiz única de VFX: `combat/`, `elements/`, `perception/`, `smt/` e os scripts `drain_spear_*.gd`.
- Preloads atualizados em `scripts/combat/battle_fx.gd` e `tests/combat/test_content_contract.gd`; `RELOAD_DIRS` da sala de VFX atualizado para `res://scripts/vfx/combat/`.
- O cache de classes do Godot foi regenerado (`--import`); não restam referências de código ao caminho antigo.
- Suíte completa de combate/VFX: **16/16 PASS**, incluindo Análise VFX e D-235. `test_content_catalog`, `test_content_contract`, `test_vfx_room`, `test_drain_spear`, `test_all_moves_vfx` e `test_move_vfx_routing` verdes.
- Não existe `export_presets.cfg` neste worktree; não havia filtro de export para ajustar.
- Docs históricos (`D-xxx` antigos, planos e `scratch/`) podem citar `scripts/combat/fx/` como registro da época; o caminho atual é `scripts/vfx/combat/`.

**Auditoria de arquitetura (2026-11-09):**
- `MoveData.behavior_script` passou a ser lido por `MoveBehaviorRegistry`; o contrato da Etapa 6 instancia um behavior de fixture sem entrada fixa por id.
- `MoveVfxRegistry.impact_family()`/`travel_family()` agora usam `MoveData.vfx_key` quando o id não tem entrada no mapa fixo; ids existentes mantêm o comportamento anterior.
- `MoveCatalog.all_moves()`, `CharacterCatalog.all_characters()`, `CharacterData.skill_ids()`, `inventory()` e `model_profile_dict()` devolvem cópias, para não mutar definições compartilhadas.
- **Fase 1 do pacote de Move:** `MoveVfx` (base de hooks, sem relógio próprio) e `MoveVfxRegistry.move_vfx_for()`/`clear_move_vfx_cache()`; `vfx_script` agora resolve e é coberto pelo contrato. Nenhum `.tres` usa ainda e nenhum VFX existente mudou.
- **Fase 2 do pacote de Move (Media):** a classe `Media` saiu de `move_behaviors.gd` para `content/moves/media/behavior.gd`; `move.tres` aponta `behavior_script`, a entrada fixa saiu do `MoveBehaviorRegistry` e o builder preserva `behavior.gd`/`vfx.gd` opcionais. Comportamento, tempos e visual idênticos; contrato e suíte 16/16 verdes.
- **Fase 3 do pacote de Move (ícone):** `content/moves/media/icon.svg` é o piloto; `scripts/ui/move_icons.gd` resolve o ícone por caminho fixo e `FanMenu`/`SkillInfoPanel` usam o ícone do Move quando existe, com fallback para o ícone de tipo/alcance. Contrato `tests/ui/test_move_icons.gd` verde; aprovação visual antes de expandir.
- Proposta completa em [`docs/PROPOSTA_PACOTE_MOVE_2026-11-09.md`](../PROPOSTA_PACOTE_MOVE_2026-11-09.md); Fases 4–5 (VFX e expansão) aguardam escolha do criador.
- Pendências registradas em [`docs/AUDITORIA_ARQUITETURA_2026-11-09.md`](../AUDITORIA_ARQUITETURA_2026-11-09.md): pacote de Move parcial (`behavior.gd`/`vfx.gd`/`icon.svg` ausentes por Move), matches de coreografia por `move_id` em VFX e testes antigos/flaky.

Nenhum push.
