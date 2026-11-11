extends Node3D
## D-377: laboratório isolado da Drain Spear no Godot. Usa a arena real, o Orc real (DQT), a câmera CINEMA do
## `drain_spear (1).html` e os cenários A–H do `crawlmon_prot_tipo`. O efeito é um MotionEffect; este script só
## entrega posições, relógios e câmera. Não é o Move no combate e não altera nenhuma regra do jogo.
##
## Abrir: scenes/debug/drain_spear_lab.tscn (F6) ou
##   Godot --path . res://scenes/debug/drain_spear_lab.tscn
## CLI: --scenario=A..H --time=1.85 --shot=arquivo.png --record=4.2 --step=0.0333 --out=pasta
##      --mirror --camera=free --clean --quit

const BattleArena = preload("res://scripts/combat/battle_arena.gd")
const BattleCamera = preload("res://scripts/combat/battle_camera.gd")
const DqtModelProfiles = preload("res://scripts/combat/dqt_model_profiles.gd")
const DqtEyes = preload("res://scripts/combat/dqt_eyes.gd")
const VfxLib = preload("res://scripts/combat/vfx_lib.gd")
const DrainSpearVfx = preload("res://scripts/vfx/drain_spear_vfx.gd")
const DrainSpearHud = preload("res://scripts/ui/drain_spear_lab_hud.gd")

const CINEMA_POS := Vector3(3.8, 2.875, 7.0)
const CINEMA_LOOK := Vector3(-2.0, 0.0, -20.0)
const FOV := 80.0
const TILT_DEG := 4.0
const NEAR := Vector3(2.0, 0.0, -2.0)
const FAR := Vector3(-6.09, 0.0, -16.16)
const MID_CENTER := 16.3
const MID_MIN := 15.3
const MID_MAX := 17.3
const MELEE_REF := 2.6
const SPEAR_LENGTH := 2.7
const BLADE_LENGTH := 1.0
const TOTAL := 4.3
const FORM_END := 0.8
const TURN_END := 1.0
const MOVE_START := 1.0
const MOVE_END := 1.8
const CONTACT := 2.1
const SPRAY_END := 2.65
const BADGE_START := 2.13
const BADGE_END := 2.43
const DISSOLVE_START := 2.15
const DISSOLVE_END := 2.7
const RECOVERY_START := 2.65
const RETURN_START := 3.05
const RETURN_END := 4.15
const ATTACK_PEAK := 0.433  ## clipe 11 do Orc: mão mais à frente (medido no GLB)
const ATTACK_START := CONTACT - ATTACK_PEAK
const ENEMY_SCALE := 2.16

var camera: Camera3D
var arena: Node3D
var attacker := {}
var target := {}
var vfx: DrainSpearVfx
var hud: DrainSpearHud
var ui: Control
var panel: PanelContainer
var _time := 0.0
var _playing := true
var _speed := 1.0
var _capturing := false
var _args := {}
var _shot_path := ""
var _record_dir := ""
var _record_seconds := 0.0
var _record_step := 1.0 / 30.0
var _record_start := 0.0
var _quit_after := false
var _clean := false
var _hide_panel := false

# --- Configuração do laboratório (cenários A–H + parâmetros do protótipo tipo) ---
var scenario := "A"
var pov_mode := "normal"  ## "normal" (CINEMA) ou "other" (mesmos papéis, câmera do outro lado)
var mirrored := false  ## compatibilidade: agora é o mesmo que pov_mode = "other" (D-378)
var start_mode := "far"
var reach_mode := "impale"  ## D-378: só a lança que cresce e impala; sem feixe/projétil
var outcome := "hit"
var retreat_duration := 1.2
var show_rings := false
var game_scales := true
var particle_quality := "high"
var anchor_mode := "auto"
var attacker_id := "dqt_orc"
var target_id := "dqt_slime"
var mag := 10
var spi := 3
var badges := {"atk_up": false, "shield": false, "mag_immune": false, "def_down": true}
var camera_mode := "cinema"
var battle_mode := false  ## D-378 1A: visual-only na batalha real (battle.tscn), sem implementar o Move
var _battle_scene: Node3D = null

# --- Geometria do cenário ---
var _target_home := FAR
var _attacker_home := NEAR
var _target_start := FAR
var _attacker_goal := NEAR
var _to_attacker := Vector3.BACK
var _initial_dist := MID_CENTER
var _requires_move := false
var _is_retreat := false
var _is_approach := false
var _contact_locked := Vector3.ZERO
var _contact_dir := Vector3.FORWARD
var _contact_base := Vector3.ZERO
var _contact_axis := Vector3.UP
var _contact_len := SPEAR_LENGTH
var _last_base := Vector3.ZERO
var _last_axis := Vector3.UP
var _last_len := SPEAR_LENGTH
var _last_steal_dist := -1.0
var _vfx_rebuild_t := -10.0
var _last_mirrored := false
var _ui_ready := false
var _labels := {}
var _rings: Array[MeshInstance3D] = []
var _scenario_buttons := {}
var _target_model_option: OptionButton
var _attacker_model_option: OptionButton
var _start_option: OptionButton
var _reach_option: OptionButton
var _outcome_option: OptionButton
var _quality_option: OptionButton
var _mirror_check: CheckBox
var _rings_check: CheckBox
var _scale_check: CheckBox
var _anchor_option: OptionButton
var _mag_slider: HSlider
var _spi_slider: HSlider
var _badge_checks := {}
var _play_button: Button
var _timeline: HSlider
var _speed_option: OptionButton
var _phase_label: Label
var _dist_label: Label
var _time_label: Label
var _log_label: Label
var _dbg_done := false
var _dbg_line: MeshInstance3D
var _orbit_active := false
var _orbit_yaw := 0.0
var _orbit_pitch := -0.25
var _orbit_dist := 14.0


func _ready() -> void:
	_parse_args()
	_apply_args()
	if scenario == "H":
		target_id = "dqt_cyclops"
	if battle_mode:
		await _setup_battle_scene()
	else:
		add_child(BattleArena.new())
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera.position = CINEMA_POS
		camera.fov = FOV
		add_child(camera)
		_set_pov(pov_mode)
	vfx = DrainSpearVfx.new()
	vfx.name = "DrainSpearVfx"
	add_child(vfx)
	vfx.setup(camera, 20261106)
	_build_rings()
	if battle_mode:
		await _bind_battle_fighters()
	else:
		_spawn_fighters()
	_last_mirrored = mirrored
	_build_ui()
	if _args.has("debug"):
		_dbg_line = MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.04
		cm.bottom_radius = 0.04
		cm.height = 1.0
		cm.radial_segments = 6
		_dbg_line.mesh = cm
		var dm := StandardMaterial3D.new()
		dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dm.albedo_color = Color(1, 0.1, 0.1)
		_dbg_line.material_override = dm
		add_child(_dbg_line)
	_apply_scenario()
	_set_play(true)
	_ui_ready = true
	if camera_mode == "free":
		_toggle_camera()
	if _shot_path != "":
		await _run_shot()
	elif _record_seconds > 0.0:
		await _run_record()
	elif _quit_after:
		quit_lab()


