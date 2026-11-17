class_name PreGameController
extends Control

const PreGameCatalog = preload("res://scripts/ui/pre_game/pre_game_catalog.gd")
const PreGameDraw = preload("res://scripts/ui/pre_game/pre_game_draw.gd")
const PreGameBackdrop = preload("res://scripts/ui/pre_game/pre_game_backdrop.gd")
const PreGameStage3D = preload("res://scripts/ui/pre_game/pre_game_stage_3d.gd")
const PreGameViewBoot = preload("res://scripts/ui/pre_game/pre_game_view_boot.gd")
const PreGameTitleWorld = preload("res://scripts/ui/pre_game/pre_game_title_world.gd")
const PreGameViewCharSelect = preload("res://scripts/ui/pre_game/pre_game_view_charselect.gd")
const PreGameViewSettingsCredits = preload("res://scripts/ui/pre_game/pre_game_view_settings_credits.gd")
const PreGameViewModals = preload("res://scripts/ui/pre_game/pre_game_view_modals.gd")

const HUB_SCENE: String = "res://scenes/hub_3d_lab.tscn"
const FOREST_SCENE: String = "res://scenes/debug/murky_forest_3d_lab.tscn"

var _gs: Node = null
var _backdrop: PreGameBackdrop = null
var _stage_3d: PreGameStage3D = null
var _view_boot: PreGameViewBoot = null
var _title_world: PreGameTitleWorld = null
var _title_v2: bool = true
var _view_char: PreGameViewCharSelect = null
var _view_settings: PreGameViewSettingsCredits = null
var _view_modals: PreGameViewModals = null

var _settings: Dictionary = {}
var _view: String = "title"
var _char_index: int = 0
var _move_index: int = 0
var _menu_index: int = 0
var _play_index: int = 0
var _play_drawer_open: bool = false
var _quit_modal_open: bool = false
var _quit_idx: int = -1
var _concept: String = "A"
var _loading_label: String = ""
var _loading_progress: float = -1.0
const FRONT_ANGLE: float = 0.28
var _model_angle: float = FRONT_ANGLE
var _zoom_offset: float = 0.0
var _turntable: bool = false  # D-1226: no auto-spin; the model only turns while the mouse is held
var _show_rig: bool = false
var _raw_key: Key = KEY_NONE  # keycode of the key being routed (see _view_action)
var _art_only: bool = false  # D-1226: charselect shows the character art instead of the 3D model
var _shift_math: bool = false
var _reduce_motion: bool = false
var _dragging: bool = false
var _last_drag_x: float = 0.0

var _cli_args: PackedStringArray = PackedStringArray()
var _requested_view: String = ""
var _requested_resolution: Vector2 = Vector2.ZERO
var _settings_tab: int = 0
var _adv_layer: int = 2
var _forced_nature_id: String = ""
var _shot_path: String = ""
var _capture_parity_dir: String = ""
var _capture_species_dir: String = ""
var _headless_scenario: String = ""
var _summary_json: bool = false
var _stdout_trace: bool = false
var _quit_after: bool = false
var _capture_spin: bool = false
var _frozen_flag: bool = false
var _instant_roulette: bool = false
var _nht_auto: bool = false
var _nht_load_min: float = 0.0
var _capture_parity: bool = false
var _pending_scene: String = ""
var _last_roulette_roll: Dictionary = {}
var _roulette_view_done: bool = false

func _ready() -> void:
    _cli_args = OS.get_cmdline_args()
    _cli_args.append_array(OS.get_cmdline_user_args())
    _gs = get_node_or_null("/root/GameState")

    if _has_flag("--hub") and not _has_flag("--view=hub"):
        _change_scene_deferred(_scene_hub())
        return
    if _has_flag("--forest"):
        _change_scene_deferred(_scene_forest())
        return

    _settings = PreGameCatalog.clone_default_settings()
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    focus_mode = Control.FOCUS_NONE
    mouse_filter = Control.MOUSE_FILTER_STOP

    _parse_cli_flags()
    _build_ui()
    _connect_signals()
    _view_settings.setup_settings(_settings)
    _apply_cli_state()
    _sync_all_views()
    if _nht_auto:
        _nht_auto_exit()

    if not _capture_species_dir.is_empty():
        await _capture_species_batch(_capture_species_dir)
        return

    if not _capture_parity_dir.is_empty():
        await _capture_parity_batch(_capture_parity_dir)
        return

    if not _shot_path.is_empty():
        await _take_screenshot(_shot_path)

    if not _headless_scenario.is_empty():
        _run_headless_scenario(_headless_scenario)
        return

    if _summary_json:
        var no_failures: Array[String] = []
        var no_info: Array[String] = []
        _print_summary("", true, no_failures, no_info)
    if _quit_after:
        get_tree().quit(0)

func _build_ui() -> void:
    _backdrop = PreGameBackdrop.new()
    _add_overlay(_backdrop)

    _stage_3d = PreGameStage3D.new()
    _stage_3d.backdrop = _backdrop
    _add_overlay(_stage_3d)

    # D-1265: v2 title/menu = 3D world behind the boot view. `--title=v1` restores the old look.
    _title_v2 = _arg_value("--title=") != "v1"
    if _title_v2:
        _title_world = PreGameTitleWorld.new()
        _add_overlay(_title_world)
        _title_world.visible = false
        _title_world.active = false

    _view_boot = PreGameViewBoot.new()
    _view_boot.use_v2 = _title_v2
    _add_overlay(_view_boot)

    _view_char = PreGameViewCharSelect.new()
    _add_overlay(_view_char)

    _view_settings = PreGameViewSettingsCredits.new()
    _add_overlay(_view_settings)

    _view_modals = PreGameViewModals.new()
    _add_overlay(_view_modals)

func _add_overlay(child: Control) -> void:
    child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(child)
    child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _connect_signals() -> void:
    _view_boot.title_entered.connect(_on_title_entered)
    _view_boot.menu_action.connect(_on_menu_action)
    _view_char.back_to_menu.connect(_on_back_to_menu)
    _view_char.character_selected.connect(_on_character_selected)
    _view_char.move_selected.connect(_on_move_selected)
    _view_char.confirm_protagonist.connect(_on_confirm_protagonist)
    _view_char.open_skill_dossier.connect(_on_open_skill_dossier)
    _view_char.open_advanced_dossier.connect(_on_open_advanced_dossier)
    _view_char.toggle_shift_math.connect(_on_toggle_shift_math)
    _view_char.camera_action.connect(_on_camera_action)
    _view_settings.back_requested.connect(_on_settings_back_requested)
    _view_settings.settings_changed.connect(_on_settings_changed)
    _view_modals.modal_closed.connect(_on_modal_closed)
    _view_modals.species_changed.connect(_on_modal_species_changed)
    _view_modals.start_roulette_from_confirm.connect(_on_start_roulette_from_confirm)
    _view_modals.roulette_finished.connect(_on_roulette_finished)
    _view_modals.roulette_enter_expedition.connect(_on_roulette_enter_expedition)
    _view_modals.roulette_cancelled.connect(_on_roulette_cancelled)

func _parse_cli_flags() -> void:
    # D-1237 debug: --nht-auto opens the roulette and presses Enter by itself.
    _nht_auto = _has_flag("--nht-auto")
    var nht_load_raw: String = _arg_value("--nht-load-min=")
    if nht_load_raw.is_valid_float():
        _nht_load_min = maxf(0.0, float(nht_load_raw))
    _requested_view = _normalize_view(_arg_value("--view="))
    if _requested_view.is_empty() and (_arg_value("--hud=") == "roulette" or _nht_auto):
        _requested_view = "roulette"  # D-1204: --hud=roulette --nature=<id> [--roulette-at=ms] --shot=file.png
    var species_raw: String = _arg_value("--species=")
    if not species_raw.is_empty():
        _char_index = _resolve_species_index(species_raw)
    _art_only = _arg_value("--art=") == "1"  # D-1226 debug: charselect art view
    var move_raw: String = _arg_value("--move=")
    if move_raw.is_valid_int():
        _move_index = clampi(int(move_raw), 0, 2)
    var layer_raw: String = _arg_value("--layer=")
    if layer_raw.is_valid_int():
        _adv_layer = clampi(int(layer_raw), 1, 4)
    var tab_raw: String = _arg_value("--tab=")
    if tab_raw.is_valid_int():
        _settings_tab = clampi(int(tab_raw), 0, 4)
    var concept_raw: String = _arg_value("--concept=").to_upper()
    if concept_raw == "A" or concept_raw == "B" or concept_raw == "C":
        _concept = concept_raw
    _forced_nature_id = _arg_value("--nature=")
    _frozen_flag = _has_flag("--frozen") or _has_flag("--freeze-backdrop")
    _capture_spin = _has_flag("--spin")
    var res_raw: String = _arg_value("--res=")
    if res_raw.is_empty():
        res_raw = _arg_value("--resolution=")
    if not res_raw.is_empty():
        _apply_resolution(res_raw)
    _shot_path = _arg_value("--shot=")
    if _shot_path.is_empty():
        _shot_path = _arg_value("--screenshot=")
    _capture_parity_dir = _arg_value("--capture-parity-dir=")
    _capture_species_dir = _arg_value("--capture-species-dir=")
    _headless_scenario = _arg_value("--scenario=")
    _summary_json = _has_flag("--summary-json")
    _stdout_trace = _has_flag("--stdout-trace")
    _quit_after = _has_flag("--quit")
    _instant_roulette = _has_flag("--instant-roulette")

