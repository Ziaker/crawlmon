<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Level Up HUD & Universal Move Card Architecture in Godot 4.7

*   **Author:** Rafael
*   **Status:** Approved (EGM Stage 9 Verified — 100% Implementation Ready)
*   **Date:** 2026-11-08

--------------------------------------------------------------------------------

## Decisões Aplicáveis

*   **D-001 / D-002 / D-003**: Regras de combate congeladas; separação estrita de escopos e autoridade documental. Fórmulas de dano espelham fielmente o motor (`battle.gd`).
*   **D-135**: Progressão de atributos do Líder com alocação manual de pontos.
*   **D-235**: Independência universal de Moves (moves, fichas e VFX são 100% agnósticos de combatente, time ou lado do campo; enquadramento de câmera deriva das dimensões reais do modelo).
*   **D-269**: Sistema de posicionamento, distâncias e alcance.
*   **D-390**: Orçamento inicial estrito de 15 pontos base no nível 1. Os 6 atributos canônicos são `STR`, `MAG`, `VIT`, `WIS`, `AGI`, `LUK`.
*   **D-391**: Renomeação de SPI para WIS e fórmula de progressão e escala de MP baseada em WIS.
*   **D-392**: Escala de HP anti-hitkill baseada em VIT e marcos de atributos (milestones a cada 5 pontos).
*   **D-393**: Escopo de 8 Natures iniciais e modificadores estáticos de atributos.
*   **D-394**: Progressão de 1 ponto/nível manual no Líder; proficiências orgânicas e automáticas nos aliados.
*   **D-395 / D-396 / D-397 / D-398**: Ícones de tipo, alcance, elemento, setas de natureza com fundo branco e 12º elemento Mystic (`#65B5B3`).
*   **D-399**: Curva de XP e recompensas pós-combate.
*   **D-400**: Tela de vitória e pausa pós-combate com exibição de espólios e ouro.
*   **D-401**: Trava obrigatória de saída ("RETURN TO DUNGEON") enquanto houver pontos de atributo pendentes no Líder.
*   **D-402**: Concessão de XP pós-combate estritamente para combatentes sobreviventes.
*   **D-413**: Regeneração de MP a cada 8s, custos de moves e textos da HUD 100% em inglês.
*   **D-414 / D-415**: Vórtice espiral de Wind oficial e ajustes de brilho/escala dos ícones.
*   **D-416 / D-417**: Paralelogramos flat com fundos temáticos de elemento e marcas d'água em baixo-relevo sem bordas chanfradas. Ícone elemental omitido do cabeçalho do card quando presente como marca d'água (D-416).
*   **D-418**: Efeito de celebração de nível: pilar de aura Ki Dragon Ball de 0.55s sem flashes de tela inteira (segurança fotossensível).
*   **D-419**: Layout das fichas de moves: duo de badges (Tipo, Alcance), chips de custo ATB/MP/DMG.
*   **D-420**: Modal de inspeção técnica de move em tela cheia com blackout, sem repetições, com 2 blocos consolidados cobrindo os 5 eixos técnicos, atalho Z / clique no card.
*   **D-421 / D-422**: Painel de status integrado com gauges, pips SMT III e tooltips de natureza.
*   **D-423**: Alinhamento óptico dos badges de elemento no roster.
*   **D-428 / D-429 / D-430**: Integração de feedback sonoro, renderização de shaders de interface e botões de ação e steppers retos (90°) ergonômicos.
*   **D-433**: Oficialização do nome como **LevelUpHUD**, disparado exclusivamente quando há subida de nível (`any_leveled_up == true`).
*   **D-434 / D-435 / D-436**: Padrões visuais de cards e contratos de viewport.

--------------------------------------------------------------------------------

## Overview

This technical design document establishes the production architecture to implement the unified **SMT III Level Up HUD** in Godot 4.7 with 1:1 visual and behavioral fidelity to the verified HTML prototype (`prototypes/hud_post_combat.html`).