func _process(delta: float) -> void:
	if _capturing:
		return
	if _playing:
		_time = minf(_time + delta * _speed, TOTAL)
		if _time >= TOTAL:
			_playing = false
			if _play_button != null:
				_play_button.text = "Play"
	_update_lab()


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := String(raw)
		if not a.begins_with("--"):
			continue
		a = a.substr(2)
		var eq := a.find("=")
		if eq >= 0:
			_args[a.substr(0, eq)] = a.substr(eq + 1)
		else:
			_args[a] = "true"


func _apply_args() -> void:
	scenario = String(_args.get("scenario", scenario)).to_upper()
	pov_mode = String(_args.get("pov", pov_mode)).to_lower()
	mirrored = _as_bool(_args.get("mirror", false)) or pov_mode == "other" or scenario == "G"
	if mirrored:
		pov_mode = "other"
	start_mode = String(_args.get("dist", start_mode))
	reach_mode = "impale"  # D-378: só a lança que cresce e impala; o feixe/projétil foi removido
	battle_mode = _as_bool(_args.get("realbattle", false))
	outcome = String(_args.get("outcome", outcome))
	retreat_duration = float(_args.get("retreat", retreat_duration))
	particle_quality = String(_args.get("quality", particle_quality))
	anchor_mode = String(_args.get("anchor", anchor_mode))
	attacker_id = String(_args.get("attacker", attacker_id))
	target_id = String(_args.get("target", target_id))
	camera_mode = String(_args.get("camera", camera_mode))
	game_scales = _as_bool(_args.get("game_scales", true))
	show_rings = _as_bool(_args.get("rings", false))
	_time = float(_args.get("time", 0.0))
	_speed = float(_args.get("speed", 1.0))
	_shot_path = String(_args.get("shot", ""))
	_record_seconds = float(_args.get("record", 0.0))
	_record_step = float(_args.get("step", 1.0 / 30.0))
	_record_start = float(_args.get("start", 0.0))
	_record_dir = String(_args.get("out", "res://test_captures/drain_spear_lab"))
	_quit_after = _as_bool(_args.get("quit", false))
	_clean = _as_bool(_args.get("clean", false))
	_hide_panel = _as_bool(_args.get("nopanel", false))


func _as_bool(v: Variant) -> bool:
	if v is bool:
		return v
	var s := str(v).to_lower()
	return s == "1" or s == "true" or s == "yes" or s == "on"


## D-378 1A: usa a cena de batalha real como palco visual-only. Não implementa o Move, não altera regra de combate:
## congela a batalha, esconde a UI do jogo e reaproveita os modelos, o AnimationPlayer, a respiração e a câmera reais.
func _setup_battle_scene() -> void:
	DqtTestParty.enabled = true
	var ps := load("res://scenes/battle.tscn") as PackedScene
	_battle_scene = ps.instantiate() as Node3D
	add_child(_battle_scene)
	var b := _battle_scene.get_node("Battle") as Battle
	while not b.running:
		await get_tree().process_frame
	for i in 8:
		await get_tree().process_frame
	b.process_mode = Node.PROCESS_MODE_DISABLED
	_battle_scene.set_process_unhandled_input(false)
	for child in _battle_scene.get_children():
		if child is CanvasLayer:
			var cl := child as CanvasLayer
			cl.visible = false
			cl.process_mode = Node.PROCESS_MODE_DISABLED
		elif String(child.name).to_lower().contains("debug"):
			child.process_mode = Node.PROCESS_MODE_DISABLED
	var director: Node = _battle_scene.get("director")
	if director != null:
		director.set_process(false)
		director.set_process_unhandled_input(false)
	camera = _battle_scene.get_node("Camera3D") as Camera3D
	camera.current = true
	_set_pov(pov_mode)


func _bind_battle_fighters() -> void:
	var b := _battle_scene.get_node("Battle") as Battle
	var orc_c: Combatant = null
	var slime_c: Combatant = null
	for c in b.party + b.enemies:
		if c.species_id == "dqt_orc" and orc_c == null:
			orc_c = c
		if c.species_id == "dqt_slime" and slime_c == null:
			slime_c = c
	var model_map: Dictionary = _battle_scene.get("models") if _battle_scene != null else {}
	if orc_c == null or slime_c == null or not model_map.has(orc_c) or not model_map.has(slime_c):
		push_error("DrainSpearLab: a batalha real não tem Orc/Slime; usando o palco do laboratório")
		attacker = _spawn_fighter(attacker_id, true, NEAR, PI)
		target = _spawn_fighter(target_id, false, FAR, 0.0)
		return
	var orc_root := model_map[orc_c] as Node3D
	var slime_root := model_map[slime_c] as Node3D
	# Só Orc e Slime no palco visual; os outros membros do roster de teste somem.
	for c in b.party + b.enemies:
		if c != orc_c and c != slime_c and model_map.has(c):
			(model_map[c] as Node3D).visible = false
	# Sombras/aneis de seleção do palco de batalha não fazem parte do efeito.
	for n in _battle_scene.find_children("ReadyRing", "", true, false):
		(n as Node3D).visible = false
	for n in _battle_scene.find_children("BurstRing", "", true, false):
		(n as Node3D).visible = false
	# O BattleFx reposiciona os modelos pelo slot da batalha a cada quadro; no palco visual quem manda é a timeline.
	var fx: Node = _battle_scene.get("fx")
	if fx != null:
		fx.set_process(false)
	for root in [orc_root, slime_root]:
		for n in (root as Node3D).find_children("ReadyRing", "", true, false):
			(n as Node3D).visible = false
		for n in (root as Node3D).find_children("BurstRing", "", true, false):
			(n as Node3D).visible = false
	# O alvo é um inimigo visual (escala de leitura do jogo), mesmo estando no lado do jogador no roster de teste.
	slime_root.scale = Vector3.ONE * ENEMY_SCALE
	orc_root.position = NEAR
	orc_root.rotation.y = PI
	slime_root.position = FAR
	slime_root.rotation.y = 0.0
	await get_tree().process_frame
	attacker = _battle_fighter(orc_root, "dqt_orc", true, NEAR, PI)
	target = _battle_fighter(slime_root, "dqt_slime", false, FAR, 0.0)


func _battle_fighter(root: Node3D, model_id: String, _is_ally: bool, pos: Vector3, yaw: float) -> Dictionary:
	var profile := DqtModelProfiles.get_profile(model_id)
	if profile.is_empty():
		profile = {"native_height": 2.0, "target_height": 2.0, "rotation_y": 180.0, "weapon_kind": "none"}
	var ap: AnimationPlayer = root.get_meta("anim_player") if root.has_meta("anim_player") else null
	var breath := root.get_node_or_null("DqtIdleBreath") as Node3D
	var inst: Node3D = root
	if breath != null and breath.get_child_count() > 0:
		inst = breath.get_child(0) as Node3D
	root.position = pos
	root.rotation.y = yaw
	root.force_update_transform()
	var box := _body_box(root)
	var height := box.size.y
	var radius := minf(minf(box.size.x, box.size.z) * 0.5, maxf(height * 0.35, 0.4))
	if breath != null:
		breath.set_meta("height", height)
	DqtModelProfiles.start_idle_breath(root)
	return {"id": model_id, "root": root, "inst": inst, "ap": ap, "profile": profile,
		"height": height, "radius": radius, "home": pos, "box": box}