func _has_flag(flag: String) -> bool:
    for arg in _cli_args:
        if str(arg) == flag:
            return true
    return false

func _arg_value(prefix: String) -> String:
    for arg in _cli_args:
        var text: String = str(arg)
        if text.begins_with(prefix):
            return text.substr(prefix.length())
    return ""

func _normalize_view(raw: String) -> String:
    match raw:
        "title":
            return "title"
        "menu":
            return "menu"
        "menu_drawer", "drawer":
            return "menu_drawer"
        "charselect":
            return "charselect"
        "skill_dossier":
            return "skill_dossier"
        "confirm_char", "confirm":
            return "confirm_char"
        "advanced":
            return "advanced"
        "roulette":
            return "roulette"
        "settings":
            return "settings"
        "credits":
            return "credits"
        "loading":
            return "loading"
        "quit_modal":
            return "quit_modal"
        _:
            return ""

func _apply_resolution(raw: String) -> void:
    var parts: PackedStringArray = raw.split("x", false)
    if parts.size() != 2:
        parts = raw.split("X", false)
    if parts.size() != 2:
        return
    var width: int = int(parts[0])
    var height: int = int(parts[1])
    if width <= 0 or height <= 0:
        return
    _requested_resolution = Vector2(float(width), float(height))
    if DisplayServer.get_name() != "headless":
        var window: Window = get_window()
        if window != null:
            window.size = Vector2i(width, height)

func _apply_cli_state() -> void:
    if _frozen_flag:
        _backdrop.frozen = true
        _stage_3d.set_frozen(true)
        _turntable = false
    if not _shot_path.is_empty() or not _capture_parity_dir.is_empty() or not _capture_species_dir.is_empty():
        _turntable = false
    _settings_tab = clampi(_settings_tab, 0, 4)
    _view_settings.settings_tab_idx = _settings_tab
    _adv_layer = clampi(_adv_layer, 1, 4)

    match _requested_view:
        "title":
            _view = "title"
        "menu":
            _view = "menu"
        "menu_drawer", "drawer":
            _view = "menu"
            _play_drawer_open = true
            _play_index = 0
        "charselect":
            _view = "charselect"
        "skill_dossier":
            _view = "charselect"
            _view_modals.open_skill_dossier(_char_index, _move_index)
        "confirm_char", "confirm":
            _view = "charselect"
            _view_modals.open_confirm_char(_char_index)
        "advanced":
            _view = "charselect"
            _view_modals.open_advanced(_char_index, _adv_layer)
        "roulette":
            _view = "charselect"
            _view_modals.roulette_muted = _has_flag("--mute=1") or _has_flag("--mute")
            var speed_raw: String = _arg_value("--speed=")
            if speed_raw.is_valid_float():
                _view_modals.roulette_speed = clampf(float(speed_raw), 0.05, 40.0)
            var intro_raw: String = _arg_value("--roulette-intro-at=")
            if intro_raw.is_valid_float():
                _last_roulette_roll = _view_modals.open_roulette(_char_index, "NEW_GAME", _forced_nature_id, false)
                _view_modals.freeze_roulette_intro_at(float(intro_raw))
                _roulette_view_done = true
            var at_raw: String = _arg_value("--roulette-at=")
            if _roulette_view_done:
                pass
            elif at_raw.is_valid_float():
                # D-1204/D-1218: exact instant (ms since the reels start spinning), frozen for the capture.
                _last_roulette_roll = _view_modals.open_roulette(_char_index, "NEW_GAME", _forced_nature_id, false)
                _view_modals.freeze_roulette_at(float(at_raw))
            else:
                _last_roulette_roll = _view_modals.open_roulette(_char_index, "NEW_GAME", _forced_nature_id, not _capture_spin)
                if not _capture_spin:
                    _view_modals.skip_roulette()
        "settings":
            _view = "settings"
            _view_settings.set_mode("settings")
        "credits":
            _view = "credits"
            _view_settings.set_mode("credits")
        "loading":
            _view = "loading"
            _loading_label = "ENTERING THE FOREST"
            _loading_progress = 0.5
        "quit_modal":
            _view = "menu"
            _quit_modal_open = true
            _quit_idx = 1
        _:
            _view = "title"

func _process(delta: float) -> void:
    if _backdrop == null or _view_modals == null:
        return
    if _view != "charselect":
        return
    if _backdrop.frozen or _dragging:
        return
    # D-1226: after the mouse is released the model eases back to face the front.
    if absf(angle_difference(_model_angle, FRONT_ANGLE)) < 0.002:
        return
    _model_angle = lerp_angle(_model_angle, FRONT_ANGLE, clampf(delta * 8.0, 0.0, 1.0))
    _stage_3d.set_model_angle(_model_angle)
    _backdrop.set_camera_controls(_model_angle, _turntable, _zoom_offset)

func _sync_all_views() -> void:
    _reduce_motion = _read_reduce_motion()
    _backdrop.reduce_motion = _reduce_motion
    var safe_rect: Rect2 = _view_char.get_pedestal_safe_rect() if _view == "charselect" else Rect2()
    _backdrop.set_view_state(_view, _char_index, _concept, safe_rect)
    _backdrop.set_camera_controls(_model_angle, _turntable, _zoom_offset)
    var show_stage: bool = _view in ["title", "menu", "charselect", "settings", "credits"]
    _view_char.art_only = _art_only
    _backdrop.art_mode = _art_only and _view == "charselect"
    _backdrop.queue_redraw()
    var world_on: bool = _title_world != null and _view in ["title", "menu"]
    if _title_world != null:
        _title_world.visible = world_on
        _title_world.active = world_on
        if world_on and not _arg_value("--species=").is_empty():  # otherwise the title leader is random
            _title_world.set_leader(_char_index)
    _stage_3d.set_stage_visible(show_stage and not (_view == "charselect" and _art_only) and not world_on)
    _stage_3d.set_species(_char_index)
    _stage_3d.set_model_angle(_model_angle)
    _stage_3d.show_rig_overlay = _show_rig and _view == "charselect" and not _view_modals.is_open()
    _stage_3d.show_badge = _view == "charselect"
    _view_boot.visible = (_view in ["title", "menu", "loading"]) or _quit_modal_open
    if _view_boot.visible:
        var boot_mode: String = "quit_modal" if _quit_modal_open else _view
        _view_boot.quit_confirm_index = _quit_idx
        _view_boot.concept_label_text = _concept_label()
        _view_boot.loading_label = _loading_label
        _view_boot.loading_progress = _loading_progress
        _view_boot.save_leader_id = _save_leader_species()
        _view_boot.save_info = _save_info()
        _view_boot.set_state(boot_mode, _menu_index, _play_drawer_open, _play_index, _is_save_available())
    _view_char.visible = _view == "charselect"
    if _view_char.visible:
        _view_char.set_state(
            _char_index,
            _move_index,
            _shift_math,
            _turntable,
            _show_rig,
            _stage_3d.get_rig_label_text()
        )
    _view_settings.visible = _view in ["settings", "credits"]
    if _view_settings.visible:
        _view_settings.set_mode(_view)
    _view_modals.visible = _view_modals.is_open()

## Save card numbers. Cascos balance and playtime are not recorded by GameState yet (D-1253 pending),
## so they read `shell_balance` / `play_seconds` when those exist and show 0 otherwise.
func _save_info() -> Dictionary:
    if not _arg_value("--fake-save=").is_empty():  # D-1204 debug sample
        return {"level": 12, "respect": 63, "cascos": 1240, "play_seconds": 12430.0}
    if _gs == null:
        return {}
    var info := {"level": 1, "respect": 0, "cascos": 0, "play_seconds": 0.0}
    var party_v: Variant = _gs.get("party")
    if party_v is Array and not (party_v as Array).is_empty() and (party_v as Array)[0] is Combatant:
        info["level"] = int(((party_v as Array)[0] as Combatant).level)
    var respect_v: Variant = _gs.get("respect")
    if respect_v != null:
        info["respect"] = int(respect_v.value)
    if "shell_balance" in _gs:
        info["cascos"] = int(_gs.get("shell_balance"))
    if "play_seconds" in _gs:
        info["play_seconds"] = float(_gs.get("play_seconds"))
    return info

func _save_leader_species() -> String:
    if not _arg_value("--fake-save=").is_empty():  # D-1204 debug: simulate a save with this leader
        return _arg_value("--fake-save=")
    if _gs == null:
        return ""
    var party_v: Variant = _gs.get("party")
    if party_v is Array and not (party_v as Array).is_empty():
        var lead: Variant = (party_v as Array)[0]
        if lead is Combatant:
            return str((lead as Combatant).species_id)
    return ""

func _is_save_available() -> bool:
    if not _arg_value("--fake-save=").is_empty():
        return true
    if _gs == null:
        return false
    var value: Variant = _gs.get("active_campaign_started")
    return value is bool and bool(value)

func _on_title_entered() -> void:
    _view = "menu"
    _play_drawer_open = false
    _sync_all_views()