Per decision **D-433**, this system is formally named **`LevelUpHUD`** (`res://scenes/ui/level_up_hud.tscn`) and is triggered exclusively when at least one party member advances a level (`any_leveled_up == true`). It unifies surviving-only XP calculation (D-399/D-402), Leader manual point allocation (D-135/D-390/D-394/D-401), universal flat move cards with low-relief embossed watermarks (D-416/D-417/D-419), non-epileptic 0.55s Dragon Ball aura boost celebration (D-418), and full-screen 2-block move inspection modal (D-420) into a decoupled, performant engine architecture.

All findings from the EGM Audit and Stages 8 & 9 Reviews have been formally synthesized and remediated in this specification.

## The Problem

Previously, level progression feedback in `scripts/combat/battle_scene.gd` depended on legacy, disconnected immediate-mode text overlays (`scripts/ui/victory_panel.gd` and `scripts/ui/level_up_modal.gd`). These legacy overlays:
1. Lacked visual integration with the 3D character models and SMT III Nocturne aesthetic.
2. Suffered from layout pinching and container breaches due to uncompensated $-9^\circ$ parallelogram shear math.
3. Violated accessibility with premature modal auto-dismissal.
4. Risked concurrent merge conflicts if implemented directly inside active combat scripts (`status_screen.gd` or `battle_hud.gd`).

The production architecture implements the standalone, decoupled `LevelUpHUD` control (`res://scenes/ui/level_up_hud.tscn`) and reusable `MoveCard` component (`res://scenes/ui/components/move_card.tscn`), tested independently in an isolated test harness (`res://scripts/debug/test_level_up_hud.gd`).

## Goals

*   **G1: 1:1 Visual & Layout Parity with HTML Prototype:** Replicate the 3-column SMT III layout with rebalanced column budgets (420px Left / 416px Center / 444px Right), $-9^\circ$ slanted parallelogram containers with pre-baked safe insets (36px on modals, 24px on cards), and SMT III 24-pip segmented stat bars.
*   **G2: Strict Game Rule Enforcement:** Hard-lock the "RETURN TO DUNGEON" button while the party Leader has unallocated stat points (D-401). Enforce organic, non-interactive proficiency growth for allies (D-394). Award XP only to surviving combatants (D-402).
*   **G3: Real Combat Engine Damage Formulas (D-001, D-003, D-420):** Display genuine engine formulas derived from `battle.gd` (Physical: `ATK × Poder × Afinidade [×2.0 Crítico]`; Magic: `MAG × Poder × Afinidade [×2.0 Crítico]`; Drain: `5 + MAG - WIS [Badge Steal]`), strictly forbidding fictitious dummy formulas.
*   **G4: Canonical Attribute Domain (D-390, D-391):** Strict separation of `HP`/`MP` resource gauges from the 6 core distributable attributes (`STR`, `MAG`, `VIT`, `WIS`, `AGI`, `LUK`).
*   **G5: Two-Tier Typographic Contract & Font Integrity:** Render body text, stats, and MoveCards at $0^\circ$ upright orthogonal orientation with zero runtime matrix shearing. Render slanted modal headers using authentic pre-rasterized italic fonts (`res://assets/fonts/kanit/Kanit-BlackItalic.ttf`) with MSDF enabled.
*   **G6: Photosensitive Safety (D-418):** Implement the 0.55s Dragon Ball aura boost as a localized additive 3D cylinder mesh with expanding planar ground shock rings, strictly forbidding full-screen screen flashes.
*   **G7: Input & Ergonomics Completeness (D-430):** Support mouse clicks on the full card area, keyboard (`Z` inspection keybind, Tab / Q-E hero swap, arrows, ESC modal dismiss), and gamepad navigation with 90° rectangular hitboxes on steppers (D-430) and non-deadlocking focus trapping.
*   **G8: Concurrent Session Safety:** Zero modifications to `scripts/ui/status_screen.gd` or `scripts/ui/battle_hud.gd`.

## Non-Goals