func _spawn_fighters() -> void:
	attacker = _spawn_fighter(attacker_id, true, NEAR, PI)
	target = _spawn_fighter(target_id, false, FAR, 0.0)
	# O alvo é sempre o oposto do atacante no lado do campo; a posição real é resolvida no cenário.
	target.root.position = FAR
	target["home"] = FAR
	attacker.root.position = NEAR
	attacker["home"] = NEAR


func _spawn_fighter(model_id: String, is_ally: bool, pos: Vector3, yaw: float) -> Dictionary:
	var profile := DqtModelProfiles.get_profile(model_id)
	if profile.is_empty():
		profile = {"native_height": 2.0, "target_height": 2.0, "rotation_y": 180.0, "weapon_kind": "none"}
	var root := Node3D.new()
	root.name = model_id.capitalize()
	var path := "res://assets/modelos/%s/%s.glb" % [model_id, model_id]
	var ps: PackedScene = load(path) if ResourceLoader.exists(path) else null
	var inst: Node3D
	var ap: AnimationPlayer = null
	if ps != null:
		inst = ps.instantiate() as Node3D
		inst.rotation_degrees = Vector3(0, float(profile.get("rotation_y", 180.0)), 0)
		var base_scale := float(profile.get("target_height", 2.0)) / maxf(float(profile.get("native_height", 2.0)), 0.001)
		var extra := 1.0
		if game_scales:
			extra = float(profile.get("ally_scale", 1.0)) if is_ally else ENEMY_SCALE
		inst.scale = Vector3.ONE * base_scale * extra
		var breath := Node3D.new()
		breath.name = "DqtIdleBreath"
		breath.set_meta("height", float(profile.get("target_height", 2.0)) * extra)
		root.add_child(breath)
		breath.add_child(inst)
		VfxLib.outline_model(inst, 0.0035)
		ap = _find_anim_player(inst)
		if ap != null:
			DqtModelProfiles.apply_anim_aliases(ap, profile)
			DqtModelProfiles.setup_weapon_follow(inst, ap, profile)
			DqtEyes.attach(root, inst, ap, str(profile.get("clip_prefix", "")) + "04")
			_strip_root_motion(ap)
			root.set_meta("anim_player", ap)
		# D-378 0D: a respiração do jogo fica ligada também nas capturas (idle vivo, como na batalha).
		DqtModelProfiles.start_idle_breath(root)
	else:
		inst = Node3D.new()
		var mi := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.5
		capsule.height = 2.0
		mi.mesh = capsule
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.6, 0.6)
		mi.material_override = mat
		root.add_child(mi)
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	var box := _body_box(root)
	var height := box.size.y
	var radius := minf(minf(box.size.x, box.size.z) * 0.5, maxf(height * 0.35, 0.4))
	return {"id": model_id, "root": root, "inst": inst, "ap": ap, "profile": profile,
		"height": height, "radius": radius, "home": pos, "box": box}


func _body_box(root: Node) -> AABB:
	var box := AABB()
	var first := true
	var all := AABB()
	var all_first := true
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null or String(mi.name).begins_with("BurstRing"):
			continue
		var b := mi.global_transform * mi.get_aabb()
		all = b if all_first else all.merge(b)
		all_first = false
		var n := String(mi.name).to_lower()
		if n.contains("buki") or n.contains("spear") or n.contains("weapon") or n.contains("sword") or n.contains("club"):
			continue
		box = b if first else box.merge(b)
		first = false
	if first:
		return all
	return box


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_anim_player(child)
		if found != null:
			return found
	return null


func _strip_root_motion(ap: AnimationPlayer) -> void:
	for anim_name in ap.get_animation_list():
		var anim := ap.get_animation(anim_name)
		for i in anim.get_track_count():
			if anim.track_get_type(i) != Animation.TYPE_POSITION_3D:
				continue
			var track_path := str(anim.track_get_path(i))
			if not (track_path.ends_with(":origin") or track_path.ends_with(":n_hara")):
				continue
			var first: Vector3 = anim.track_get_key_value(i, 0)
			for k in anim.track_get_key_count(i):
				var v: Vector3 = anim.track_get_key_value(i, k)
				anim.track_set_key_value(i, k, Vector3(first.x, v.y, first.z))


func _apply_scenario() -> void:
	if attacker.is_empty() or target.is_empty():
		return
	# Presets A–H (o painel pode mudar cada parâmetro depois).
	var want_mirror := false
	var want_mode := "far"
	var want_outcome := "hit"
	var want_pov := "normal"
	var want_badges := {"atk_up": false, "shield": false, "mag_immune": false, "def_down": true}
	var want_target := target_id
	match scenario:
		"A":
			pass
		"B":
			want_badges = {"atk_up": true, "shield": true, "mag_immune": false, "def_down": true}
		"C":
			want_badges = {"atk_up": false, "shield": false, "mag_immune": true, "def_down": true}
		"D":
			want_outcome = "evade"
		"E":
			want_mode = "close"
		"F":
			want_mode = "target_approaching"
		"G":
			want_pov = "other"
		"H":
			want_target = "dqt_cyclops"
	if battle_mode:
		want_target = "dqt_slime"  # o palco real tem Orc e Slime; o Cyclops fica no laboratório isolado
	badges = want_badges
	outcome = want_outcome
	start_mode = want_mode
	pov_mode = want_pov if not _args.has("pov") and not _args.has("mirror") else pov_mode
	mirrored = pov_mode == "other"
	if _args.has("outcome"):
		outcome = String(_args["outcome"])
	if want_target != target_id:
		target_id = want_target
		_respawn_target()
	_apply_distance_only()
	_set_pov(pov_mode)
	_refresh_geometry()
	_sync_ui_from_state()


func _refresh_geometry() -> void:
	_contact_locked = _compute_contact_at(CONTACT)
	var cd := _contact_locked - _attacker_center_at(CONTACT)
	_contact_dir = Vector3(cd.x, 0.0, cd.z).normalized()
	_contact_base = _contact_locked
	_contact_axis = _contact_dir
	_contact_len = SPEAR_LENGTH
	_last_base = _contact_base
	_last_axis = _contact_axis
	_last_len = _contact_len
	_last_steal_dist = -1.0


func _apply_distance_only() -> void:
	var target_home := FAR
	var attacker_side := NEAR
	var to_attacker := (attacker_side - target_home).normalized()
	var dist := MID_CENTER
	match start_mode:
		"far": dist = 22.5
		"in_range": dist = MID_CENTER
		"close": dist = 8.5
		"melee_ref": dist = MELEE_REF
		"target_approaching": dist = MID_CENTER
	_target_home = target_home
	_attacker_home = target_home + to_attacker * dist
	_to_attacker = to_attacker
	_target_start = target_home
	_is_approach = start_mode == "target_approaching"
	if _is_approach:
		_target_start = target_home + (target_home - _attacker_home).normalized() * 6.7
	_attacker_goal = target_home + to_attacker * MID_CENTER
	_initial_dist = _attacker_home.distance_to(_target_home)
	_requires_move = absf(_initial_dist - MID_CENTER) > 0.15 and not _is_approach
	_is_retreat = _initial_dist < MID_MIN
	target["home"] = _target_home
	attacker["home"] = _attacker_home
	target.root.position = _target_start
	attacker.root.position = _attacker_home
	_update_rings()