func _on_menu_action(action_id: String) -> void:
    match action_id:
        "open_drawer":
            _play_drawer_open = true
            _play_index = 0
        "close_drawer":
            _play_drawer_open = false
        "new_game":
            _play_drawer_open = false
            _view = "charselect"
        "continue":
            _start_continue()
        "new_expedition":
            _start_new_expedition()
        "settings":
            _play_drawer_open = false
            _view = "settings"
        "credits":
            _play_drawer_open = false
            _view = "credits"
        "quit_prompt":
            _quit_modal_open = true
            _quit_idx = 1
        "quit_cancel":
            _quit_modal_open = false
        "quit_confirm":
            _quit_modal_open = false
            get_tree().quit()
            return
        _:
            pass
    _sync_all_views()

func _start_continue() -> void:
    if not _is_save_available():
        return
    _play_drawer_open = false
    _view = "loading"
    _loading_label = "ENTERING THE HUB"
    _loading_progress = 0.42
    _sync_all_views()
    _deferred_scene_change(_scene_hub())

func _start_new_expedition() -> void:
    _play_drawer_open = false
    if not _is_save_available():
        _safe_call(_gs, "start_new_campaign", ["abra"])
    _deferred_scene_change(_scene_hub())

func _on_back_to_menu() -> void:
    _view = "menu"
    _play_drawer_open = false
    _sync_all_views()

func _on_character_selected(idx: int) -> void:
    _char_index = clampi(idx, 0, _species_count() - 1)
    _move_index = 0
    _sync_all_views()

func _on_move_selected(idx: int) -> void:
    _move_index = clampi(idx, 0, 2)
    _sync_all_views()

func _on_confirm_protagonist() -> void:
    var spec: Dictionary = PreGameCatalog.get_protagonist_by_index(_char_index)
    var species_id: String = str(spec.get("id", "abra"))
    if _instant_roulette:
        _safe_call(_gs, "start_new_campaign", [species_id])
        _enter_expedition({"nature_id": _forced_nature_id})
        return
    _view_modals.open_confirm_char(_char_index)
    _sync_all_views()

func _on_open_skill_dossier() -> void:
    _view_modals.open_skill_dossier(_char_index, _move_index)
    _sync_all_views()

func _on_open_advanced_dossier(layer: int) -> void:
    _view_modals.open_advanced(_char_index, clampi(layer, 1, 4))
    _sync_all_views()

func _on_toggle_shift_math() -> void:
    _shift_math = not _shift_math
    _sync_all_views()

func _on_camera_action(action: String) -> void:
    match action:
        "rot_left":
            _model_angle = wrapf(_model_angle - PI / 6.0, -PI, PI)
        "rot_right":
            _model_angle = wrapf(_model_angle + PI / 6.0, -PI, PI)
        "toggle_turntable":
            _turntable = not _turntable
        "toggle_rig":
            _show_rig = not _show_rig
        "toggle_art":
            _art_only = _view_char.art_only
        "center":
            _model_angle = 0.28
            _zoom_offset = 0.0
            _backdrop.snap_camera()
            _backdrop.snap_state()
        _:
            pass
    _stage_3d.set_model_angle(_model_angle)
    _sync_all_views()

func _open_roulette_for_selection() -> void:
    _last_roulette_roll = _view_modals.open_roulette(_char_index, "NEW_GAME", _forced_nature_id, _read_reduce_motion())
    _sync_all_views()

func _on_settings_back_requested() -> void:
    _view = "menu"
    _sync_all_views()

func _on_settings_changed(settings: Dictionary) -> void:
    _settings = settings.duplicate(true)
    if _gs != null:
        PreGameCatalog.apply_settings_to_engine(_settings, _gs)
    _sync_all_views()

func _on_modal_closed(_which: String) -> void:
    _sync_all_views()

func _on_modal_species_changed(idx: int) -> void:
    _char_index = clampi(idx, 0, _species_count() - 1)
    _move_index = 0
    _sync_all_views()

func _on_start_roulette_from_confirm() -> void:
    var spec: Dictionary = PreGameCatalog.get_protagonist_by_index(_char_index)
    var species_id: String = str(spec.get("id", "abra"))
    _safe_call(_gs, "start_new_campaign", [species_id])
    # D-1219: a character that already has a Nature skips the roulette.
    if _gs != null and _forced_nature_id.is_empty() and bool(_safe_call(_gs, "has_character_nature", [species_id])):
        _view_modals.close_modal()
        _enter_expedition({})
        return
    _open_roulette_for_selection()

func _on_roulette_finished(result: Dictionary) -> void:
    _last_roulette_roll = result.duplicate(true)
    _sync_all_views()

func _on_roulette_enter_expedition(result: Dictionary) -> void:
    # D-1237: the roulette Enter plays the Nature -> Hub transition.
    _nht_begin_transition(result)

func _nht_auto_exit() -> void:
    await get_tree().process_frame
    var guard: int = 0
    while guard < 600 and is_inside_tree():
        var slot: NatureSlotView = _view_modals.get_slot()
        if slot != null and slot.is_settled():
            await get_tree().process_frame
            slot.request_exit()
            return
        await get_tree().process_frame
        guard += 1

func _nht_begin_transition(result: Dictionary) -> void:
    var nature_id: String = str(result.get("nature_id", ""))
    var offsets: Dictionary = {}
    if result.get("offsets") is Dictionary:
        offsets = result["offsets"] as Dictionary
    _safe_call(_gs, "roll_expedition_nature_and_prepare", [nature_id, offsets])
    _pending_scene = _scene_hub()
    if _suppress_scene_change():
        return  # Headless scenarios and capture batches never leave this scene.
    var opts: Dictionary = {
        "load_min_ms": _nht_load_min,
        "quit": _has_flag("--nht-quit"),
        "shots": _arg_value("--nht-shots="),
        "summary": _has_flag("--nht-summary"),
    }
    NatureHubTransition.begin(get_tree(), _scene_hub(), opts)

func _on_roulette_cancelled() -> void:
    _sync_all_views()

func _enter_expedition(result: Dictionary) -> void:
    var nature_id: String = str(result.get("nature_id", ""))
    var offsets: Dictionary = {}
    if result.get("offsets") is Dictionary:
        offsets = result["offsets"] as Dictionary
    _safe_call(_gs, "roll_expedition_nature_and_prepare", [nature_id, offsets])
    _view_modals.close_modal()
    _loading_label = "ENTERING THE FOREST"
    _loading_progress = 0.64
    _view = "loading"
    _sync_all_views()
    _deferred_scene_change(_scene_forest())

func _species_count() -> int:
    return maxi(1, PreGameCatalog.build_protagonist_list().size())

func _read_reduce_motion() -> bool:
    var row: Dictionary = PreGameCatalog.setting_row(_settings, "ACCESSIBILITY", "motion")
    return int(row.get("idx", 0)) == 1

func _cycle_concept() -> void:
    if _concept == "A":
        _concept = "B"
    elif _concept == "B":
        _concept = "C"
    else:
        _concept = "A"
    _sync_all_views()


func _concept_label() -> String:
    match _concept:
        "A":
            return "CONCEPT A: STATUS SPIRES"
        "B":
            return "CONCEPT B: TYPO VOID"
        "C":
            return "CONCEPT C: THRESHOLD"
    return "CONCEPT A: STATUS SPIRES"

func _gui_input(event: InputEvent) -> void:
    if not (event is InputEventMouse):
        return
    if _view_modals == null:
        return
    if _view_modals.is_open():
        if _view_modals.handle_gui_input(event):
            accept_event()
        return
    if _quit_modal_open or (_view in ["title", "menu", "loading"]):
        if _view_boot.handle_gui_input(event):
            accept_event()
        return
    if _view in ["settings", "credits"]:
        if _view_settings.handle_gui_input(event):
            accept_event()
        return
    if _view == "charselect":
        _charselect_gui_input(event)

func _charselect_gui_input(event: InputEvent) -> void:
    if _view_char.handle_gui_input(event):
        accept_event()
        return
    var pedestal: Rect2 = _view_char.get_pedestal_safe_rect()
    if event is InputEventMouseButton:
        var button: InputEventMouseButton = event as InputEventMouseButton
        if button.button_index == MOUSE_BUTTON_LEFT:
            if button.pressed and pedestal.has_point(button.position):
                _dragging = true
                _last_drag_x = button.position.x
                _turntable = false
                accept_event()
            elif not button.pressed and _dragging:
                _dragging = false
                _backdrop.snap_state()
                accept_event()
        elif button.pressed and pedestal.has_point(button.position):
            if button.button_index == MOUSE_BUTTON_WHEEL_UP:
                _zoom_offset = clampf(_zoom_offset - 0.06, -0.22, 0.32)
                _backdrop.set_camera_controls(_model_angle, _turntable, _zoom_offset)
                accept_event()
            elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
                _zoom_offset = clampf(_zoom_offset + 0.06, -0.22, 0.32)
                _backdrop.set_camera_controls(_model_angle, _turntable, _zoom_offset)
                accept_event()
    elif event is InputEventMouseMotion and _dragging:
        var motion: InputEventMouseMotion = event as InputEventMouseMotion
        var dx: float = motion.position.x - _last_drag_x
        _last_drag_x = motion.position.x
        _model_angle = wrapf(_model_angle + dx * 0.01, -PI, PI)
        _backdrop.stage_drag(dx)
        _stage_3d.set_model_angle(_model_angle)
        _backdrop.set_camera_controls(_model_angle, _turntable, _zoom_offset)
        accept_event()

func _input(event: InputEvent) -> void:
    _handle_key_event(event)