*   **NG1: Combat Balance Modifications:** Modifying base attribute curves, HP formulas, MP scaling formulas, or damage equations (frozen in D-390, D-391, and D-392).
*   **NG2: Immediate Refactor of In-Combat HUDs:** Replacing `battle_hud.gd` or `status_screen.gd` immediately; they will consume the standalone `MoveCard` component in future sessions.
*   **NG3: Inventory / Equipment Management:** Managing inventory items or equipment swaps during this screen (limited to displaying battle spoils and gold per D-400).

## Critical User Journeys (CUJs)

### CUJ 1: Post-Combat Victory & Level Up Invocation (D-401 & D-433)
*   **Given**: Player completes a combat encounter where at least one combatant levels up (`any_leveled_up == true`), and the party Leader (Abra) gains 1 distributable stat point (`distributable_points == 1`).
*   **When**: `battle_scene.gd:_trigger_victory_flow()` verifies `any_leveled_up == true`, pauses the combat tree, and instantiates `LevelUpHUD.open(party_summaries, total_xp)`.
*   **Then**:
    1. Abra's 3D model mounts via `CharacterModelLoader` in an isolated `SubViewport` (Center Column, 416px width) with camera framing derived dynamically from bounding radius via `CharacterModelLoader.frame_model_camera()` (Rule 7, D-235) and performs the victory jump while the 0.55s D-418 Dragon Ball aura pillar (`peak_alpha` fading from 0.18 to 0.0) and floor shock rings fire.
    2. The party tab shows `[LV UP!]` badge, and the "AVAILABLE: 1 PT" pill pulses in yellow.
    3. The stat allocation `+` buttons pulse with neon cyan aura glow (`#00d8f6`).
    4. "RETURN TO DUNGEON" button is disabled; attempting to activate it displays the flashing warning banner.
    5. Player increments MAG by 1 and clicks "CONFIRM ALLOCATIONS". Points are committed to `hero.progression_points["MAG"]`, `distributable_points` decrements, `sync_effective_stats()` and `update_resource_maximums()` execute (updating `max_mp`), the lock is lifted, and "RETURN TO DUNGEON" becomes active.
    6. When "RETURN TO DUNGEON" is pressed, `LevelUpHUD` emits `completed`, the tree unpauses, time scale resets, and `GameState.end_battle(true)` resumes dungeon exploration.

### CUJ 2: Move Card Inspection Modal (D-420)
*   **Given**: Player is viewing Abra's move list in the Right Column (444px width, 4 active battle moves).
*   **When**: Player clicks anywhere on the `PSYBEAM` card, presses `Z` (or gamepad `X` button mapped to `ui_inspect`), or selects it and presses `Enter`/`Space`.
*   **Then**:
    1. A full-screen blackout backdrop (`Color(0,0,0,0.95)`) darkens the entire HUD and traps keyboard/mouse focus (`mouse_filter = STOP`).
    2. Focus is routed to the modal's `close_button` (`close_button.grab_focus()`), with `gui_focus_changed` trapping navigation inside the modal to prevent gamepad/keyboard navigation deadlocks.
    3. The modal card opens with decoupled $-9^\circ$ slanted shells and 36px safe insets, displaying Block 1 (`MECHANICS & TACTICAL SCALING`) and Block 2 (`VISUALS & SPATIAL MOTION`).
    4. The exact damage formula is displayed via dynamic formatter reflecting real engine math (`8 [MAG] × 1.2 [Poder] × Afinidade [×2.0 Crítico]`) with scaling notes.
    5. The modal remains open indefinitely until explicit player action (no auto-dismiss timer).
    6. Pressing `ESC`, `Enter`, gamepad `B`, or clicking the backdrop dismisses the modal and returns focus directly to the originating `PSYBEAM` card (`card.grab_focus()`).