func _respawn_all() -> void:
	if not attacker.is_empty():
		attacker.root.queue_free()
	if not target.is_empty():
		target.root.queue_free()
	attacker = _spawn_fighter(attacker_id, true, NEAR, PI)
	target = _spawn_fighter(target_id, false, FAR, 0.0)
	attacker.root.position = NEAR
	target.root.position = FAR
	attacker["home"] = NEAR
	target["home"] = FAR


func _sync_ui_from_state() -> void:
	if not _ui_ready:
		return
	if _start_option != null:
		var idx := ["far", "in_range", "close", "melee_ref", "target_approaching"].find(start_mode)
		if idx >= 0:
			_start_option.select(idx)
	if _outcome_option != null:
		var oi := ["hit", "evade", "interrupt"].find(outcome)
		if oi >= 0:
			_outcome_option.select(oi)
	if _mirror_check != null:
		_mirror_check.set_pressed_no_signal(pov_mode == "other")
	if _rings_check != null:
		_rings_check.set_pressed_no_signal(show_rings)
	if _scale_check != null:
		_scale_check.set_pressed_no_signal(game_scales)
	if _anchor_option != null:
		var ai := ["auto", "body"].find(anchor_mode)
		if ai >= 0:
			_anchor_option.select(ai)
	if _attacker_model_option != null:
		var ami := ["dqt_orc", "dqt_cyclops", "dqt_slime"].find(attacker_id)
		if ami >= 0:
			_attacker_model_option.select(ami)
	if _target_model_option != null:
		var tmi := ["dqt_cyclops", "dqt_slime", "dqt_orc"].find(target_id)
		if tmi >= 0:
			_target_model_option.select(tmi)
	for k in _badge_checks:
		(_badge_checks[k] as CheckBox).set_pressed_no_signal(bool(badges.get(k, false)))
	for c in _scenario_buttons:
		(_scenario_buttons[c] as Button).set_pressed_no_signal(c == scenario)


func _respawn_target() -> void:
	if not target.is_empty():
		target.root.queue_free()
	target = _spawn_fighter(target_id, false, _target_home, 0.0)
	target.root.position = _target_home
	target["home"] = _target_home


func _attacker_center_at(t: float) -> Vector3:
	return _attacker_root_at(t) + Vector3(0, float(attacker.height) * 0.5, 0)


func _target_center_at(t: float) -> Vector3:
	return _target_root_at(t) + Vector3(0, float(target.height) * 0.5, 0)


func _attacker_root_at(t: float) -> Vector3:
	var home: Vector3 = attacker["home"]
	if not _requires_move:
		return home
	var end_t := MOVE_END
	if _is_retreat:
		end_t = minf(MOVE_START + retreat_duration, MOVE_END)
	var p := clampf((t - MOVE_START) / maxf(end_t - MOVE_START, 0.01), 0.0, 1.0)
	var e := p * p * (3.0 - 2.0 * p)
	var goal: Vector3 = _attacker_goal
	var pos := home.lerp(goal, e)
	if t > RETURN_START:
		var r := clampf((t - RETURN_START) / maxf(RETURN_END - RETURN_START, 0.01), 0.0, 1.0)
		var re := r * r * (3.0 - 2.0 * r)
		pos = goal.lerp(home, re)
	return pos


func _target_root_at(t: float) -> Vector3:
	var home: Vector3 = target["home"]
	if _is_approach:
		var p := clampf((t - MOVE_START) / maxf(MOVE_END - MOVE_START, 0.01), 0.0, 1.0)
		var e := p * p * (3.0 - 2.0 * p)
		return _target_start.lerp(home, e)
	if outcome == "evade":
		var dodge := _ramp(t, CONTACT - 0.15, CONTACT + 0.05) * (1.0 - _ramp(t, CONTACT + 0.15, RECOVERY_START))
		var side := Vector3(_contact_dir.z, 0.0, -_contact_dir.x)
		return home + side * 3.2 * dodge + _contact_dir * 0.8 * dodge
	if outcome == "hit" and t >= CONTACT:
		var recoil := _ramp(t, CONTACT, CONTACT + 0.06) * (1.0 - _ramp(t, CONTACT + 0.08, CONTACT + 0.28))
		return home - _contact_dir * 0.35 * recoil
	return home


func _ramp(t: float, a: float, b: float) -> float:
	return clampf((t - a) / maxf(b - a, 0.0001), 0.0, 1.0)


func _compute_contact_at(t: float) -> Vector3:
	var tr := _target_root_at(t)
	var ar := _attacker_root_at(t)
	var tc := tr + Vector3(0, float(target.height) * 0.5, 0)
	var ac := ar + Vector3(0, float(attacker.height) * 0.5, 0)
	var d := Vector3(tc.x - ac.x, 0.0, tc.z - ac.z).normalized()
	var contact := tr + Vector3(0, float(target.height) * 0.47, 0) - d * (float(target.radius) * 0.46)
	return contact


## D-378: a lança mágica nasce no chão e sobe para a MÃO. Esta é a âncora da mão (punho), não a ponta da lança
## física. Se o modelo não tiver lança, cai no corpo. Dado do modelo, nunca nome/time/lado (D-235/D-377).
func _hand_anchor() -> Vector3:
	if anchor_mode == "body" or String(attacker.profile.get("weapon_kind", "none")) != "spear":
		return _body_anchor()
	var sk := _skeleton_of(attacker.inst)
	if sk == null:
		return _body_anchor()
	var wf: Dictionary = attacker.profile.get("weapon_follow", {})
	var hand_name := str(wf.get("hand", ""))
	if hand_name != "":
		var hb := sk.find_bone(hand_name)
		if hb >= 0:
			return sk.global_transform * sk.get_bone_global_pose(hb).origin
	var bone_name := str(wf.get("bone", ""))
	if bone_name == "":
		return _body_anchor()
	var b := sk.find_bone(bone_name)
	if b < 0:
		return _body_anchor()
	return sk.global_transform * sk.get_bone_global_pose(b).origin


## Ponteiro da lança física (referência de depuração; a lança mágica usa a mão).
func _weapon_anchor() -> Vector3:
	return _hand_anchor() + _weapon_axis() * float(attacker.profile.get("weapon_reach", 1.6))


func _weapon_axis() -> Vector3:
	var sk := _skeleton_of(attacker.inst)
	if sk == null:
		return Vector3.UP
	var wf: Dictionary = attacker.profile.get("weapon_follow", {})
	var bone_name := str(wf.get("bone", ""))
	var b := sk.find_bone(bone_name)
	if b < 0:
		return Vector3.UP
	var ax := (sk.global_transform.basis * sk.get_bone_global_pose(b).basis.y).normalized()
	ax *= float(attacker.profile.get("weapon_axis_sign", 1))
	if ax.dot(Vector3.UP) < -0.2:
		ax = -ax
	return ax


func _body_anchor() -> Vector3:
	var ac := _attacker_center_at(_time)
	var d := _contact_dir if _contact_dir.length() > 0.01 else Vector3.FORWARD
	var side := Vector3(d.z, 0.0, -d.x)
	return ac + side * (float(attacker.radius) * 0.85) + Vector3(0, -float(attacker.height) * 0.12, 0)