func _handle_key_event(event: InputEvent) -> bool:
    if not _headless_scenario.is_empty():
        return false
    if _view_modals == null or _view_settings == null:
        return false
    if not (event is InputEventKey):
        return false
    var key: InputEventKey = event as InputEventKey
    if not key.pressed:
        return false
    if _view in ["settings", "credits"] and not _view_settings.listening_key.is_empty():
        _view_settings.handle_gui_input(event)
        get_viewport().set_input_as_handled()
        return true
    var action: String = _key_to_action(key)
    if action.is_empty():
        return false
    _raw_key = key.keycode
    if key.echo and not _is_rotation_action(action):
        return false
    if _route_key_action(action):
        get_viewport().set_input_as_handled()
        return true
    return false

func _key_to_action(key: InputEventKey) -> String:
    var code: Key = key.keycode
    var shift: bool = key.shift_pressed
    match code:
        KEY_W, KEY_UP:
            return "up"
        KEY_S, KEY_DOWN:
            return "down"
        KEY_A, KEY_LEFT:
            return "left"
        KEY_D, KEY_RIGHT:
            return "right"
        KEY_Z, KEY_ENTER, KEY_KP_ENTER:
            return "enter"
        KEY_X, KEY_ESCAPE:
            return "back"
        KEY_TAB:
            return "tab_prev" if shift else "tab_next"
        KEY_SHIFT:
            return "shift"
        KEY_SPACE:
            return "space"
        KEY_Q:
            return "q"
        KEY_E:
            return "e"
        KEY_R:
            return "r"
        KEY_C:
            return "c"
        KEY_T:
            return "t"
        KEY_F:
            return "f"
        KEY_V:
            return "cycle_concept"
        KEY_1:
            return "1"
        KEY_2:
            return "2"
        KEY_3:
            return "3"
        KEY_4:
            return "4"
        _:
            return ""

func _route_key_action(action: String) -> bool:
    if _view_modals.is_open():
        return _view_modals.handle_key_action(_view_action(action, "modal"))
    if action == "cycle_concept" and (_view in ["title", "menu"]) and not _quit_modal_open:
        _cycle_concept()
        return true
    if _view == "title" and not _quit_modal_open and not _is_modifier_action(action):
        _view_boot.handle_key_action("enter")
        _on_title_entered()
        return true
    if _quit_modal_open or (_view in ["title", "menu", "loading"]):
        return _view_boot.handle_key_action(_view_action(action, "boot"))
    if _view in ["settings", "credits"]:
        return _view_settings.handle_key_action(_view_action(action, "settings"))
    if _view == "charselect":
        return _view_char.handle_key_action(_view_action(action, "charselect"))
    return false

## The controller's generic key names differ from what each view listens for
## (Z arrives as "enter", Tab as "tab_next", A/D as left/right). Translate per view
## so every key shown on screen works from the keyboard.
func _view_action(action: String, target: String) -> String:
    match target:
        "boot":
            return "confirm" if action == "enter" else action
        "settings":
            return "confirm" if action == "enter" else action
        "charselect":
            if _raw_key == KEY_A or action in ["tab_next", "tab_prev"]:
                return "advanced"
            if _raw_key == KEY_D:
                return "skill_dossier"
            return action
        "modal":
            match action:
                "enter":
                    return "confirm"
                "tab_next":
                    return "tab_right"
                "tab_prev":
                    return "tab_left"
                "space":
                    return "skip"
                "1", "2", "3", "4":
                    return "layer_" + action
            if _raw_key == KEY_A:
                return "toggle_adv"
            if _raw_key == KEY_D:
                return "toggle_dossier"
            if _raw_key == KEY_R:
                return "reveal"
    return action

func _is_modifier_action(action: String) -> bool:
    return action == "shift"

func _is_rotation_action(action: String) -> bool:
    return action in ["left", "right", "up", "down"]

func _run_headless_scenario(scenario: String) -> void:
    var failures: Array[String] = []
    var info: Array[String] = []
    var normalized: String = scenario.to_upper()
    match normalized:
        "PREGAME_BOOT":
            _scenario_boot(failures, info)
        "PREGAME_SLIME":
            _scenario_slime(failures, info)
        "PREGAME_D981":
            _scenario_d981(failures, info)
        "PREGAME_CAMPAIGN":
            _scenario_campaign(failures, info)
        "PREGAME_SETTINGS_CREDITS":
            _scenario_settings_credits(failures, info)
        "PREGAME_QUAD_AUDIT":
            _scenario_quad_audit(failures, info)
        "PREGAME_PARITY_LAYOUT":
            _scenario_parity_layout(failures, info)
        "PREGAME_ROULETTE":
            _scenario_roulette(failures, info)
        "PREGAME_KEYS":
            _scenario_keys(failures, info)
        _:
            failures.append("unknown scenario: %s" % scenario)
    var ok: bool = failures.is_empty()
    print("[PREGAME_SCENARIO] %s ok=%s" % [normalized, str(ok)])
    for failure in failures:
        printerr("[PREGAME_FAIL] " + failure)
    if _stdout_trace:
        for entry in info:
            print("[PREGAME_INFO] " + entry)
    _print_summary(normalized, ok, failures, info)
    get_tree().quit(0 if ok else 1)

## D-1226: real key events through the same path the keyboard uses.
func _press(code: Key, shift: bool = false) -> void:
    var saved: String = _headless_scenario
    _headless_scenario = ""
    var ev := InputEventKey.new()
    ev.keycode = code
    ev.pressed = true
    ev.shift_pressed = shift
    _handle_key_event(ev)
    _headless_scenario = saved

func _scenario_keys(failures: Array[String], info: Array[String]) -> void:
    _view = "menu"
    _play_drawer_open = false
    _sync_all_views()
    _press(KEY_Z)
    _check(_view_boot.play_drawer_open, "menu: Z did not open the PLAY drawer", failures)
    _press(KEY_X)
    _check(not _view_boot.play_drawer_open, "menu: X did not close the drawer", failures)
    _view = "charselect"
    _sync_all_views()
    _press(KEY_DOWN)
    _check(_char_index == 1, "charselect: Down did not select the next protagonist", failures)
    _press(KEY_RIGHT)
    _check(_move_index == 1, "charselect: Right did not select the next move", failures)
    _press(KEY_F)
    _check(_art_only, "charselect: F did not toggle ART view", failures)
    _press(KEY_F)
    _press(KEY_A)
    _check(_view_modals.is_open() and _view_modals.active_modal == "advanced", "charselect: A did not open the advanced dossier", failures)
    _press(KEY_A)
    _check(not _view_modals.is_open(), "advanced: A did not close the dossier", failures)
    _press(KEY_TAB)
    _check(_view_modals.is_open(), "charselect: Tab did not open the advanced dossier", failures)
    _press(KEY_X)
    _press(KEY_D)
    _check(_view_modals.is_open() and _view_modals.active_modal == "skill_dossier", "charselect: D did not open the skill dossier", failures)
    _press(KEY_X)
    _press(KEY_Z)
    _check(_view_modals.is_open() and _view_modals.active_modal == "confirm_char", "charselect: Z did not open the confirm modal", failures)
    _press(KEY_X)
    _check(not _view_modals.is_open(), "confirm modal: X did not close", failures)
    info.append("keys_checked=11")

func _print_summary(scenario: String, ok: bool, failures: Array[String], info: Array[String], extra: Dictionary = {}) -> void:
    var payload: Dictionary = {
        "controller": "PreGameController",
        "scenario": scenario,
        "ok": ok,
        "view": _view,
        "species": _char_index,
        "failures": failures,
        "info": info
    }
    for key in extra.keys():
        payload[key] = extra[key]
    var text: String = JSON.stringify(payload)
    print("[PREGAME_SUMMARY_JSON]")
    print("SUMMARY_JSON:" + text)

func _check(condition: bool, message: String, failures: Array[String]) -> bool:
    if not condition:
        failures.append(message)
    return condition

func _assert_catalog_integrity(failures: Array[String]) -> void:
    var species: Array = PreGameCatalog.build_protagonist_list()
    _check(species.size() == 6, "expected 6 species, got %d" % species.size(), failures)
    for index in species.size():
        var spec: Dictionary = species[index]
        var species_id: String = str(spec.get("id", "species_%d" % index))
        var portrait_tex: Texture2D = spec.get("portrait_icon") as Texture2D
        _check(portrait_tex != null, "species %s missing portrait icon" % species_id, failures)
        if portrait_tex != null and species_id.begins_with("dqt_"):
            var expected_portrait: String = "res://personagens/portraits/%s.png" % species_id.trim_prefix("dqt_")
            _check(portrait_tex.resource_path == expected_portrait, "species %s expected normal portrait %s, got %s" % [species_id, expected_portrait, portrait_tex.resource_path], failures)
        _check(int(spec.get("base_stats_total", 0)) == 15, "species %s base stat sum expected 15, got %d" % [species_id, int(spec.get("base_stats_total", 0))], failures)
        var starter_moves: Array = spec.get("starter_moves", [])
        _check(starter_moves.size() == 3, "species %s starter move count expected 3, got %d" % [species_id, starter_moves.size()], failures)
        for move_id in starter_moves:
            _check(PreGameCatalog.get_move_spec(str(move_id)).get("move") != null, "species %s missing MoveData for %s" % [species_id, str(move_id)], failures)
        _assert_combo_ev_rows(spec, species_id, failures)
    _assert_nature_copy(failures)

