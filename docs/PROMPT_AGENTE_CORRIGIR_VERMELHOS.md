<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Prompt para o agente que vai corrigir os testes vermelhos

> **Atualização (2026-11-09):** os testes listados abaixo já estão **verdes** nesta worktree
> (`D167_D168_TEST_PASS`, `D160_D164_COMBAT_FIXES_TEST_PASS`, `MOVE_VFX_ROUTING_TEST_PASS`,
> `ALL_MOVES_VFX_TEST_PASS`, `ABRA_VFX_TEST_PASS`, `PANCHAM_VFX_TEST_PASS`). Use este documento
> como histórico; não reverta as correções já feitas.

Você é um agente de engenharia no projeto **Crawlmon**, um dungeon crawler em **Godot 4.7.2** no Windows.

Raiz do projeto:

```text
C:\Users\zerke\OneDrive\Área de Trabalho\Z\crawlmon
```

Binário usado nos testes:

```text
.\Godot_v4.7.2-stable_win64_console.exe
```

## 1. Leitura obrigatória antes de qualquer ação

1. Leia `AGENTS.md` inteiro.
2. Leia `docs/decisoes/README.md` e todos os `docs/decisoes/D-*.md`.
3. Leia `docs/REGRAS_DO_JOGO.md`.
4. Cite no início da resposta os IDs das decisões que se aplicam.
5. Se qualquer detalhe for ambíguo, pergunte antes de alterar. Não invente regra, não “conserte” o jogo para o teste passar.

## 2. Estado atual (não desfaça)

As Etapas 1–3 da arquitetura de conteúdo estão concluídas e a Etapa 4 foi iniciada:

- `content/moves/<id>/move.tres` (38 Moves) e `content/characters/<id>/` (6 personagens).
- `MoveData`, `CharacterData`, `CharacterLoadout`, `CharacterModelProfile`, `MoveCatalog`, `CharacterCatalog`.
- `CharacterFactory`; `EnemyFactory`, `GameState._build_party` e `DqtTestParty` delegam a ele.
- `MoveBehavior`/`MoveBehaviorRegistry`/`MoveBehaviors`; `AttackPlanner` e `BattleAI` leem `MoveData`.
- `MoveVfxRegistry`; `fx_telegraph`, `fx_projectiles`, `fx_impacts` e `BattleFx` roteiam por `vfx_key`/tags.
- `skill.gd` foi reduzido de 887 para 327 linhas; textos/custos legados estão em `scripts/data/skill_legacy_data.gd`.

**Não reverta essas mudanças.** O worktree já tem mudanças não commitadas de outras sessões; não use `git checkout -- .`, `git reset --hard` nem apague arquivos não versionados.

Contrato que precisa continuar verde:

```text
tests/combat/test_content_catalog.gd
```

## 3. Objetivo

Corrigir **apenas** os testes vermelhos abaixo. Para cada um:

1. Reproduza com o comando indicado.
2. Encontre a causa raiz.
3. Decida se o **teste** está desatualizado ou se o **jogo** regrediu.
4. Se for o teste: corrija o teste, sem mudar regra de jogo.
5. Se for o jogo: **pare e pergunte** qual decisão vale, citando os IDs. Não altere regra de jogo por conta própria.
6. Rode o teste de novo e cole o resultado.

## 4. Vermelhos atuais

### 4.1 `tests/battle/test_d167_d168.gd`

Comando:

```powershell
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/battle/test_d167_d168.gd
```

Falhas atuais:

- `[FAIL] no próprio trajeto espera a janela perfeita`
- `[FAIL] desvia na janela perfeita`
- Também aparece `ERROR: Parameter "material" is null.` (verifique se é ruído ou causa).

Contexto: o fixture já recebeu MP (`max_mp/mp = 999`) e as falhas de IA/variação/reserva sumiram. O que resta é a janela de Evade perfeito. Leia **D-283, D-1006, D-1014, D-987, D-988** antes de mexer. Não altere a janela no jogo sem decisão.

### 4.2 `tests/battle/test_d160_d164_combat_fixes.gd`

Comando:

```powershell
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/battle/test_d160_d164_combat_fixes.gd
```

Falha atual:

- `[FAIL] KO com Tackle voa para longe dos jogadores (dot 1.00, dist 3.64)`

Contexto: D-160 diz que o lançamento de K.O. vai sempre para longe de onde os jogadores estão; D-049 define o lançamento balístico. Verifique se o teste usa a posição/ângulo corretos ou se o lançamento regrediu. Há também erros de `material null` e lambda capturada; se forem ruído, diga.

### 4.3 `tests/vfx/test_move_vfx_routing.gd`

Comando:

```powershell
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/vfx/test_move_vfx_routing.gd
```

Falha atual:

- `authored move impact must dispatch B1 before elemental fallback`

Contexto: o teste chama `_impact(..., "investida")` e espera um nó `TackleImpactB1`. Hoje `fx_impacts._tackle_impact` cria `TackleShockCone`, `TackleSlashArcA/B`, `TackleFlipbookMain/Core`, `TackleGroundSmoke`; não existe `TackleImpactB1` em nenhum script. Verifique se B1/B2 foram removidos intencionalmente (D-1017/D-1020/D-1044) ou se o teste está velho. Não recrie um VFX inteiro sem decisão.

### 4.4 `tests/vfx/test_all_moves_vfx.gd`

Comando:

```powershell
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/vfx/test_all_moves_vfx.gd
```

Falhas atuais:

- `Tackle golpe A2 deve ter exatamente 2 laminas de smear`
- `Tackle impacto B1 deve conter a raiz da explosao estelar`
- `Tackle impacto B1 deve conter o anel de plasma dourado`
- `Tackle impacto B1 deve conter o anel de plasma cruzado`
- `Media deve ter tratamento visual de status`