## D-378 1A: ponto no CHÃO, à direita da tela, derivado da câmera e do atacante reais (nunca coordenada fixa).
func _ground_spawn_point() -> Vector3:
	var root := (attacker.root as Node3D).global_position
	var right := camera.global_transform.basis.x
	right.y = 0.0
	right = right.normalized() if right.length() > 0.01 else Vector3.RIGHT
	var p := root + right * maxf(float(attacker.radius) + 0.55, 0.95)
	p.y = 0.0
	return p


func _skeleton_of(node: Node) -> Skeleton3D:
	if node == null:
		return null
	var list := node.find_children("*", "Skeleton3D", true, false)
	return list[0] as Skeleton3D if not list.is_empty() else null


## D-378: geometria da lança única e conectada.
## 0–0,8 s: vertical no ponto verde do chão; 0,8–1,0 s: vira para o alvo e sobe para a mão; 1,0–1,8 s: corre com a mão;
## 1,8–2,1 s: o CABO cresce até impalar; 2,1–2,35 s: dá ré; 2,15–2,7 s: dissolve. Sem projétil, sem feixe.
func _spear_state(t: float) -> Dictionary:
	var has_weapon := String(attacker.profile.get("weapon_kind", "none")) == "spear" and anchor_mode != "body"
	var hand := _hand_anchor()
	var ground := _ground_spawn_point()
	var target_dir := _contact_dir if _contact_dir.length() > 0.01 else Vector3.FORWARD
	var aim := (_contact_locked - hand)
	aim = aim.normalized() if aim.length() > 0.01 else target_dir
	var base := ground
	var axis := Vector3.UP
	var length := SPEAR_LENGTH
	var reveal := clampf(t / FORM_END, 0.0, 1.0)
	var dissolve := 0.0
	# Durante a corrida a lança acompanha a arma física (diagonal legível) e só alinha no alvo para a estocada.
	var carry := (_weapon_axis() * 0.55 + aim * 0.45).normalized()
	# Formação vertical no chão.
	if t < FORM_END:
		base = ground
		axis = Vector3.UP
		length = SPEAR_LENGTH
	# Virada ANTES da corrida: a lança gira e sobe para a mão ao mesmo tempo.
	elif t < TURN_END:
		var u := _ramp(t, FORM_END, TURN_END)
		var e := u * u * (3.0 - 2.0 * u)
		base = ground.lerp(hand, e)
		axis = Vector3.UP.slerp(carry, e).normalized()
		length = SPEAR_LENGTH
	# Corrida com a lança na mão; o alinhamento final acontece durante a corrida.
	else:
		base = hand
		var align := _ramp(t, MOVE_START, MOVE_END - 0.10)
		axis = carry.slerp(aim, align * align * (3.0 - 2.0 * align)).normalized()
		length = SPEAR_LENGTH
	# Cenário F: o alvo se aproxima; a lança espera vertical até a faixa.
	if _is_approach and t < MOVE_END:
		base = hand
		axis = Vector3.UP
		length = SPEAR_LENGTH
	# Estocada: o cabo só cresce no CLÍMAX da animação (últimos 0,10 s antes do contato), não durante o prelude.
	if t >= MOVE_END and t < CONTACT and outcome != "interrupt":
		var u := _ramp(t, CONTACT - 0.10, CONTACT)
		var e := u * u * (3.0 - 2.0 * u)
		var full := hand.distance_to(_contact_locked) + 0.30
		base = hand
		axis = aim
		length = lerpf(SPEAR_LENGTH, full, e)
	elif t >= CONTACT:
		var full := hand.distance_to(_contact_locked) + 0.30
		base = hand
		axis = aim
		if outcome == "hit":
			# Impala (2,1) e puxa de volta 0,85 m até 2,35; depois dissolve no lugar.
			var pull := _ramp(t, CONTACT, CONTACT + 0.25)
			length = full - 0.85 * pull
		else:
			length = full
	if outcome == "interrupt" and t >= 1.65:
		base = hand
		axis = aim if t >= TURN_END else Vector3.UP
		length = SPEAR_LENGTH
	if t >= DISSOLVE_START:
		dissolve = _ramp(t, DISSOLVE_START, DISSOLVE_END)
	var tip := base + axis * length
	return {"base": base, "axis": axis, "length": length, "tip": tip, "has_weapon": has_weapon, "reveal": reveal, "dissolve": dissolve}


func _draw_vfx(t: float, st: Dictionary) -> void:
	if vfx == null:
		return
	var steal_dist := _contact_locked.distance_to(_attacker_center_at(CONTACT))
	if absf(steal_dist - _last_steal_dist) > 0.25:
		vfx.rebuild(steal_dist)
		_last_steal_dist = steal_dist
	vfx.begin(t)
	var base: Vector3 = st["base"]
	var axis: Vector3 = st["axis"]
	var tip: Vector3 = st["tip"]
	# Formação + virada + corrida: a lança nasce no chão e acompanha a mão. Reveal só na formação.
	if t < MOVE_END:
		var reveal := clampf(t / FORM_END, 0.0, 1.0)
		vfx.draw_phase("windup", t, base, tip, tip, axis, reveal, 0.0, false)
	# Estocada: cabo cresce, lâmina fixa; sem feixe. A aura acompanha.
	if t >= MOVE_END and t < CONTACT and outcome != "interrupt":
		var p := clampf((t - MOVE_END) / (CONTACT - MOVE_END), 0.0, 1.0)
		vfx.draw_phase("thrust", t - MOVE_END, base, tip, tip, axis, 1.0, p, false)
	# D-379: boost burst helicoidal no início da estocada (0,6 s; fade após 0,4 s). No Badge Steal ele
	# termina no contato para o vórtice não competir com os orbes que voltam.
	var drill_end := CONTACT if not _stolen_badges().is_empty() else MOVE_END + 0.60
	if t >= MOVE_END and t < drill_end and outcome != "interrupt":
		var dk := clampf((t - MOVE_END) / 0.28, 0.0, 1.0)
		vfx.draw_phase("drill", t - MOVE_END, base, tip, tip, axis, dk, 0.0, false)
	# Impacto: normal (leque para longe) ou Badge Steal (o MESMO leque, virado para o atacante).
	var after := t - CONTACT
	var impact_scale := clampf(camera.global_position.distance_to(_contact_locked) / 16.0, 1.0, 1.8)
	if after >= 0.0 and after <= 0.80 and outcome == "hit":
		var stolen := _stolen_badges()
		if stolen.is_empty():
			vfx.draw_phase("impact_flash", after, _contact_locked, _contact_locked + _contact_dir * 0.1, _contact_locked, _contact_dir, clampf(after / 0.55, 0.0, 1.0), 0.0, false, impact_scale)
			vfx.draw_phase("impact", after, _contact_locked, _contact_locked + _contact_dir * 10.0, _contact_locked, _contact_dir, clampf(after / 0.55, 0.0, 1.0), 0.0, false, impact_scale)
		else:
			var attacker_center := _attacker_center_at(CONTACT)
			var steal_axis := (attacker_center - _contact_locked).normalized()
			# Igual ao HTML: flash no contato + streaks/orbes reversos + órbita no atacante.
			vfx.draw_phase("impact_flash", after, _contact_locked, _contact_locked + _contact_dir * 0.1, _contact_locked, _contact_dir, clampf(after / 0.55, 0.0, 1.0), 0.0, false, impact_scale)
			# O HTML roda o retorno de 2,15 s a 2,84 s (0,69 s). CONTACT = 2,10.
			var steal_t := t - 2.15
			if steal_t >= 0.0 and steal_t < 0.69:
				vfx.draw_phase("steal", steal_t, _contact_locked, attacker_center, _contact_locked, steal_axis, clampf(steal_t / 0.69, 0.0, 1.0), 0.0, false, impact_scale)
	# A lança continua cravada, dá ré e dissolve lentamente em partículas.
	if t >= CONTACT and t < DISSOLVE_END:
		var dk := clampf((t - DISSOLVE_START) / maxf(DISSOLVE_END - DISSOLVE_START, 0.01), 0.0, 1.0)
		vfx.draw_phase("dissolve", t - CONTACT, base, tip, tip, axis, dk, 0.0, false)
	vfx.end()