## D-1217 / D-144: each COMBO_EV_TABLE row must equal the NatureData mods applied
## to the 15-point base under the triangular offset distribution, with the 1-point
## floor of CrawlmonAttributeMath.consolidate_innate_attributes.
func _assert_combo_ev_rows(spec: Dictionary, species_id: String, failures: Array[String]) -> void:
    var rows: Dictionary = spec.get("combo_ev", {})
    _check(rows.size() == PreGameCatalog.NATURE_ORDER.size(), "species %s combo_ev expected %d natures, got %d" % [species_id, PreGameCatalog.NATURE_ORDER.size(), rows.size()], failures)
    for nature_id in PreGameCatalog.NATURE_ORDER:
        var parsed: Dictionary = _parse_combo_row(str(rows.get(nature_id, "")))
        if not _check(not parsed.is_empty(), "species %s/%s combo_ev row missing or unparsable" % [species_id, nature_id], failures):
            continue
        var expected: Dictionary = _combo_ev_expected(spec, nature_id)
        _check(int(parsed["base"]) == int(expected["base"]), "species %s/%s base combos expected %d, got %d" % [species_id, nature_id, int(expected["base"]), int(parsed["base"])], failures)
        _check(int(parsed["min"]) == int(expected["min"]), "species %s/%s EV min expected %d, got %d" % [species_id, nature_id, int(expected["min"]), int(parsed["min"])], failures)
        _check(int(parsed["max"]) == int(expected["max"]), "species %s/%s EV max expected %d, got %d" % [species_id, nature_id, int(expected["max"]), int(parsed["max"])], failures)
        _check(absf(float(parsed["ev"]) - float(expected["ev"])) <= 0.0051, "species %s/%s EV expected %.2f, got %.2f" % [species_id, nature_id, float(expected["ev"]), float(parsed["ev"])], failures)

func _combo_ev_expected(spec: Dictionary, nature_id: String) -> Dictionary:
    var base_stats: Dictionary = spec.get("base_stats", {})
    var mods: Dictionary = NatureData.get_nature(nature_id).get("mods", {})
    var base_label: int = 0
    var ev: float = 0.0
    var low: int = 0
    var high: int = 0
    for stat in PreGameCatalog.STAT_ORDER:
        var value: int = int(base_stats.get(stat, 0)) + int(mods.get(stat, 0))
        base_label += maxi(1, value)
        var ticket_total: float = 0.0
        var ticket_low: int = 999999
        var ticket_high: int = -999999
        for ticket in 16:
            var clamped: int = maxi(1, value + CrawlmonAttributeMath.individual_offset_from_ticket(ticket))
            ticket_total += float(clamped)
            ticket_low = mini(ticket_low, clamped)
            ticket_high = maxi(ticket_high, clamped)
        ev += ticket_total / 16.0
        low += ticket_low
        high += ticket_high
    return {"base": base_label, "ev": ev, "min": low, "max": high}

## Parses "15 / 16.75 [7..33]" into base / ev / min / max.
func _parse_combo_row(text: String) -> Dictionary:
    var trimmed: String = text.strip_edges()
    var slash: int = trimmed.find(" / ")
    var bracket: int = trimmed.find(" [")
    if slash < 0 or bracket < 0:
        return {}
    var bounds: PackedStringArray = trimmed.substr(bracket + 2).trim_suffix("]").split("..")
    if bounds.size() != 2:
        return {}
    return {
        "base": int(trimmed.substr(0, slash)),
        "ev": float(trimmed.substr(slash + 3, bracket - slash - 3)),
        "min": int(bounds[0]),
        "max": int(bounds[1])
    }

## D-1263: no Nature copy may cite numeric values or "+N STAT" (supersedes D-1217's citing rule).
func _assert_nature_copy(failures: Array[String]) -> void:
    _check(PreGameCatalog.NATURE_ORDER.size() == NatureData.NATURES.size(), "NATURE_ORDER size expected %d, got %d" % [NatureData.NATURES.size(), PreGameCatalog.NATURE_ORDER.size()], failures)
    var digits: RegEx = RegEx.new()
    digits.compile("[0-9]")
    for nature_id in PreGameCatalog.NATURE_ORDER:
        _check(NatureData.NATURES.has(nature_id), "NatureData missing %s" % nature_id, failures)
        var text: String = str(PreGameCatalog.NATURE_DESCRIPTIONS.get(nature_id, ""))
        _check(not text.is_empty(), "NATURE_DESCRIPTIONS missing %s" % nature_id, failures)
        _check(digits.search(text) == null, "NATURE_DESCRIPTIONS[%s] cites a number (D-1263)" % nature_id, failures)

## D-1215/D-1219 (D-1204): the 18 Natures show the right reel symbols whether the roll plays out,
## is skipped or runs with reduced motion, and the Nature stays with the character until it is erased.
func _scenario_roulette(failures: Array[String], info: Array[String]) -> void:
    _view_modals.roulette_muted = true
    for nature_id in PreGameCatalog.NATURE_ORDER:
        var expected: Array[String] = NatureSlotLogic.symbols_for(nature_id)
        _view_modals.open_roulette(0, "NEW_GAME", nature_id, false)
        var slot: NatureSlotView = _view_modals.get_slot()
        slot.frozen = true
        slot.advance(20000.0)
        var natural: Dictionary = slot.summary()
        _view_modals.open_roulette(0, "NEW_GAME", nature_id, false)
        slot.frozen = true
        slot.advance(1500.0)
        slot.skip()
        var skipped: Dictionary = slot.summary()
        _view_modals.open_roulette(0, "NEW_GAME", nature_id, true)
        var reduced: Dictionary = slot.summary()
        for pair in [["natural", natural], ["skip", skipped], ["reduce", reduced]]:
            var run: Dictionary = pair[1]
            _check(str(run.get("state", "")) == "SETTLED", "%s/%s did not reach SETTLED" % [nature_id, pair[0]], failures)
            _check(bool(run.get("match", false)) and run.get("shown") == expected, "%s/%s shows %s, expected %s" % [nature_id, pair[0], str(run.get("shown")), str(expected)], failures)
        info.append("%s -> %s" % [nature_id, str(expected)])
    # D-1215/D-1219: Enter only starts the exit wipe; the transition request comes after it.
    _view_modals.open_roulette(0, "NEW_GAME", "brave", true)
    var exit_slot: NatureSlotView = _view_modals.get_slot()
    exit_slot.frozen = true
    var exit_fired: Array[bool] = [false]
    exit_slot.enter_requested.connect(func() -> void: exit_fired[0] = true)
    _check(exit_slot.request_exit(), "request_exit refused while SETTLED", failures)
    exit_slot.advance(300.0)
    _check(not exit_fired[0], "transition fired before the wipe ended", failures)
    exit_slot.advance(600.0)
    _check(exit_fired[0], "transition did not fire after the wipe", failures)
    _view_modals.close_modal()
    var gs: Node = _gs
    _check(gs != null, "GameState missing", failures)
    if gs == null:
        return
    gs.call("start_new_campaign", "abra")
    gs.call("clear_character_nature", "abra")
    _check(not bool(gs.call("has_character_nature", "abra")), "abra should start without a Nature", failures)
    var first: Dictionary = gs.call("roll_expedition_nature_and_prepare", "bold", {})
    _check(bool(gs.call("has_character_nature", "abra")), "Nature not stored for abra", failures)
    var second: Dictionary = gs.call("roll_expedition_nature_and_prepare", "", {})
    _check(str(second.get("nature_id", "")) == "bold", "stored Nature changed between expeditions", failures)
    _check(first.get("offsets") == second.get("offsets"), "individual offsets changed between expeditions", failures)
    gs.call("clear_character_nature", "abra")
    _check(not bool(gs.call("has_character_nature", "abra")), "game over did not erase the Nature", failures)

func _scenario_boot(failures: Array[String], info: Array[String]) -> void:
    _assert_catalog_integrity(failures)
    var species: Array = PreGameCatalog.build_protagonist_list()
    _check(species.size() == 6, "expected 6 species, got %d" % species.size(), failures)
    for index in species.size():
        var spec: Dictionary = species[index]
        _check(not str(spec.get("id", "")).is_empty(), "species %d missing id" % index, failures)
        _check(not str(spec.get("name", "")).is_empty(), "species %d missing name" % index, failures)
        _check(spec.get("base_stats") is Dictionary, "species %d missing base_stats" % index, failures)
        _check(not PreGameCatalog.get_protagonist_by_index(index).is_empty(), "species %d lookup failed" % index, failures)
    _view = "title"
    _sync_all_views()
    _on_title_entered()
    _check(_view == "menu", "title did not enter menu", failures)
    _on_menu_action("open_drawer")
    _check(_play_drawer_open, "drawer did not open", failures)
    _on_menu_action("close_drawer")
    _check(not _play_drawer_open, "drawer did not close", failures)
    var natures: Array = PreGameCatalog.NATURES_LIST()
    _check(natures.size() == 18, "expected 18 natures, got %d" % natures.size(), failures)
    _check(PreGameCatalog.NATURE_ORDER.size() == 18, "NATURE_ORDER size mismatch", failures)
    var combos: int = 0
    for species_index in species.size():
        var species_spec: Dictionary = species[species_index]
        for nature_entry in natures:
            var nature_spec: Dictionary = nature_entry
            var nature_id: String = str(nature_spec.get("id", ""))
            if nature_id.is_empty():
                continue
            var stats: Dictionary = PreGameCatalog.consolidate_stats(species_spec, nature_id, {}, 1)
            if not stats.is_empty():
                combos += 1
    _check(combos == 108, "expected 108 species/nature combos, got %d" % combos, failures)
    info.append("species=6 natures=8 combos=%d" % combos)
    _view = "menu"
    _sync_all_views()