Contexto: mesmo caso de B1/B2 do item 4.3. Para Media, `BattleFx.play_hit` hoje retorna cedo para `stage_vfx` (D-337: o ritual próprio substitui o burst genérico); o teste pode estar esperando o burst antigo. Não reintroduza o burst branco.

### 4.5 `tests/vfx/test_abra_vfx.gd`

Comando:

```powershell
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/vfx/test_abra_vfx.gd
```

Falhas atuais (expectativas de VFX/plano antigas):

- `Confusion must emit authored mental waves`
- `Confusion must emit three concentric waves`
- `Psybeam must use a continuous cylindrical beam`
- `Psybeam must contain core, halo and two helices`
- `Shock Wave must own its ascending arc and target lock`
- `Rapid Teleport must own its spatial choreography`
- `Confusion must dispatch the telekinetic gravity field`
- `Psybeam must dispatch its prism refraction`
- `Shock Wave must dispatch its double procedural lightning pillar`

Contexto: o teste já foi ajustado para usar `fx_attack_plan.begin_attack` (antes chamava um método inexistente em `FxMotion`). Agora ele precisa de `move_id`/`move_data` ou de expectativas atualizadas. Compare com os VFX reais e com as decisões D-170 e D-308 antes de mudar o jogo.

### 4.6 `tests/vfx/test_pancham_vfx.gd` (exit 0, mas com erro)

Comando:

```powershell
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/vfx/test_pancham_vfx.gd
```

Ele imprime `PANCHAM_VFX_TEST_PASS`, mas registra:

- `SCRIPT ERROR: Invalid access to property or key 'run_t' on a base object of type 'Dictionary'.`

Provável causa: o teste lê `quick.data["run_t"]`, mas o planejamento grava `run_t` em `Incoming.run_t`, não em `Incoming.data`. Confirme e corrija só o teste.

## 5. Testes que já estão verdes (não quebre)

- `tests/combat/test_content_catalog.gd`
- `tests/combat/test_enemy_encounter_generation.gd`
- `tests/battle/test_d238_burn.gd`
- `tests/battle/test_d1025_tidal_surge.gd`
- `tests/battle/test_d1026_armor.gd`
- `tests/battle/test_d977_electric_beam.gd`
- `tests/battle/test_d1005_boulder_smash.gd`
- `tests/battle/test_drain_spear.gd`
- `tests/battle/test_battle_load.gd`
- `tests/battle/test_d272_guard.gd`
- `tests/battle/test_d279_clash.gd`
- `tests/battle/test_d285_d286.gd`
- `tests/battle/test_d282_prison.gd`
- `tests/battle/test_d157_hitshake_and_launch.gd`
- `tests/battle/test_d032_mechanics.gd` (exit 0; pode imprimir ruído)
- `tests/ui/test_qol_batch.gd`
- `tests/ui/test_status_screen_content.gd`
- `tests/vfx/test_vfx_room.gd`
- `tests/vfx/test_gible_vfx.gd`
- `tests/vfx/test_fire_move_vfx.gd`

## 6. Regras de trabalho

- Não altere regra de jogo para fazer teste passar. Se o teste estiver certo e o jogo errado, pare e pergunte.
- Não mexa em `content/`, `MoveData`, `CharacterData`, `MoveCatalog`, `CharacterCatalog`, `MoveBehavior` ou `MoveVfxRegistry` sem necessidade; se mexer, justifique.
- Não desfaça `skill_legacy_data.gd` nem a redução de `skill.gd`.
- Rode `--import` antes dos testes se criar classe/recurso novo.
- Não commite nem dê push sem autorização expressa.
- Confira `git branch --show-current` e `git status` antes de qualquer commit.
- Entregue, por teste: causa raiz, se era teste ou jogo, o que mudou, comando e resultado.
- Diga o que **não** foi verificado.

## 7. Resultado final (2026-11-09)

Os seis vermelhos foram corrigidos como **teste desatualizado / chamada na camada errada**, sem mudar regra de jogo:

- `test_d167_d168` — passou a exercitar o scheduler real (`Battle._tick_ai_dodge`/`can_evade_now`), com `motion = "melee"`; `D167_D168_TEST_PASS`.
- `test_d160_d164_combat_fixes` — espera por tempo real até o corpo percorrer mais de 9 m, em vez de 240 quadros fixos; `D160_D164_COMBAT_FIXES_TEST_PASS`.
- `test_move_vfx_routing` — valida a composição atual do Tackle (`TackleShockCone` etc.), não o antigo `TackleImpactB1`; `MOVE_VFX_ROUTING_TEST_PASS`.
- `test_all_moves_vfx` — valida D-041/D-990/D-337 (sem lâminas fixas, sem B1/plasma antigo e Media com ritual próprio); `ALL_MOVES_VFX_TEST_PASS`.
- `test_abra_vfx` — usa `AttackPlanner.plan()` antes de `begin_attack()` e os estágios atuais do `AbraMoveVfx` (D-170); `ABRA_VFX_TEST_PASS`.
- `test_pancham_vfx` — usa `AttackPlanner.plan()` e valida `Incoming.run_t`/`data["run_t"]`; `PANCHAM_VFX_TEST_PASS`.

Verificação atual nesta worktree: **28/28 scripts de teste** e **suíte de combate/VFX 16/16** (incluindo Análise VFX e D-235). O erro transitório de compilação de `BattleRewards`/`BattleBadges` era cache de classes após a Etapa 4; `--import` resolveu. HEAD atual `2bec47e9` (outra sessão); as correções dos seis testes continuam **não commitadas** e **sem push**.