func _stolen_badges() -> Array:
	var out: Array = []
	if outcome != "hit":
		return out
	for k in ["atk_up", "shield", "mag_immune"]:
		if bool(badges.get(k, false)):
			out.append(k)
	return out


func _update_lab() -> void:
	if attacker.is_empty() or target.is_empty():
		return
	# Posições.
	var ar := _attacker_root_at(_time)
	var tr := _target_root_at(_time)
	attacker.root.position = ar
	target.root.position = tr
	# Animações determinísticas.
	_animate(attacker, _time, true)
	_animate(target, _time, false)
	# Geometria do contato travada no golpe.
	_contact_locked = _compute_contact_at(CONTACT)
	var cd := _contact_locked - _attacker_center_at(CONTACT)
	_contact_dir = Vector3(cd.x, 0.0, cd.z).normalized()
	if _time >= MOVE_END:
		var st0 := _spear_state(_time)
		_last_base = st0["base"]
		_last_axis = st0["axis"]
		_last_len = st0["length"]
	# VFX.
	var st := _spear_state(_time)
	if _dbg_line != null:
		var b: Vector3 = st["base"]
		var tip: Vector3 = st["tip"]
		var axv := tip - b
		var ln := axv.length()
		if ln > 0.01:
			var q := Quaternion(Vector3.UP, axv.normalized())
			_dbg_line.transform = Transform3D(Basis(q) * Basis.from_scale(Vector3(1.0, ln, 1.0)), b + axv * 0.5)
			_dbg_line.visible = true
		else:
			_dbg_line.visible = false
	if _args.has("debug") and not _dbg_done and absf(_time - float(_args.get("dbgtime", 1.70))) <= 0.03:
		_dbg_done = true
		print("DBG t=", _time, " reach=", reach_mode, " base=", st["base"], " axis=", st["axis"], " len=", st["length"], " tip=", st["tip"], " contact=", _contact_locked, " dir=", _contact_dir, " anchor=", _weapon_anchor(), " phys=", _weapon_axis(), " has=", st["has_weapon"], " anim=", attacker.get("ap").current_animation if attacker.get("ap") != null else "?", "/", target.get("ap").current_animation if target.get("ap") != null else "?", " screen=", camera.unproject_position(st["base"]), "->", camera.unproject_position(st["tip"]))
	_draw_vfx(_time, st)
	_update_rings()
	_update_hud(st)
	_update_controls()


func _animate(f: Dictionary, t: float, is_attacker: bool) -> void:
	var ap: AnimationPlayer = f.get("ap")
	if ap == null:
		return
	var anim := "battle_idle"
	var at := 0.0
	if is_attacker:
		if outcome == "interrupt":
			anim = "battle_idle"
		elif t < MOVE_START:
			anim = "battle_idle"
		elif t < ATTACK_START:
			anim = "walk"
			if ap.has_animation("walk"):
				at = fmod((t - MOVE_START) / 0.5333, 1.0) * ap.get_animation("walk").length
		elif t < ATTACK_START + (ap.get_animation("attack").length if ap.has_animation("attack") else 1.7333):
			anim = "attack"
			if ap.has_animation("attack"):
				# O clipe 11 toca inteiro, como no jogo; a mão mais à frente (0,433 s) cai no contato (2,1 s).
				at = clampf(t - ATTACK_START, 0.0, ap.get_animation("attack").length)
		else:
			anim = "battle_idle"
	else:
		if t >= CONTACT and outcome == "hit":
			anim = "damage"
			if ap.has_animation("damage"):
				at = clampf(t - CONTACT, 0.0, ap.get_animation("damage").length)
		elif t < CONTACT and _is_approach:
			anim = "walk"
			if ap.has_animation("walk"):
				at = fmod((t - MOVE_START) / 0.5333, 1.0) * ap.get_animation("walk").length
		else:
			anim = "battle_idle"
	if not ap.has_animation(anim):
		return
	ap.speed_scale = 1.0
	if ap.current_animation != anim:
		ap.play(anim, 0.0)
	ap.seek(at, true)


func _update_controls() -> void:
	if not _ui_ready:
		return
	if _play_button != null:
		_play_button.text = "Pause" if _playing else "Play"
	if _timeline != null and not _timeline.has_focus():
		_timeline.set_value_no_signal(_time)
	if _time_label != null:
		_time_label.text = "%.2f / %.2f s" % [_time, TOTAL]


func _update_hud(st: Dictionary) -> void:
	if hud == null:
		return
	var phase := _phase_name(_time)
	var hint := _phase_hint(_time)
	var dist := _attacker_center_at(_time).distance_to(_target_center_at(_time))
	hud.set_state({
		"time": _time, "total": TOTAL, "phase": phase, "hint": hint, "distance": dist,
		"attacker": attacker, "target": target, "camera": camera,
		"badges": badges, "stolen": _stolen_badges(), "outcome": outcome,
		"mag": mag, "spi": spi, "reach": "impala", "quality": particle_quality,
		"mirrored": pov_mode == "other", "pov": pov_mode,
	})


func _phase_name(t: float) -> String:
	if outcome == "interrupt" and t >= 1.65:
		return "INTERRUPÇÃO"
	if t < FORM_END:
		return "FORMAÇÃO"
	if t < TURN_END:
		return "VIRADA"
	if t < MOVE_END:
		return "DESLOCAMENTO"
	if t < CONTACT:
		return "ESTOCADA"
	if t < SPRAY_END:
		return "BADGE STEAL" if not _stolen_badges().is_empty() else "IMPACTO"
	if t < DISSOLVE_END:
		return "DISSOLUÇÃO"
	return "RECOVERY"


func _phase_hint(t: float) -> String:
	if outcome == "interrupt" and t >= 1.65:
		return "A estocada foi cancelada"
	if t < FORM_END:
		return "A lança nasce no chão, à direita da tela"
	if t < TURN_END:
		return "Vira para o alvo e sobe para a mão, antes de correr"
	if t < MOVE_END:
		if _is_approach:
			return "Lança vertical; o alvo se aproxima"
		return "Recuo para a faixa" if _is_retreat else "Aproximação até a faixa mid-range"
	if t < CONTACT:
		return "O cabo cresce; a lâmina fixa busca o contato"
	if t < SPRAY_END:
		return "Retorno reverso: streaks + orbs + coroa" if not _stolen_badges().is_empty() else "Spray em leque a partir do contato"
	if t < DISSOLVE_END:
		return "A lança dá ré e some lentamente em partículas"
	return "Retorno à formação"