func _scenario_slime(failures: Array[String], info: Array[String]) -> void:
    var slime_index: int = _species_index_of("dqt_slime")
    _check(slime_index >= 0, "slime species not found", failures)
    if slime_index < 0:
        return
    _char_index = slime_index
    var spec: Dictionary = PreGameCatalog.get_protagonist_by_index(slime_index)
    var base_stats: Dictionary = spec.get("base_stats", {})
    var total: int = _sum_numeric(base_stats)
    _check(total == 15, "slime base stat sum expected 15, got %d" % total, failures)
    var starters: Array = spec.get("starter_moves", [])
    _check(starters.size() == 3, "slime starter move count expected 3, got %d" % starters.size(), failures)
    var expected: Array[String] = ["tackle", "bubble_shot", "heal"]
    for move_id in expected:
        _check(starters.has(move_id), "slime missing starter move %s" % move_id, failures)
        var move_spec: Dictionary = PreGameCatalog.get_move_spec(move_id)
        _check(move_spec.get("move") != null, "missing MoveData for %s" % move_id, failures)
    var nature_id: String = _first_nature_id()
    var stats: Dictionary = PreGameCatalog.consolidate_stats(spec, nature_id, {}, 1)
    _check(not stats.is_empty(), "slime consolidated stats empty", failures)
    info.append("slime_base=%d starters=%d nature=%s" % [total, starters.size(), nature_id])

func _scenario_d981(failures: Array[String], info: Array[String]) -> void:
    _char_index = 0
    _view = "charselect"
    _sync_all_views()
    _view_modals.open_advanced(_char_index, 2)
    _check(_view_modals.is_open(), "advanced dossier did not open", failures)
    _check(not _view_modals.reveal_unknowns, "reveal_unknowns should start false", failures)
    _view_modals.reveal_unknowns = true
    _check(_view_modals.reveal_unknowns, "reveal_unknowns toggle failed", failures)
    _view_modals.open_advanced(_char_index, 3)
    _check(_view_modals.adv_layer == 3, "advanced layer expected 3, got %d" % _view_modals.adv_layer, failures)
    _view_modals.open_advanced(_char_index, 2)
    _check(_view_modals.adv_layer == 2, "advanced layer expected 2, got %d" % _view_modals.adv_layer, failures)
    _view_modals.close_modal()
    _sync_all_views()
    var spec: Dictionary = PreGameCatalog.get_protagonist_by_index(_char_index)
    var natures_count: int = PreGameCatalog.NATURES_LIST().size()
    _check(natures_count == 18, "D-1216 expected 18 natures, got %d" % natures_count, failures)
    var matrix: Dictionary = spec.get("combo_ev", {})
    _check(matrix.size() == PreGameCatalog.NATURE_ORDER.size(), "combo_ev expected %d natures, got %d" % [PreGameCatalog.NATURE_ORDER.size(), matrix.size()], failures)
    var nature_id: String = _first_nature_id()
    var base_stats: Dictionary = PreGameCatalog.consolidate_stats(spec, nature_id, {}, 1)
    var base_flat: Dictionary = _flatten_stats(base_stats)
    var stat_key: String = _preferred_stat_key(base_flat)
    _check(not stat_key.is_empty(), "no numeric stat exposed for math check", failures)
    if not stat_key.is_empty():
        var base_value: int = int(base_flat.get(stat_key, 0))
        var bump: Dictionary = {}
        bump[stat_key] = 5
        var bumped_flat: Dictionary = _flatten_stats(PreGameCatalog.consolidate_stats(spec, nature_id, bump, 1))
        _check(int(bumped_flat.get(stat_key, 0)) == base_value + 5, "consolidated offset math mismatch on %s" % stat_key, failures)
        var floor_offsets: Dictionary = {}
        floor_offsets[stat_key] = -9999
        var floored_flat: Dictionary = _flatten_stats(PreGameCatalog.consolidate_stats(spec, nature_id, floor_offsets, 1))
        _check(int(floored_flat.get(stat_key, 0)) >= 1, "consolidated stat floor should be 1 on %s" % stat_key, failures)
    var other_nature: String = _nature_id_at(2)
    if not other_nature.is_empty() and other_nature != nature_id:
        var other_flat: Dictionary = _flatten_stats(PreGameCatalog.consolidate_stats(spec, other_nature, {}, 1))
        var nature_delta: bool = false
        for key in base_flat.keys():
            if other_flat.has(key) and int(other_flat[key]) != int(base_flat[key]):
                nature_delta = true
                break
        _check(nature_delta, "expected non-neutral nature %s to alter consolidated stats" % other_nature, failures)
        info.append("nature_delta=%s" % str(nature_delta))
    info.append("natures=%d matrix=%d stat_key=%s" % [natures_count, matrix.size(), stat_key])

func _scenario_campaign(failures: Array[String], info: Array[String]) -> void:
    _check(_gs != null, "GameState autoload unavailable", failures)
    _char_index = _species_index_of("abra")
    if _char_index < 0:
        _char_index = 0
    _view = "charselect"
    _sync_all_views()
    _last_roulette_roll = _view_modals.open_roulette(_char_index, "NEW_GAME", "calm", true)
    _check(_view_modals.is_open(), "roulette did not open", failures)
    _view_modals.skip_roulette()
    var locked_before: Dictionary = _view_modals.roulette_locked_result.duplicate(true)
    var nature_before: String = str(locked_before.get("nature_id", ""))
    var signature_before: String = str(locked_before)
    _view_modals.skip_roulette()
    var locked_after: Dictionary = _view_modals.roulette_locked_result.duplicate(true)
    var nature_after: String = str(locked_after.get("nature_id", ""))
    var signature_after: String = str(locked_after)
    _check(signature_before == signature_after, "skip_roulette changed the locked result", failures)
    _check(nature_before == nature_after, "skip_roulette changed the locked nature", failures)
    _check(not nature_after.is_empty(), "roulette locked nature is empty", failures)
    _view_modals.close_modal()
    _sync_all_views()
    var slime_index: int = _species_index_of("dqt_slime")
    _check(slime_index >= 0, "slime species not found", failures)
    if slime_index < 0:
        return
    _char_index = slime_index
    _sync_all_views()
    _safe_call(_gs, "start_new_campaign", ["dqt_slime"])
    _safe_call(_gs, "roll_expedition_nature_and_prepare", [nature_after])
    var party_size: int = 0
    if _gs != null:
        var party_value: Variant = _gs.get("party")
        if party_value is Array:
            var party: Array = party_value
            party_size = party.size()
            _check(party_size == 1, "party size expected 1 (leader only, D-1261), got %d" % party_size, failures)
            if party_size > 0:
                var leader_v: Variant = party[0]
                if leader_v is Dictionary:
                    var leader: Dictionary = leader_v
                    var leader_id: String = str(leader.get("species_id", leader.get("id", "")))
                    _check(leader_id == "dqt_slime", "party leader expected dqt_slime, got %s" % leader_id, failures)
                    var leader_nature: String = _extract_nature_id(leader)
                    if leader_nature.is_empty():
                        info.append("party leader nature not exposed")
                    else:
                        _check(leader_nature == nature_after, "party leader nature expected %s, got %s" % [nature_after, leader_nature], failures)
                elif leader_v is Object:
                    var leader_obj: Object = leader_v
                    var leader_id: String = ""
                    if _gs.has_method("species_key"):
                        leader_id = str(_gs.call("species_key", leader_obj))
                    else:
                        leader_id = str(leader_obj.get("species_id"))
                    _check(leader_id == "dqt_slime", "party leader expected dqt_slime, got %s" % leader_id, failures)
                    var leader_nature: String = str(leader_obj.get("nature_id"))
                    if leader_nature.is_empty():
                        info.append("party leader nature not exposed")
                    else:
                        _check(leader_nature == nature_after, "party leader nature expected %s, got %s" % [nature_after, leader_nature], failures)
                else:
                    failures.append("GameState.party[0] is neither Dictionary nor Object")
        else:
            failures.append("GameState.party is not an Array")
    info.append("party=%d locked_nature=%s" % [party_size, nature_after])