### CUJ 3: Dynamic Multi-Party Navigation & Ally Organic Growth (D-394 & D-405)
*   **Given**: Active party has multiple combatants (e.g., Abra Leader, Pancham Ally, Gible Ally).
*   **When**: Player switches tabs via Tab or `Q`/`E`.
*   **Then**:
    1. Selected member's 3D model mounts in the center viewport via `CharacterModelLoader` with dynamic framing.
    2. Any pending session points allocated on Abra are safely preserved in `hero_sessions[hero_id]`.
    3. For allies, manual `+`/`-` allocation buttons are hidden.
    4. The `AllyProficiencyPanel` (inline sub-panel inside Left Column) displays organic combat gains earned during battle.
    5. "RETURN TO DUNGEON" button availability reflects only whether the Leader (`hero.is_party_leader()`) has pending distributable points.

--------------------------------------------------------------------------------

## Technical Architecture & EGM Resolution Decisions

### 1. Viewport Budget & Column Allocation (1280x720) [Resolution Item 2 & Stage 9 Finding 6]

The 1280px horizontal budget is divided to guarantee zero content clipping and zero character model pinching:

| Column | Width | Node Path | Slant Angle |
| :--- | :--- | :--- | :--- |
| **Left Column** | **420px** | `MainVBox/ContentArea/LeftCol` | $-9^\circ$ Shell, $0^\circ$ Content |
| **Center Column** | **416px** | `MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport` | Planar / Dynamic Radius Framing |
| **Right Column** | **444px** | `MainVBox/ContentArea/RightCol` | $-9^\circ$ Shell, $0^\circ$ Content |
| **Total** | **1280px** | Native Godot viewport resolution | Balanced Spacing |

### 2. Decoupled Parallelogram Shell & Pre-Baked Safe Insets [Resolution Items 1 & 4]

*   **Decoupled Architecture:** Containers decouple the visual slanted shell (`SlantedPanel` drawing polygon/shader) from child `Control` layout.
*   **Pre-Baked Insets (Stability):** Established directly via `MarginContainer`:
    *   **Modal Blocks ($h = 220\text{px}$):** `margin_left = 36px`, `margin_right = 36px`.
    *   **Move Cards ($h = 100\text{px}$):** `margin_left = 24px`, `margin_right = 24px`.
    *   **Identity Header ($h = 140\text{px}$):** `margin_left = 28px`, `margin_right = 28px`.
*   `SlantedPanel` renders the background parallelogram polygon and dropped neo-shadow in `_draw()`.

### 3. Canonical Attribute Domain vs Resource Pools [Stage 8 Finding 3]

*   **Resource Pools (Non-distributable):** `HP` (scales with `VIT`, +2 HP/VIT per D-392) and `MP` (scales with `WIS` per D-391). Rendered as dual progress bars at the top of the Left Column.
*   **Distributable Attributes (D-390, D-391, D-394):** The 6 canonical attributes are:
    1. **`STR`**: Físico / Melee scaling.
    2. **`MAG`**: Mágico / Special scaling.
    3. **`VIT`**: Vida / Resistência / HP pools.
    4. **`WIS`**: Sabedoria / MP pools e recuperação.
    5. **`AGI`**: Agilidade / Velocidade de ATB e iniciativa.
    6. **`LUK`**: Sorte / Taxa crítica e evasão.
*   The Left Column allocates 180px for the Pip Strip and 240px for the 6 canonical attribute rows, values, and steppers.

### 4. Real Engine Damage Formulas (D-001, D-003, D-420) [Stage 9 Blocker 1]

`move_inspection_modal.gd` formats formulas dynamically via engine logic:
```gdscript
func format_move_formula(skill: Skill, caster: Combatant) -> Dictionary:
    var is_drain := skill.display_name.to_upper() == "DRAIN SPEAR"
    var is_magic := skill.kind == Skill.Kind.CAST
    var stat_name := "MAG" if is_magic else "ATK"
    var stat_val := caster.mag if (is_magic and caster) else (caster.attack if caster else 8)
    
    if is_drain:
        return {
            "formula": "5 + %d [%s] - WIS [Target]" % [stat_val, stat_name],
            "scaling": "Scales with %s · Ignores Defense · Steals positive badges on hit" % stat_name
        }
    else:
        var mult_str := "%.1f [Poder]" % skill.power
        return {
            "formula": "%d [%s] × %s × Afinidade [×2.0 Crítico]" % [stat_val, stat_name, mult_str],
            "scaling": "Scales with %s · Position Step ±10%% · Weakness ×1.5 · Crit ×2.0" % stat_name
        }
```