func _build_rings() -> void:
	for spec in [[MID_MIN, Color("62d8e7")], [MID_CENTER, Color("d7fd6a")], [MID_MAX, Color("62d8e7")], [MELEE_REF, Color("ff624f")]]:
		var r: float = spec[0]
		var mi := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = r - 0.035
		torus.outer_radius = r + 0.035
		torus.rings = 96
		torus.ring_segments = 3
		mi.mesh = torus
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(spec[1], 0.65)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = mat
		mi.position = Vector3(0, 0.025, 0)
		mi.visible = false
		add_child(mi)
		_rings.append(mi)


func _update_rings() -> void:
	for mi in _rings:
		mi.visible = show_rings
		if show_rings:
			var p := _target_center_at(_time)
			mi.position = Vector3(p.x, 0.025, p.z)


func _set_play(v: bool) -> void:
	_playing = v
	if v and _time >= TOTAL:
		_time = 0.0


func _mirror_point(p: Vector3, plane_point: Vector3, normal: Vector3) -> Vector3:
	return p - 2.0 * (p - plane_point).dot(normal) * normal


## D-378 2A: "espelhado" = POV do OUTRO lado, mesmos papéis. A câmera é o espelho da CINEMA no plano que passa
## pelo ponto médio e é perpendicular ao eixo atacante→alvo. FOV 80° e Dutch 4° continuam.
func _set_pov(pov: String) -> void:
	pov_mode = pov
	camera_mode = "cinema"
	_set_pov_transform()


func _set_pov_transform() -> void:
	if camera == null:
		return
	var pos := CINEMA_POS
	var look := CINEMA_LOOK
	if pov_mode == "other":
		var plane_point := (NEAR + FAR) * 0.5
		var normal := (FAR - NEAR).normalized()
		pos = _mirror_point(CINEMA_POS, plane_point, normal)
		look = _mirror_point(CINEMA_LOOK, plane_point, normal)
		# O espelho cai atrás do alvo e o corpo dele tapa o quadro. Afasta a câmera
		# do ponto médio e olha para o meio dos dois lutadores.
		var mid := plane_point
		var away := (pos - mid).normalized()
		pos = mid + away * 20.0
		look = mid + Vector3(0, 1.0, 0)
	camera.position = pos
	camera.fov = FOV
	camera.look_at_from_position(pos, look)
	camera.rotate_object_local(Vector3.BACK, deg_to_rad(TILT_DEG))
	camera.current = true


func _set_cinema() -> void:
	camera_mode = "cinema"
	_set_pov_transform()


func _toggle_camera() -> void:
	if camera_mode == "cinema":
		camera_mode = "free"
		var focus := _attacker_center_at(_time).lerp(_target_center_at(_time), 0.5)
		var dir := (camera.global_position - focus).normalized()
		_orbit_yaw = atan2(dir.x, dir.z)
		_orbit_pitch = asin(clampf(dir.y, -1.0, 1.0))
		_orbit_dist = 14.0
		_apply_orbit()
	else:
		_set_cinema()


func _apply_orbit() -> void:
	if camera_mode != "free":
		return
	var focus := _attacker_center_at(_time).lerp(_target_center_at(_time), 0.5)
	var dir := Vector3(cos(_orbit_pitch) * sin(_orbit_yaw), sin(_orbit_pitch), cos(_orbit_pitch) * cos(_orbit_yaw))
	camera.position = focus + dir * _orbit_dist
	camera.look_at(focus)