func _scenario_settings_credits(failures: Array[String], info: Array[String]) -> void:
    var tabs: Array = PreGameCatalog.SETTINGS_TAB_ORDER
    _check(tabs.size() == 5, "settings tab count expected 5, got %d" % tabs.size(), failures)
    _view = "settings"
    _view_settings.visible = true
    for tab_index in mini(tabs.size(), 5):
        _view_settings.settings_tab_idx = tab_index
        _view_settings.set_mode("settings")
        _sync_all_views()
        _check(_view_settings.settings_tab_idx == tab_index, "settings tab index expected %d" % tab_index, failures)
    var tab_id: String = ""
    if not tabs.is_empty():
        tab_id = str(tabs[0])
    var setting_key: String = _first_setting_key(_settings, tab_id)
    _check(not setting_key.is_empty(), "no setting key available in tab %s" % tab_id, failures)
    if not setting_key.is_empty():
        var row: Dictionary = PreGameCatalog.setting_row(_settings, tab_id, setting_key)
        var next_value: Variant = 0
        if row.has("idx"):
            var opts: Array = row.get("opts", [])
            next_value = (int(row.get("idx", 0)) + 1) % maxi(opts.size(), 1)
        elif row.has("val"):
            var cur: int = int(row.get("val", 50))
            next_value = (cur + 10) if cur <= 90 else 50
        var written: bool = _set_setting_value(_settings, tab_id, setting_key, next_value)
        _check(written, "failed to write setting %s.%s" % [tab_id, setting_key], failures)
        var stored_value: Variant = _read_setting_value(_settings, tab_id, setting_key)
        _check(str(stored_value) == str(next_value), "setting value did not persist", failures)
        _on_settings_changed(_settings)
        info.append("setting=%s.%s value=%s" % [tab_id, setting_key, str(next_value)])
    if _gs != null:
        PreGameCatalog.apply_settings_to_engine(_settings, _gs)
        info.append("apply_settings_to_engine=ok")
    else:
        info.append("apply_settings_to_engine=skipped")
    _view = "credits"
    _view_settings.set_mode("credits")
    _sync_all_views()
    _check(_view_settings.visible, "credits view should be visible", failures)
    info.append("tabs=%d" % tabs.size())

func _scenario_quad_audit(failures: Array[String], info: Array[String]) -> void:
    var resolutions: Array[Vector2] = [Vector2(960.0, 540.0), Vector2(1280.0, 720.0), Vector2(1600.0, 900.0), Vector2(1920.0, 1080.0)]
    var violations: Array = []
    var previous_size: Vector2 = size
    _view = "charselect"
    for resolution in resolutions:
        _resize_tree(resolution)
        for species_index in 6:
            _char_index = species_index
            _sync_all_views()
            var rects: Dictionary = _view_char.get_quad_audit_rects()
            var required: Array[String] = ["roster", "pedestal", "affinity", "dossier", "confirm_btn", "deck", "footer"]
            for key in required:
                if not rects.has(key):
                    violations.append(_violation(resolution, species_index, "missing:%s" % key))
                    continue
                var rect: Rect2 = rects[key]
                if rect.position.x < -0.5 or rect.position.y < -0.5 or rect.end.x > resolution.x + 0.5 or rect.end.y > resolution.y + 0.5:
                    violations.append(_violation(resolution, species_index, "bounds:%s" % key))
            var no_overlap: Array[String] = ["roster", "affinity", "dossier", "confirm_btn", "deck", "footer"]
            for left_index in no_overlap.size():
                for right_index in range(left_index + 1, no_overlap.size()):
                    var left_key: String = no_overlap[left_index]
                    var right_key: String = no_overlap[right_index]
                    if rects.has(left_key) and rects.has(right_key):
                        var left_rect: Rect2 = rects[left_key]
                        var right_rect: Rect2 = rects[right_key]
                        if _rects_overlap(left_rect, right_rect, 2.0):
                            violations.append(_violation(resolution, species_index, "overlap:%s/%s" % [left_key, right_key]))
            var pedestal_keys: Array[String] = ["roster", "dossier", "confirm_btn", "deck", "footer"]
            for key in pedestal_keys:
                if rects.has("pedestal") and rects.has(key):
                    var pedestal_rect: Rect2 = rects["pedestal"]
                    var other_rect: Rect2 = rects[key]
                    if _rects_overlap(pedestal_rect, other_rect, 2.0):
                        violations.append(_violation(resolution, species_index, "pedestal_overlap:%s" % key))
    _resize_tree(previous_size)
    _char_index = 0
    _sync_all_views()
    var ok: bool = violations.is_empty()
    _check(ok, "quad audit reported %d violation(s)" % violations.size(), failures)
    print("QUAD_AUDIT_JSON:" + JSON.stringify({"ok": ok, "violations": violations}))
    info.append("quad_audit_resolutions=%d species=6 violations=%d" % [resolutions.size(), violations.size()])

func _scenario_parity_layout(failures: Array[String], info: Array[String]) -> void:
    _assert_catalog_integrity(failures)
    var started_ms: int = Time.get_ticks_msec()
    _view = "title"
    _sync_all_views()
    _assert_layout("title", failures)
    _view = "menu"
    _sync_all_views()
    _assert_layout("menu", failures)
    _play_drawer_open = true
    _play_index = 0
    _sync_all_views()
    _assert_layout("menu_drawer", failures)
    _play_drawer_open = false
    if _view_modals.is_open():
        _view_modals.close_modal()
    _view = "charselect"
    _char_index = 0
    _sync_all_views()
    _assert_layout("charselect", failures)
    _view_modals.open_skill_dossier(0, 0)
    _sync_all_views()
    _assert_layout("skill_dossier", failures)
    _view_modals.close_modal()
    _sync_all_views()
    _view_modals.open_confirm_char(0)
    _sync_all_views()
    _assert_layout("confirm_char", failures)
    _view_modals.close_modal()
    _sync_all_views()
    for layer in range(1, 5):
        _view_modals.open_advanced(0, layer)
        _sync_all_views()
        _assert_layout("advanced_%d" % layer, failures)
        _view_modals.close_modal()
        _sync_all_views()
    _last_roulette_roll = _view_modals.open_roulette(0, "NEW_GAME", _forced_nature_id, true)
    _sync_all_views()
    _assert_layout("roulette", failures)
    _view_modals.skip_roulette()
    _sync_all_views()
    _assert_layout("roulette_locked", failures)
    _view_modals.close_modal()
    _sync_all_views()
    _view = "settings"
    for tab_index in 5:
        _view_settings.settings_tab_idx = tab_index
        _view_settings.set_mode("settings")
        _sync_all_views()
        _assert_layout("settings_%d" % tab_index, failures)
    _view = "credits"
    _sync_all_views()
    _assert_layout("credits", failures)
    _view = "menu"
    _quit_modal_open = true
    _quit_idx = 1
    _sync_all_views()
    _assert_layout("quit_modal", failures)
    _quit_modal_open = false
    _view = "loading"
    _loading_label = "LOADING"
    _loading_progress = 0.5
    _sync_all_views()
    _assert_layout("loading", failures)
    _view = "menu"
    _loading_label = ""
    _loading_progress = -1.0
    _sync_all_views()
    var elapsed_ms: int = Time.get_ticks_msec() - started_ms
    _check(elapsed_ms < 1000, "parity layout exceeded 1s: %dms" % elapsed_ms, failures)
    info.append("parity_layout_ms=%d" % elapsed_ms)

func _assert_layout(label: String, failures: Array[String]) -> void:
    var boot_expected: bool = (_view in ["title", "menu", "loading"]) or _quit_modal_open
    _check(_view_boot.visible == boot_expected, label + ": boot visibility mismatch", failures)
    _check(_view_char.visible == (_view == "charselect"), label + ": charselect visibility mismatch", failures)
    _check(_view_settings.visible == (_view in ["settings", "credits"]), label + ": settings visibility mismatch", failures)
    _check(_view_modals.visible == _view_modals.is_open(), label + ": modals visibility mismatch", failures)

func _take_screenshot(path: String) -> void:
    for _i in 8:
        await get_tree().process_frame
    _save_viewport_png(path)

func _save_viewport_png(path: String) -> void:
    if path.is_empty():
        return
    var base_dir: String = path.get_base_dir()
    if not base_dir.is_empty():
        DirAccess.make_dir_recursive_absolute(base_dir)
    var image: Image = get_viewport().get_texture().get_image()
    if image == null:
        printerr("[PREGAME_SHOT] viewport image unavailable: " + path)
        return
    var error: Error = image.save_png(path)
    if error == OK:
        print("[PREGAME_SHOT] path=" + path)
    else:
        printerr("[PREGAME_SHOT] save failed path=%s error=%d" % [path, error])

func _capture_parity_batch(dir: String) -> void:
    _capture_parity = true
    _backdrop.frozen = true
    _stage_3d.set_frozen(true)
    _turntable = false
    DirAccess.make_dir_recursive_absolute(dir)
    var count: int = 0
    _view = "title"
    await _capture_step(dir, "gd_01_title.png")
    count += 1
    _view = "menu"
    _play_drawer_open = false
    await _capture_step(dir, "gd_02_menu.png")
    count += 1
    _play_drawer_open = true
    _play_index = 0
    await _capture_step(dir, "gd_03_drawer.png")
    count += 1
    _play_drawer_open = false
    _view = "charselect"
    _char_index = 0
    await _capture_step(dir, "gd_04_char_abra.png")
    count += 1
    _char_index = _species_index_of("dqt_slime")
    if _char_index < 0:
        _char_index = 3
    await _capture_step(dir, "gd_05_char_slime.png")
    count += 1
    _char_index = 0
    _view_modals.open_skill_dossier(0, 0)
    await _capture_step(dir, "gd_06_skill_dossier.png")
    count += 1
    _view_modals.close_modal()
    _view_modals.open_confirm_char(0)
    await _capture_step(dir, "gd_07_confirm.png")
    count += 1
    _view_modals.close_modal()
    for layer in range(1, 5):
        _view_modals.open_advanced(0, layer)
        await _capture_step(dir, "gd_08_adv_%d.png" % layer)
        count += 1
        _view_modals.close_modal()
    _last_roulette_roll = _view_modals.open_roulette(0, "NEW_GAME", "calm", true)
    _view_modals.skip_roulette()
    await _capture_step(dir, "gd_09_roulette.png")
    count += 1
    _view_modals.close_modal()
    _view = "settings"
    var settings_names: Array[String] = ["video", "audio", "ctrl", "play", "a11y"]
    for tab_index in settings_names.size():
        _view_settings.settings_tab_idx = tab_index
        _view_settings.set_mode("settings")
        await _capture_step(dir, "gd_10_set_%s.png" % settings_names[tab_index])
        count += 1
    _view = "credits"
    await _capture_step(dir, "gd_12_credits.png")
    count += 1
    _sync_all_views()
    print("[PREGAME_PARITY] count=%d dir=%s" % [count, dir])
    if _quit_after:
        get_tree().quit(0)