### 5. Dynamic Monster Camera Framing API (Rule 7, D-235) [Stage 9 Blocker 2]

Implemented in `res://scripts/combat/character_model_loader.gd`:
```gdscript
static func calculate_model_bounds(model: Node3D) -> AABB:
    var aabb := AABB()
    var first := true
    for mesh_inst in model.find_children("*", "MeshInstance3D", true, false):
        if mesh_inst is MeshInstance3D and mesh_inst.mesh:
            var mesh_aabb: AABB = mesh_inst.transform * mesh_inst.mesh.get_aabb()
            if first:
                aabb = mesh_aabb
                first = false
            else:
                aabb = aabb.merge(mesh_aabb)
    if first:
        aabb = AABB(Vector3(-0.5, 0, -0.5), Vector3(1.0, 2.0, 1.0))
    return aabb

static func frame_model_camera(model: Node3D, camera: Camera3D, optical_offset_y: float = 0.08) -> void:
    var bounds := calculate_model_bounds(model)
    var radius := maxf(bounds.size.x, bounds.size.y) * 0.5
    var fov_rad := deg_to_rad(camera.fov)
    var target_dist := (radius / tan(fov_rad * 0.5)) * 1.25
    camera.position = Vector3(0.0, bounds.get_center().y + optical_offset_y, maxf(target_dist, 2.8))
    camera.look_at(Vector3(0.0, bounds.get_center().y, 0.0))
```

### 6. Stepper Hitbox Ergonomics (D-430) [Stage 9 Major 5]

*   In `scenes/ui/level_up_hud.tscn`, all 12 allocation steppers (`MinusBtn`, `PlusBtn`) configure `skew_deg = 0.0`, providing **straight 90° rectangular hitboxes** (`Button`), guaranteeing 100% reliable click detection.

### 7. MoveCard Presentation (D-416 & D-419) [Stage 9 Major 5]

*   MoveCards render a full-surface element flat background with embossed watermark.
*   Per **D-416**, `ElementBadge` is removed from `BadgesRow`, displaying a **duo of badges** (Tipo e Alcance) alongside the cost chips (ATB/MP).
*   The full card surface is clickable (`mouse_filter = STOP`), triggering the modal.
*   The Right Column displays the **4 active battle skills** in a 2x2 grid.

### 8. Two-Tier Typographic Contract & Font Integrity [Resolution Items 3 & 6]

*   **Tier 1 ($0^\circ$ Upright):** Body text, stat numbers, steppers, and MoveCards operate strictly at $0^\circ$ orthogonal rotation.
*   **Tier 2 ($-9^\circ$ Italic):** Modal headers use native pre-rasterized italic font files (`res://assets/fonts/kanit/Kanit-BlackItalic.ttf`) with MSDF enabled (`multichannel_signed_distance_field = true`).
*   Runtime matrix shearing (`skew`) on `Label` nodes is strictly prohibited.

### 9. SMT III 24-Pip Segmented Geometry [Resolution Item 5]

*   **Pip Dimensions:** Width = `6.0px`, Height = `14.0px`, Spacing = `1.5px`.
*   **Total Strip Width:** $24 \times (6.0 + 1.5) = 180.0\text{px}$.
*   Fits comfortably within the 420px Left Column alongside the 6 canonical attributes.

### 10. Dragon Ball Ki Aura Shader Contract (D-418) [Stage 9 Blocker 3]

*   `shaders/ui/dragonball_aura.gdshader` defines uniform `peak_alpha : hint_range(0.0, 0.5) = 0.18`.
*   `level_up_hud.gd` animates `shader_parameter/peak_alpha` from 0.18 to 0.0 over 0.55s via Quad ease-in tween.

### 11. 12th Element Mystic (`#65B5B3`) Contract (D-398) [Stage 9 Blocker 4]