func _unhandled_input(event: InputEvent) -> void:
	if camera_mode != "free":
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			_orbit_active = mb.pressed
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_dist = clampf(_orbit_dist * 0.90, 4.0, 32.0)
			_apply_orbit()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_dist = clampf(_orbit_dist * 1.10, 4.0, 32.0)
			_apply_orbit()
	elif event is InputEventMouseMotion and _orbit_active:
		var mm := event as InputEventMouseMotion
		_orbit_yaw -= mm.relative.x * 0.006
		_orbit_pitch = clampf(_orbit_pitch - mm.relative.y * 0.006, -1.25, 1.25)
		_apply_orbit()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	hud = DrainSpearHud.new()
	ui.add_child(hud)
	hud.visible = not _clean
	# Painel lateral discreto (à direita; o log fica acima dele).
	panel = PanelContainer.new()
	panel.position = Vector2(924, 132)
	panel.custom_minimum_size = Vector2(340, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.visible = not _clean and not _hide_panel
	ui.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 558)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	scroll.add_child(box)
	var title := Label.new()
	title.text = "DRAIN SPEAR / LAB"
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "move_drain_spear · 2 ATB + 12 MP · Normal · mid-range"
	sub.add_theme_font_size_override("font_size", 11)
	box.add_child(sub)
	# Cenários A–H.
	var scen_row := HBoxContainer.new()
	box.add_child(scen_row)
	for code in ["A", "B", "C", "D", "E", "F", "G", "H"]:
		var b := Button.new()
		b.text = code
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(32, 28)
		b.pressed.connect(func() -> void: _set_scenario(code))
		scen_row.add_child(b)
		_scenario_buttons[code] = b
	# Distância.
	_start_option = _option(box, "Distância inicial", ["Distante 22,5", "Na faixa 16,3", "Próximo 8,5", "Melee 2,6", "Alvo aproximando"], ["far", "in_range", "close", "melee_ref", "target_approaching"])
	_start_option.item_selected.connect(func(i: int) -> void: start_mode = _start_option.get_item_metadata(i); _apply_distance_only(); _refresh_geometry())
	_reach_option = null  # D-378: sem Hybrid/Elongate/Surge; a lança cresce e impala
	_outcome_option = _option(box, "Resultado", ["Acerto", "Evade", "Interrupção"], ["hit", "evade", "interrupt"])
	_outcome_option.item_selected.connect(func(i: int) -> void: outcome = _outcome_option.get_item_metadata(i))
	_attacker_model_option = _option(box, "Atacante (prova D-235)", ["Orc", "Cyclops", "Slime"], ["dqt_orc", "dqt_cyclops", "dqt_slime"])
	_attacker_model_option.item_selected.connect(func(i: int) -> void: attacker_id = _attacker_model_option.get_item_metadata(i); _respawn_attacker())
	_target_model_option = _option(box, "Alvo", ["Cyclops", "Slime", "Orc"], ["dqt_cyclops", "dqt_slime", "dqt_orc"])
	_target_model_option.item_selected.connect(func(i: int) -> void: target_id = _target_model_option.get_item_metadata(i); _respawn_target(); _apply_distance_only(); _refresh_geometry())
	# Badges.
	var badge_title := Label.new()
	badge_title.text = "Badges do alvo"
	badge_title.add_theme_font_size_override("font_size", 12)
	box.add_child(badge_title)
	var badge_row := HBoxContainer.new()
	box.add_child(badge_row)
	for key in ["atk_up", "shield", "mag_immune", "def_down"]:
		var cb := CheckBox.new()
		cb.text = {"atk_up": "ATK+1", "shield": "SHD", "mag_immune": "IMM", "def_down": "DEF-1"}[key]
		cb.button_pressed = bool(badges.get(key, false))
		cb.toggled.connect(func(on: bool) -> void: badges[key] = on)
		badge_row.add_child(cb)
		_badge_checks[key] = cb
	# MAG/SPI.
	var stats := HBoxContainer.new()
	box.add_child(stats)
	_mag_slider = _slider(stats, "MAG", 5, 25, mag)
	_spi_slider = _slider(stats, "SPI", 0, 10, spi)
	_mag_slider.value_changed.connect(func(v: float) -> void: mag = int(v))
	_spi_slider.value_changed.connect(func(v: float) -> void: spi = int(v))
	# Qualidade/câmera.
	var qrow := HBoxContainer.new()
	box.add_child(qrow)
	_quality_option = _option(qrow, "Qualidade", ["Baixa", "Média", "Alta"], ["low", "med", "high"])
	_quality_option.item_selected.connect(func(i: int) -> void: particle_quality = _quality_option.get_item_metadata(i))
	var cam_btn := Button.new()
	cam_btn.text = "Câmera livre"
	cam_btn.pressed.connect(func() -> void: _toggle_camera())
	qrow.add_child(cam_btn)
	# Checks.
	_mirror_check = CheckBox.new()
	_mirror_check.text = "POV do outro lado (G)"
	_mirror_check.button_pressed = pov_mode == "other"
	_mirror_check.toggled.connect(func(on: bool) -> void: _set_pov("other" if on else "normal"))
	box.add_child(_mirror_check)
	_rings_check = CheckBox.new()
	_rings_check.text = "Anéis mid-range"
	_rings_check.button_pressed = show_rings
	_rings_check.toggled.connect(func(on: bool) -> void: show_rings = on)
	box.add_child(_rings_check)
	_scale_check = CheckBox.new()
	_scale_check.text = "Escalas do jogo"
	_scale_check.button_pressed = game_scales
	_scale_check.toggled.connect(func(on: bool) -> void: game_scales = on; _respawn_all(); _apply_distance_only(); _refresh_geometry())
	box.add_child(_scale_check)
	_anchor_option = _option(box, "Âncora da lança", ["Automática (lança real)", "Corpo"], ["auto", "body"])
	_anchor_option.item_selected.connect(func(i: int) -> void: anchor_mode = _anchor_option.get_item_metadata(i))
	if battle_mode:
		# No palco da batalha real os modelos vêm da cena; trocar atacante/alvo/escala criaria modelos manuais por cima.
		_attacker_model_option.disabled = true
		_target_model_option.disabled = true
		_scale_check.disabled = true
	# Barra de transporte fixa no rodapé (fora do painel rolável).
	var bottom := PanelContainer.new()
	bottom.position = Vector2(16, 646)
	bottom.custom_minimum_size = Vector2(880, 64)
	bottom.visible = not _clean and not _hide_panel
	ui.add_child(bottom)
	var bmargin := MarginContainer.new()
	bmargin.add_theme_constant_override("margin_left", 10)
	bmargin.add_theme_constant_override("margin_right", 10)
	bmargin.add_theme_constant_override("margin_top", 4)
	bmargin.add_theme_constant_override("margin_bottom", 4)
	bottom.add_child(bmargin)
	var bbox := VBoxContainer.new()
	bbox.add_theme_constant_override("separation", 2)
	bmargin.add_child(bbox)
	# Transporte.
	var transport := HBoxContainer.new()
	bbox.add_child(transport)
	_play_button = Button.new()
	_play_button.text = "Pause"
	_play_button.pressed.connect(func() -> void: _set_play(not _playing))
	transport.add_child(_play_button)
	var restart := Button.new()
	restart.text = "Reiniciar"
	restart.pressed.connect(func() -> void: _time = 0.0; _set_play(false); _update_lab())
	transport.add_child(restart)
	var replay := Button.new()
	replay.text = "Replay"
	replay.pressed.connect(func() -> void: _time = 0.0; _set_play(true))
	transport.add_child(replay)
	_speed_option = OptionButton.new()
	for s in [0.25, 0.5, 1.0, 2.0]:
		_speed_option.add_item("%sx" % str(s))
	_speed_option.select(2)
	_speed_option.item_selected.connect(func(i: int) -> void: _speed = [0.25, 0.5, 1.0, 2.0][i])
	transport.add_child(_speed_option)
	# Timeline.
	_timeline = HSlider.new()
	_timeline.min_value = 0.0
	_timeline.max_value = TOTAL
	_timeline.step = 0.005
	_timeline.value = 0.0
	_timeline.value_changed.connect(func(v: float) -> void: _time = v; _set_play(false); _update_lab())
	bbox.add_child(_timeline)
	_time_label = Label.new()
	_time_label.text = "0,00 / 4,20 s"
	bbox.add_child(_time_label)
	# O HUD desenha fase/distância/log; o painel é só controle.
	_style_tree(panel)
	_style_tree(bottom)
	_ui_ready = true


func _style_tree(n: Node) -> void:
	for c in n.get_children():
		if c is Label:
			(c as Label).add_theme_font_size_override("font_size", 11)
		elif c is Button or c is OptionButton or c is CheckBox:
			var b := c as Control
			b.add_theme_font_size_override("font_size", 10)
			b.custom_minimum_size.y = 22
		_style_tree(c)


func _option(parent: Node, label: String, labels: Array, values: Array) -> OptionButton:
	var l := Label.new()
	l.text = label
	l.add_theme_font_size_override("font_size", 11)
	parent.add_child(l)
	var o := OptionButton.new()
	for i in labels.size():
		o.add_item(String(labels[i]))
		o.set_item_metadata(i, values[i])
	parent.add_child(o)
	return o


func _slider(parent: Node, label: String, lo: float, hi: float, value: float) -> HSlider:
	var box := VBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.add_theme_font_size_override("font_size", 10)
	box.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 1
	s.value = value
	s.custom_minimum_size = Vector2(110, 18)
	box.add_child(s)
	parent.add_child(box)
	return s


func _set_scenario(code: String) -> void:
	scenario = code
	_apply_scenario()
	_time = 0.0
	_set_play(true)


func _respawn_attacker() -> void:
	if not attacker.is_empty():
		attacker.root.queue_free()
	attacker = _spawn_fighter(attacker_id, true, NEAR, PI)
	attacker["home"] = _attacker_home
	attacker.root.position = _attacker_home
	_apply_distance_only()
	_refresh_geometry()


func quit_lab() -> void:
	get_tree().quit()


func _run_shot() -> void:
	_capturing = true
	_set_play(false)
	_time = clampf(float(_args.get("time", CONTACT + 0.05)), 0.0, TOTAL)
	_update_lab()
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shot_path.get_base_dir()))
	img.save_png(_shot_path)
	print("SHOT ", _shot_path, " t=", _time, " stats=", vfx.stats())
	quit_lab()


func _run_record() -> void:
	_capturing = true
	_set_play(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_record_dir))
	var frames := int(ceil(_record_seconds / _record_step))
	for i in frames:
		_time = clampf(_record_start + float(i) * _record_step, 0.0, TOTAL)
		_update_lab()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/f_%04d.png" % [_record_dir, i])
	print("RECORD ", _record_dir, " frames=", frames)
	quit_lab()