func _capture_species_batch(dir: String) -> void:
    _capture_parity = true
    _backdrop.frozen = true
    _stage_3d.set_frozen(true)
    _turntable = false
    DirAccess.make_dir_recursive_absolute(dir)
    _view = "charselect"
    var species: Array = PreGameCatalog.build_protagonist_list()
    var captured: int = 0
    for index in mini(species.size(), 6):
        var spec: Dictionary = species[index]
        var species_id: String = str(spec.get("id", "species_%d" % index))
        _char_index = index
        await _capture_step(dir, "sp_%d_%s.png" % [index, species_id])
        captured += 1
    var info: Array[String] = ["species_captured=%d" % captured]
    print("[PREGAME_SPECIES_CAPTURE] captured=%d dir=%s" % [captured, dir])
    if _summary_json:
        _print_summary("PREGAME_SPECIES_CAPTURE", captured == 6, [], info, {"species_captured": captured})
    if _quit_after:
        get_tree().quit(0)

func _capture_step(dir: String, file_name: String) -> void:
    _sync_all_views()
    if _view_boot != null:
        _view_boot.queue_redraw()
    if _view_char != null:
        _view_char.queue_redraw()
    if _view_settings != null:
        _view_settings.queue_redraw()
    if _view_modals != null:
        _view_modals.queue_redraw()
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    _save_viewport_png(dir.path_join(file_name))

func _scene_hub() -> String:
    if _gs != null:
        var value: Variant = _gs.get("HUB_3D")
        if value is String and not str(value).is_empty():
            return str(value)
    return HUB_SCENE

func _scene_forest() -> String:
    if _gs != null:
        var value: Variant = _gs.get("MURKY_FOREST_3D")
        if value is String and not str(value).is_empty():
            return str(value)
    return FOREST_SCENE

func _change_scene_deferred(path: String) -> void:
    if path.is_empty():
        return
    get_tree().call_deferred("change_scene_to_file", path)

func _deferred_scene_change(path: String) -> void:
    _pending_scene = path
    if _suppress_scene_change():
        return
    get_tree().call_deferred("change_scene_to_file", path)

func _suppress_scene_change() -> bool:
    return not _headless_scenario.is_empty() or not _capture_parity_dir.is_empty() or not _capture_species_dir.is_empty() or _capture_parity

func _safe_call(target: Object, method_name: String, args: Array) -> Variant:
    if target == null:
        return null
    if not target.has_method(method_name):
        return null
    return target.callv(method_name, args)

func _species_index_of(species_id: String) -> int:
    var species: Array = PreGameCatalog.build_protagonist_list()
    for index in species.size():
        var spec: Dictionary = species[index]
        if str(spec.get("id", "")) == species_id:
            return index
    return -1

func _resolve_species_index(raw: String) -> int:
    if raw.is_valid_int():
        return clampi(int(raw), 0, _species_count() - 1)
    var resolved: int = _species_index_of(raw)
    if resolved >= 0:
        return resolved
    return 0

func _first_nature_id() -> String:
    var natures: Array = PreGameCatalog.NATURES_LIST()
    if natures.is_empty():
        return ""
    var first: Dictionary = natures[0]
    return str(first.get("id", ""))

func _nature_id_at(index: int) -> String:
    var natures: Array = PreGameCatalog.NATURES_LIST()
    if natures.is_empty():
        return ""
    var safe_index: int = clampi(index, 0, natures.size() - 1)
    var entry: Dictionary = natures[safe_index]
    return str(entry.get("id", ""))

func _sum_numeric(source: Dictionary) -> int:
    var total: int = 0
    for key in source.keys():
        var value: Variant = source[key]
        if value is int:
            total += int(value)
        elif value is float:
            total += int(round(float(value)))
    return total

func _flatten_stats(source: Dictionary) -> Dictionary:
    var flattened: Dictionary = {}
    var nested_keys: Array[String] = ["stats", "final_stats", "combined", "totals"]
    for nested_key in nested_keys:
        var candidate: Variant = source.get(nested_key, null)
        if candidate is Dictionary:
            var inner: Dictionary = candidate
            for key in inner.keys():
                var value: Variant = inner[key]
                if value is int or value is float:
                    flattened[str(key)] = int(round(float(value)))
            if not flattened.is_empty():
                return flattened
    for key in source.keys():
        var value: Variant = source[key]
        if value is int or value is float:
            flattened[str(key)] = int(round(float(value)))
        elif value is Dictionary:
            var entry: Dictionary = value
            for stat_key in ["total", "final", "value", "current"]:
                if entry.has(stat_key):
                    var stat_value: Variant = entry[stat_key]
                    if stat_value is int or stat_value is float:
                        flattened[str(key)] = int(round(float(stat_value)))
                        break
    return flattened

func _preferred_stat_key(stats: Dictionary) -> String:
    if stats.is_empty():
        return ""
    var preferred: Array[String] = ["STR", "MAG", "VIT", "WIS", "AGI", "LUK", "hp", "health", "atk", "attack"]
    for key in preferred:
        if stats.has(key):
            return key
    for key in stats.keys():
        return str(key)
    return ""

func _bump_value(value: Variant) -> Variant:
    if value is bool:
        return not bool(value)
    if value is int:
        return int(value) + 1
    if value is float:
        return float(value) + 0.1
    if value is String:
        return str(value) + " "
    return value

func _first_setting_key(settings: Dictionary, tab: String) -> String:
    var tab_value: Variant = settings.get(tab, null)
    if tab_value is Array:
        var rows: Array = tab_value
        for row_v in rows:
            if row_v is Dictionary:
                return str((row_v as Dictionary).get("key", ""))
        return ""
    if tab_value is Dictionary:
        var tab_dict: Dictionary = tab_value
        for key in tab_dict.keys():
            return str(key)
    return ""

func _read_setting_value(settings: Dictionary, tab: String, key: String) -> Variant:
    var tab_value: Variant = settings.get(tab, null)
    if tab_value is Array:
        var rows: Array = tab_value
        for row_v in rows:
            if row_v is Dictionary:
                var row: Dictionary = row_v
                if str(row.get("key", "")).to_lower() == key.to_lower():
                    if row.has("idx"):
                        return int(row.get("idx", 0))
                    if row.has("val"):
                        return row.get("val")
                    return null
        return null
    if not (tab_value is Dictionary):
        return null
    var tab_dict: Dictionary = tab_value
    var entry: Variant = tab_dict.get(key, null)
    if entry is Dictionary:
        var entry_dict: Dictionary = entry
        return entry_dict.get("value")
    return entry

func _set_setting_value(settings: Dictionary, tab: String, key: String, value: Variant) -> bool:
    var tab_value: Variant = settings.get(tab, null)
    if tab_value is Array:
        var rows: Array = tab_value
        for row_v in rows:
            if row_v is Dictionary:
                var row: Dictionary = row_v
                if str(row.get("key", "")).to_lower() == key.to_lower():
                    if row.has("idx"):
                        row["idx"] = int(value)
                    elif row.has("val"):
                        row["val"] = value
                    else:
                        return false
                    return true
        return false
    if not (tab_value is Dictionary):
        return false
    var tab_dict: Dictionary = tab_value
    var entry: Variant = tab_dict.get(key, null)
    if entry is Dictionary:
        var entry_dict: Dictionary = entry
        entry_dict["value"] = value
        tab_dict[key] = entry_dict
        settings[tab] = tab_dict
        return true
    return false

func _violation(resolution: Vector2, species_index: int, reason: String) -> Dictionary:
    return {"res": "%dx%d" % [int(resolution.x), int(resolution.y)], "species": species_index, "reason": reason}

func _rects_overlap(left: Rect2, right: Rect2, tolerance: float) -> bool:
    var inner_left: Rect2 = left.grow(-tolerance)
    var inner_right: Rect2 = right.grow(-tolerance)
    if inner_left.size.x <= 0.0 or inner_left.size.y <= 0.0:
        return false
    if inner_right.size.x <= 0.0 or inner_right.size.y <= 0.0:
        return false
    return inner_left.intersects(inner_right)

func _resize_tree(target: Vector2) -> void:
    size = target
    _backdrop.size = target
    _stage_3d.size = target
    _view_boot.size = target
    _view_char.size = target
    _view_settings.size = target
    _view_modals.size = target

func _extract_nature_id(entry: Dictionary) -> String:
    for key in ["nature_id", "natureId", "nature"]:
        if entry.has(key):
            var value: Variant = entry[key]
            if value is String:
                return str(value)
            if value is Dictionary:
                var nested: Dictionary = value
                var nested_id: String = str(nested.get("id", ""))
                if not nested_id.is_empty():
                    return nested_id
    return ""