*   `scripts/data/element.gd`: Add `MYSTIC` to `enum Type` and `NAMES`.
*   `move_card.gd` and `move_inspection_modal.gd`: Add `Element.Type.MYSTIC: {"name": "Mystic", "bg": Color("#65b5b3"), "fg": Color.BLACK, "sub": Color("#042f2e"), "icon": "res://assets/ui/icons/elements/mystic.svg"}` to `ELEMENT_DATA`.

--------------------------------------------------------------------------------

## Implementation Plan

### Milestone 1: Data Contracts & Component Foundations
1. In `scripts/data/element.gd`, add `MYSTIC` to `enum Type` and `NAMES`.
2. In `scripts/combat/character_model_loader.gd`, implement `calculate_model_bounds(model)` and `frame_model_camera(model, camera)`.
3. In `scripts/ui/components/stat_pips_strip.gd`, set `@export var pip_size := Vector2(6.0, 14.0)` and `@export var pip_spacing := 1.5` ($24 \times 7.5 = 180\text{px}$).
4. In `scenes/ui/level_up_hud.tscn`, ensure all 12 stat steppers (`MinusBtn`, `PlusBtn`) in `StatsVBox` have `skew_deg = 0.0` for 90° rectangular hitboxes per D-430.

### Milestone 2: MoveCard & Inspection Modal Realignment
1. In `scenes/ui/components/move_card.tscn` and `scripts/ui/components/move_card.gd`, remove the redundant `ElementBadge` node from `BadgesRow` (leaving only Type and Range badges per D-416). Add `Element.Type.MYSTIC` to `ELEMENT_DATA`.
2. In `scripts/ui/components/move_inspection_modal.gd`:
   * Add `Element.Type.MYSTIC` to `ELEMENT_DATA`.
   * Implement real engine formulas derived from `battle.gd` (Physical: `ATK × Poder × Afinidade`, Magic: `MAG × Poder × Afinidade`, Drain: `5 + MAG - WIS [Badge Steal]`).
   * Implement focus trapping via `get_viewport().gui_focus_changed`.

### Milestone 3: Top-Level `LevelUpHUD` Realignment
1. In `scenes/ui/level_up_hud.tscn`, adjust column sizes:
   * `LeftCol`: `custom_minimum_size = Vector2(420, 0)` (and `HeroCard`: 420px).
   * `CenterCol/ViewportContainer/SubViewport`: `size = Vector2i(416, 520)`.
   * `RightCol`: `custom_minimum_size = Vector2(444, 0)`.
2. In `scripts/ui/level_up_hud.gd`:
   * In `_mount_3d_character()`, call `CharacterModelLoader.frame_model_camera(char_node, camera)`.
   * In `_play_celebration_sequence()`, fix shader tween uniform to `"shader_parameter/peak_alpha"`.
   * In `_on_confirm_alloc_pressed()` and `_on_return_pressed()`, call `hero.update_resource_maximums()`.

### Milestone 4: Headless Verification Test
1. Create `scripts/debug/test_level_up_hud.gd` extending `SceneTree` for `godot --headless`:
   * Test 1: Instantiates `LevelUpHUD`, passes party with Leader gaining 1 level (1 distributable point).
   * Test 2: Asserts `return_btn.disabled == true` and `advance_lock_notice.visible == true` (D-401).
   * Test 3: Increments `MAG` by 1; asserts remaining points == 0 and `return_btn.disabled == false`.
   * Test 4: Confirms allocation; asserts `hero.progression_points["MAG"] == 1` and `hero.max_mp` updated.
   * Test 5: Simulates clicking `PSYBEAM` card; asserts modal opened and `close_btn` has focus.
   * Test 6: Simulates pressing `KEY_ESCAPE`; asserts modal closed and originating card regained focus.
   * Exits non-zero on assertion failure; exits 0 on success.

--------------------------------------------------------------------------------
*Drafted and verified with EGM Protocol (Stage 9 100% Implementation Ready)*
