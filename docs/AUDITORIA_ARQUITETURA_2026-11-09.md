# Auditoria de arquitetura — 2026-11-09

- **Decisões aplicáveis:** D-1079, D-1080, D-1081, D-235, D-019/D-1040, D-1042/D-1044, D-308, D-022.
- **Escopo:** Etapas 1–6 da arquitetura de conteúdo, pastas de VFX, catálogos, definições compartilhadas e testes-contrato.
- **Regra:** nenhuma regra de jogo foi alterada; refatorações preservam comportamento.

## Verificações feitas

- 33 `.gd` + 33 `.uid` em `scripts/vfx/combat`; nenhum `.gd` sem `.uid`, nenhum `.uid` órfão, nenhum resto em `scripts/combat/fx`.
- `--import` regenerou o cache de classes; 0 referências de código ao caminho antigo.
- `content/moves` tem 38 pastas com `move.tres`; `content/characters` tem 6 pastas com `species.tres` + `loadout.tres` + `model_profile.tres`, e `species.tres` referencia os outros dois.
- `MoveCatalog`/`CharacterCatalog` usam caminho fixo e catálogo explícito, sem varredura de pasta em runtime para conteúdo.
- `MoveData.behavior_script` e `MoveData.vfx_script` existiam, mas nenhum `.tres` os usava e os registries não os liam.
- `fx_projectiles.gd`/`fx_impacts.gd` ainda têm `match move_id` para coreografias específicas (não listas de família).
- A sala de VFX usa `DirAccess.get_files_at` apenas no reload de debug.
- `VfxRoomAnalysis` acessa campos privados do `Battle` (`_landing`, `_returning`, `_status_pause`) para a matriz de testes.

## Corrigido

1. **`MoveData.behavior_script` deixou de ser campo morto.** `MoveBehaviorRegistry.get_behavior()` agora instancia o script do Move quando ele existe e é um `MoveBehavior`; o mapa `BEHAVIORS` continua como compatibilidade. O contrato da Etapa 6 cobre isso com `tests/combat/fixtures/contract_move_behavior.gd`.
2. **`vfx_key` agora vale também no impacto e no trajeto de um Move novo.** `MoveVfxRegistry.impact_family()` usa o mapa fixo para ids existentes e cai para `MoveData.vfx_key` quando o id não tem entrada; `travel_family()` usa o mesmo caminho, preservando o caso especial do Teleport. O contrato cobre `family_for_inc`, `impact_family` e `travel_family`.
3. **Definições compartilhadas não vazam mais arrays/dicionários internos.** `MoveCatalog.all_moves()`, `CharacterCatalog.all_characters()`, `CharacterData.skill_ids()`, `inventory()` e `model_profile_dict()` devolvem cópias (D-1079: Resources são somente leitura).
4. **Tipagem:** `BattleBadges.transfers`/`stolen` agora são `Array[Dictionary]`.
5. **Isolamento do teste-contrato:** o cache de `MoveBehaviorRegistry` do Move de teste é limpo ao restaurar os catálogos; o cache de `MoveVfx` também.
6. **Testes antigos de VFX atualizados para o comportamento atual:** `test_tackle_vfx` valida a remoção das lâminas fixas (D-990); `test_abra_prototype_vfx` passa um `Incoming` real para o hook de telegraph (D-170).
7. **Fase 1 do pacote de Move:** criada a base `MoveVfx` (`scripts/combat/moves/move_vfx.gd`) e `MoveVfxRegistry.move_vfx_for()`/`clear_move_vfx_cache()`. `MoveData.vfx_script` agora resolve para um script válido, sem nenhum `.tres` usando e sem alterar VFX existente. O roteamento de combate continua no registry até a Fase 4.

## Encontrado, não corrigido (precisa de decisão)

- **Pacote de Move parcial (D-1079 item 3):** as pastas de Move têm só `move.tres`; não há `behavior.gd`, `vfx.gd` nem `icon.svg` por Move. O comportamento continua centralizado em `move_behaviors.gd`/`MoveVfxRegistry`, agora com `behavior_script` funcional. Migrar tudo para pacotes por Move é uma etapa de conteúdo/VFX e mexe em D-308.
- **`vfx_script`:** a interface de hooks existe (`MoveVfx`) e o registry resolve o campo, mas nenhum `.tres` usa e o roteamento de combate continua em `vfx_key` + `MoveVfxRegistry` até a Fase 4 da proposta.
- **Matches por `move_id` em `fx_projectiles.gd`/`fx_impacts.gd`:** são coreografias específicas (Confusion, Psybeam, Teleport, Sand Attack, Electric/Tidal etc.), não listas de família. Movê-las para módulos por Move exige o protocolo D-308 e aprovação visual.
- **`DirAccess.get_files_at` no reload da sala de VFX:** exceção de ferramenta de debug; não afeta conteúdo exportado.
- **`VfxRoomAnalysis` acessa privados do `Battle`:** acoplamento aceito na ferramenta de debug; uma API pública de limpeza/telemetria seria melhor.
- **Aliases PT/EN** continuam em `MoveBehaviorRegistry`/`Skill` como compatibilidade temporária (D-1079 item 1).
- **`CharacterFactory` cai para Gible** quando a espécie não existe, com `push_warning`; um typo de conteúdo pode passar silenciosamente.
- **Testes não rastreados/obsoletos:** `tests/vfx/test_bubble_shield.gd` espera Abra com Bubble Shield (a party canônica antiga não tinha) e `tests/vfx/test_body_alignment.gd` chama `BattleFx.move_impact_is_around()`, API que não existe mais. Não foram alterados por serem trabalho não rastreado de outra sessão.
- **`test_melee_timers_karate_brick.gd`** continua intermitente: a medição pelo log da sala de VFX pega linhas de ataques antigos após o reload. Não é falha de regra; precisa de uma medição por telemetria ou de limpeza do log da sala.

## Validação

- **28/28** scripts da lista principal verdes.
- Suíte `tests/battle/run_agent_combat_tests.py`: **16/16 PASS**.
- `test_content_catalog` e `test_content_contract` verdes, incluindo `behavior_script` e `vfx_key` do Move novo.
- `test_tackle_vfx` e `test_abra_prototype_vfx` verdes depois da atualização.
- `test_bubble_shield`, `test_body_alignment` e `test_melee_timers_karate_brick` seguem como pendências de teste, não de regra.
- Nenhum commit e nenhum push.
