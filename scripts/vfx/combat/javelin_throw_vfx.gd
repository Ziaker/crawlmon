class_name JavelinThrowVfx
extends Node3D
## VFX 3D do Move "Javelin Throw" (Opção C — "Lança do Ponto Fraco", fusão A + C).
##
## Regras: D-235 (nada de personagem/time/lado; tudo vem de hand/chest/feet/camera reais),
## D-308 (quatro fases e transição contínua), D-1030 (malhas 3D procedurais, sem Motion Composer),
## D-019/D-1040 (esta classe NÃO tem relógio de combate: o driver entrega o estado) e D-1103
## (nenhuma regra de dano/crítico/custo é tocada aqui).
##
## A cena de laboratório usa um relógio local só para inspeção; na batalha o `FxJavelinThrow`
## traduz as fases reais do `Incoming` para os mesmos parâmetros de `draw()`.

const COL_SOLAR_CORE := Color("#FFF3C4")
const COL_SOLAR_GOLD := Color("#FFD166")
const COL_CRIT_CRIMSON := Color("#FF2A55")
const COL_CRIT_DEEP := Color("#EF4444")
const COL_AMBER_PULSE := Color("#F59E0B")
const COL_AMBER_GLOW := Color("#FBBF24")
const COL_OBSIDIAN := Color("#1E293B")

const SPEAR_LENGTH := 2.15
const SPEAR_HALF := 1.075
const SPEAR_RADIUS_SCALE := 0.82
const GHOST_COUNT := 7
const CROWN_BLADES := 7
const DEBRIS_COUNT := 10
const SPARK_COUNT := 12

const WINDUP_FULL := 0.75
const RELEASE_END := 0.35
const IMPACT_CROSS_END := 0.50
const IMPACT_FLASH_END := 0.30
const IMPACT_DELAYED_RING_AT := 0.08
const IMPACT_DELAYED_RING_END := 0.60
const IMPACT_GROUND_END := 0.65
const IMPACT_DISSOLVE_AT := 0.60
const IMPACT_TOTAL := 0.80

var _camera: Camera3D
var _built := false
var _master_alpha := 1.0

# Espacial (entregue pelo driver a cada quadro)
var _hand := Vector3.ZERO
var _chest := Vector3.ZERO
var _feet := Vector3.ZERO
var _axis := Vector3.FORWARD
var _distance := 6.0
var _impact_scale := 1.0
var _view_scale := 1.0

# Nós
var _root: Node3D
var _spear_root: Node3D
var _spear_pieces: Array[Node3D] = []
var _piece_mats: Array = []  # Array[Array[ShaderMaterial]]
var _charge_pulse: Node3D
var _pulse_mats: Array = []
var _tip_star: Node3D
var _star_mat: ShaderMaterial
var _mark_core: MeshInstance3D
var _mark_shell: MeshInstance3D
var _mark_core_mat: ShaderMaterial
var _mark_shell_mat: ShaderMaterial
var _reticle_root: Node3D
var _reticle_ring: MeshInstance3D
var _reticle_wedges: Array[Node3D] = []
var _reticle_mat: ShaderMaterial
var _crown_root: Node3D
var _crown_blades: Array[Node3D] = []
var _crown_solid_inner: ShaderMaterial
var _crown_solid_outer: ShaderMaterial
var _crown_edge: ShaderMaterial
var _ghost_nodes: Array[MeshInstance3D] = []
var _ghost_mats: Array[ShaderMaterial] = []
var _beam: MeshInstance3D
var _beam_mat: ShaderMaterial
var _cross_blades: Array[MeshInstance3D] = []
var _cross_mat: ShaderMaterial
var _cross_edge_mat: ShaderMaterial
var _flash_inner: MeshInstance3D
var _flash_outer: MeshInstance3D
var _flash_inner_mat: ShaderMaterial
var _flash_outer_mat: ShaderMaterial
var _delayed_ring: MeshInstance3D
var _delayed_ring_mat: ShaderMaterial
var _ground_ring: MeshInstance3D
var _ground_ring_mat: ShaderMaterial
var _ground_spikes: Array[Node3D] = []
var _spike_meshes: Array[MeshInstance3D] = []
var _spike_mat: ShaderMaterial
var _spike_mesh: ArrayMesh
var _debris: Array[MeshInstance3D] = []
var _debris_dirs: Array[Vector3] = []
var _debris_mat: ShaderMaterial
var _sparks: Array[MeshInstance3D] = []
var _spark_dirs: Array[Vector3] = []
var _spark_mat: ShaderMaterial

# Malhas compartilhadas
var _shaft_mesh: ArrayMesh
var _grip_mesh: ArrayMesh
var _collar_mesh: ArrayMesh
var _collar_ring_mesh: ArrayMesh
var _gold_ring_mesh: ArrayMesh
var _fin_mesh: ArrayMesh
var _tip_mesh: ArrayMesh
var _tip_wire_mesh: ArrayMesh
var _star_mesh: ArrayMesh
var _pulse_torus_mesh: ArrayMesh
var _pulse_sleeve_mesh: ArrayMesh
var _line_core_mesh: ArrayMesh
var _line_shell_mesh: ArrayMesh
var _reticle_ring_mesh: ArrayMesh
var _wedge_mesh: ArrayMesh
var _crown_blade_inner_mesh: ArrayMesh
var _crown_blade_outer_mesh: ArrayMesh
var _crown_edge_inner_mesh: ArrayMesh
var _crown_edge_outer_mesh: ArrayMesh
var _ghost_mesh: ArrayMesh
var _beam_mesh: ArrayMesh
var _diamond_mesh: ArrayMesh
var _diamond_wire_mesh: ArrayMesh
var _flash_inner_mesh: ArrayMesh
var _flash_outer_mesh: ArrayMesh
var _delayed_ring_mesh: ArrayMesh
var _ground_ring_mesh: ArrayMesh
var _rock_mesh: ArrayMesh
var _spark_mesh: ArrayMesh

# Shaders (um PBR facetado e dois emissivos; nada de leitura de tela)
var _shader_pbr: Shader
var _shader_glow: Shader
var _shader_xray: Shader
var _shader_add: Shader


func setup(camera: Camera3D) -> void:
	_camera = camera
	if not _built:
		_build()


## Ajuda de laboratório (D-1162): posições/basis reais para provar a orientação sem chutar.
func debug_state() -> Dictionary:
	if not _built:
		return {}
	return {
		"hand": _hand,
		"chest": _chest,
		"axis": _axis,
		"tip": _spear_root.to_global(Vector3(0.0, 0.0, SPEAR_HALF)),
		"tail": _spear_root.to_global(Vector3(0.0, 0.0, -SPEAR_HALF)),
		"basis_z": _spear_root.global_transform.basis.z,
		"cross_vis": _cross_blades[0].visible if not _cross_blades.is_empty() else false,
		"cross_pos": _cross_blades[0].global_position if not _cross_blades.is_empty() else Vector3.ZERO,
		"cross_scale": _cross_blades[0].scale if not _cross_blades.is_empty() else Vector3.ZERO,
		"cross_alpha": _cross_mat.get_shader_parameter("alpha") if _cross_mat != null else -1.0,
		"spear_visible": _spear_root.visible,
		"piece0_visible": _spear_pieces[0].visible if not _spear_pieces.is_empty() else false,
		"piece4_visible": _spear_pieces[4].visible if _spear_pieces.size() > 4 else false,
		"piece0_alpha": _piece_mats[0][0].get_shader_parameter("alpha") if not _piece_mats.is_empty() else -1.0,
		"piece4_alpha": _piece_mats[4][0].get_shader_parameter("alpha") if _piece_mats.size() > 4 else -1.0,
		"tip_emission": _piece_mats[4][0].get_shader_parameter("emission_energy") if _piece_mats.size() > 4 else -1.0,
		"star_visible": _tip_star.visible,
		"crown_visible": _crown_root.visible,
		"beam_visible": _beam.visible,
		"reticle_visible": _reticle_root.visible,
		"reticle_ring_scale": _reticle_ring.scale.x,
		"flash_outer_scale": _flash_outer.scale.x,
		"flash_outer_radius": _flash_outer.scale.x,
		"flash_inner_radius": _flash_inner.scale.x,
		"spike0_visible": _ground_spikes[0].visible if not _ground_spikes.is_empty() else false,
	}


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	if not _built:
		_build()


## Desenha o estado recebido. Chaves:
## stage: "windup" | "flight" | "impact" | "miss" | "done"
## hand, chest, feet, axis, distance, impact_scale, view_scale
## windup_t, windup_total
## flight_u, flight_t, flight_duration
## release_t (segundos desde o disparo, inclusive depois do impacto)
## since_impact (segundos desde o contato; -1 antes)
## impact_chest (ponto congelado do contato; default = chest)
## crit (bool), miss_t (segundos desde a esquiva), master_alpha
func draw(p: Dictionary) -> void:
	if not _built:
		_build()
	_read_state(p)
	var stage := String(p.get("stage", "done"))
	_master_alpha = clampf(float(p.get("master_alpha", 1.0)), 0.0, 1.0)
	if stage == "done" or _master_alpha <= 0.001:
		_hide_all()
		return

	var windup_t := clampf(float(p.get("windup_t", 0.0)), 0.0, WINDUP_FULL)
	var windup_total := maxf(float(p.get("windup_total", WINDUP_FULL)), 0.01)
	var flight_u := clampf(float(p.get("flight_u", 0.0)), 0.0, 1.0)
	var flight_t := maxf(float(p.get("flight_t", 0.0)), 0.0)
	var flight_duration := maxf(float(p.get("flight_duration", 0.30)), 0.01)
	var release_t := float(p.get("release_t", -1.0))
	var since_impact := float(p.get("since_impact", -1.0))
	var crit := bool(p.get("crit", false))
	var impact_chest: Vector3 = p.get("impact_chest", _chest)
	var miss_t := maxf(float(p.get("miss_t", 0.0)), 0.0)

	_draw_spear(stage, windup_t, flight_u, release_t, since_impact, impact_chest, miss_t)
	_draw_windup_extras(stage, windup_t, release_t)
	_draw_crown(release_t, flight_duration)
	_draw_flight_layer(stage, flight_u, flight_t, flight_duration, release_t, since_impact, crit)
	_draw_impact(stage, since_impact, impact_chest, crit)
	# Se a montagem ainda não chegou ao fim, as camadas de voo/impacto não aparecem.
	if windup_t < windup_total and stage == "windup":
		_crown_root.visible = false
		_beam.visible = false
		for g in _ghost_nodes:
			g.visible = false
		_impact_hide()


func _read_state(p: Dictionary) -> void:
	_hand = p.get("hand", Vector3.ZERO)
	_chest = p.get("chest", _hand + Vector3.FORWARD)
	_feet = p.get("feet", Vector3(_chest.x, 0.0, _chest.z))
	_axis = p.get("axis", (_chest - _hand))
	if _axis.length_squared() < 0.0001:
		_axis = Vector3.FORWARD
	else:
		_axis = _axis.normalized()
	_distance = maxf(float(p.get("distance", 6.0)), 0.5)
	_impact_scale = clampf(float(p.get("impact_scale", 1.0)), 0.5, 2.2)
	_view_scale = clampf(float(p.get("view_scale", 1.0)), 0.5, 4.0)


func _hide_all() -> void:
	_spear_root.visible = false
	_mark_core.visible = false
	_mark_shell.visible = false
	_reticle_root.visible = false
	_crown_root.visible = false
	_beam.visible = false
	for g in _ghost_nodes:
		g.visible = false
	_impact_hide()


func _impact_hide() -> void:
	for c in _cross_blades:
		c.visible = false
	_flash_inner.visible = false
	_flash_outer.visible = false
	_delayed_ring.visible = false
	_ground_ring.visible = false
	for s in _ground_spikes:
		s.visible = false
	for d in _debris:
		d.visible = false
	for s in _sparks:
		s.visible = false


func _draw_spear(stage: String, windup_t: float, flight_u: float, release_t: float,
		since_impact: float, impact_chest: Vector3, miss_t: float) -> void:
	_spear_root.visible = stage != "done"
	if not _spear_root.visible:
		return

	var end_fade := 1.0
	var assembly_t := windup_t
	var center := _hand
	var basis := _spear_basis(_axis, _camera_position(), _hand)

	if stage == "windup":
		var pull := 0.0
		if windup_t < 0.70:
			pull = _ease_out_cubic(windup_t / 0.70) * 0.28
		else:
			pull = (1.0 - _ease_out_cubic((windup_t - 0.70) / 0.05)) * 0.28
		center = _hand - _axis * pull
	elif stage == "flight":
		assembly_t = WINDUP_FULL
		var sample := _sample_center(flight_u, _view_scale)
		center = sample["pos"]
		var tangent: Vector3 = sample["tangent"]
		basis = _spear_basis(tangent, _camera_position(), center)
		var spin := flight_u * TAU * 3.5
		basis = basis.rotated(tangent, spin)
	elif stage == "impact":
		assembly_t = WINDUP_FULL
		var half := SPEAR_HALF * _view_scale
		var tip_anchor := impact_chest + _axis * (0.32 * _view_scale)
		var vib := 0.0
		if since_impact >= 0.0 and since_impact <= 0.22:
			vib = sin(since_impact * 65.0) * exp(-since_impact * 14.0) * 0.08
		basis = _spear_basis(_axis, _camera_position(), impact_chest)
		basis = basis.rotated(basis.x, vib)
		center = tip_anchor - basis.z * half
		if since_impact >= IMPACT_DISSOLVE_AT:
			end_fade = 1.0 - clampf((since_impact - IMPACT_DISSOLVE_AT) / 0.20, 0.0, 1.0)
	elif stage == "miss":
		assembly_t = WINDUP_FULL
		var sample2 := _sample_center(1.0, _view_scale)
		center = sample2["pos"] + (sample2["tangent"] as Vector3) * (miss_t * 9.0 * _view_scale)
		basis = _spear_basis(sample2["tangent"], _camera_position(), center)
		end_fade = 1.0 - clampf(miss_t / 0.22, 0.0, 1.0)

	# A lança inteira escala com a distância da câmera (leitura de tela, D-308/D-1033).
	_spear_root.global_transform = Transform3D(basis.scaled(Vector3.ONE * _view_scale), center)

	# Montagem procedural das 5 peças (0.00 a 0.68 s).
	var windows := [
		Vector2(0.00, 0.22),  # haste
		Vector2(0.12, 0.35),  # empunhadura
		Vector2(0.25, 0.48),  # colar
		Vector2(0.36, 0.58),  # penas
		Vector2(0.46, 0.68),  # ponta (última)
	]
	var start_offsets := [
		Vector3(0.0, 0.35, -0.45),
		Vector3(0.28, -0.22, -0.15),
		Vector3(-0.25, 0.28, 0.30),
		Vector3(0.0, 0.0, -0.22),
		Vector3(0.0, 0.22, 0.55),
	]
	var start_rots := [
		Vector3(0.8, 0.4, 0.0),
		Vector3(0.0, 0.0, 1.4),
		Vector3(-0.9, 0.5, 0.0),
		Vector3(0.0, 0.0, 0.9),
		Vector3(0.0, 0.0, PI),
	]

	for i in range(5):
		var win: Vector2 = windows[i]
		var p_raw := clampf((assembly_t - win.x) / (win.y - win.x), 0.0, 1.0)
		var p_ease := _ease_out_cubic(p_raw)
		var piece: Node3D = _spear_pieces[i]
		piece.visible = assembly_t >= win.x and end_fade > 0.01
		piece.position = (start_offsets[i] as Vector3).lerp(Vector3.ZERO, p_ease)
		piece.rotation = (start_rots[i] as Vector3).lerp(Vector3.ZERO, p_ease)
		_piece_set_scale(piece, lerpf(0.25, 1.0, p_ease))
		_piece_set_alpha(i, p_ease * end_fade * _master_alpha)
		if i == 3:
			for f_idx in range(piece.get_child_count()):
				var fin_holder := piece.get_child(f_idx) as Node3D
				var ang := float(f_idx) * TAU / 3.0
				var radial_dir := Vector3(cos(ang), sin(ang), 0.0)
				var radial_off := (1.0 - p_ease) * 0.32
				fin_holder.position = radial_dir * (0.032 + radial_off) + Vector3(0.0, 0.0, -0.78)
				fin_holder.basis = Basis(Vector3.FORWARD, ang - PI * 0.5) * Basis(Vector3.RIGHT, 0.7 * (1.0 - p_ease))

	# O pulso e a estrela são filhos da lança: herdam o giro/posição reais.
	_draw_charge_pulse(stage, windup_t, end_fade)
	_draw_tip_star(stage, windup_t, release_t, end_fade)
	# O pulso âmbar também carrega a emissão da ponta (HTML: 0.45 -> 2.85), e a
	# ponta perde energia durante o voo/impacto até o dissolve.
	_update_tip_glow(stage, windup_t, flight_u, since_impact, end_fade)


func _update_tip_glow(stage: String, windup_t: float, flight_u: float, since_impact: float, end_fade: float) -> void:
	var energy := 4.5
	if stage == "windup":
		var pulse_p := clampf((windup_t - 0.58) / 0.17, 0.0, 1.0)
		energy = lerpf(2.8, 4.5, _ease_out_cubic(pulse_p))
	elif stage == "flight":
		energy = lerpf(4.5, 2.8, clampf(flight_u, 0.0, 1.0))
	elif stage == "impact":
		energy = lerpf(4.5, 2.8, clampf(since_impact / 0.50, 0.0, 1.0))
	elif stage == "miss":
		energy = 2.8
	_piece_mats[4][0].set_shader_parameter("emission_energy", maxf(energy, 0.2) * lerpf(0.35, 1.0, end_fade))


func _draw_charge_pulse(stage: String, windup_t: float, end_fade: float) -> void:
	var visible := stage == "windup" and windup_t >= 0.58 and windup_t <= WINDUP_FULL and end_fade > 0.01
	_charge_pulse.visible = visible
	if not visible:
		return
	var p := clampf((windup_t - 0.58) / (WINDUP_FULL - 0.58), 0.0, 1.0)
	var z := lerpf(-0.15, SPEAR_HALF, _ease_out_cubic(p))
	_charge_pulse.position = Vector3(0.0, 0.0, z)
	var s := 1.0 + sin(p * PI) * 0.65
	_charge_pulse.scale = Vector3(s, s, 1.0)
	for m in _pulse_mats:
		(m as ShaderMaterial).set_shader_parameter("alpha", sin(p * PI) * 0.95 * _master_alpha)


func _draw_tip_star(stage: String, windup_t: float, release_t: float, end_fade: float) -> void:
	var visible := false
	var elastic := 0.0
	var alpha := 0.0
	if stage == "windup" and windup_t >= 0.60 and windup_t <= WINDUP_FULL:
		visible = true
		var p := clampf((windup_t - 0.60) / 0.15, 0.0, 1.0)
		elastic = maxf(_ease_out_back(p), 0.001)
		alpha = clampf(p, 0.0, 1.0)
	elif release_t >= 0.0 and release_t < 0.15:
		# A estrela não corta no disparo: ela entrega a energia à coroa durante os
		# primeiros 0,15 s e só então desaparece (a coroa já está aberta).
		visible = true
		elastic = 1.0
		alpha = 1.0 - clampf(release_t / 0.15, 0.0, 1.0)
	_tip_star.visible = visible and end_fade > 0.01
	if not _tip_star.visible:
		return
	_tip_star.position = Vector3(0.0, 0.0, SPEAR_HALF)
	_tip_star.scale = Vector3.ONE * maxf(elastic, 0.001)
	_tip_star.rotation = Vector3(0.0, 0.0, (windup_t + maxf(release_t, 0.0)) * 8.5)
	_star_mat.set_shader_parameter("alpha", alpha * end_fade * _master_alpha)


## Linha de marcação, retículo e acessórios do wind-up.
func _draw_windup_extras(stage: String, windup_t: float, release_t: float) -> void:
	var mark_on := stage == "windup" and windup_t >= 0.05 and windup_t <= WINDUP_FULL
	var release_fade := 1.0
	if stage != "windup" and release_t >= 0.0 and release_t < 0.04:
		mark_on = true
		release_fade = 1.0 - release_t / 0.04

	_mark_core.visible = false
	_mark_shell.visible = false
	_reticle_root.visible = false
	if not mark_on:
		return

	var tip_world := _spear_root.to_global(Vector3(0.0, 0.0, SPEAR_HALF))
	var p_line := clampf((windup_t - 0.05) / 0.25, 0.0, 1.0)
	var line_end := tip_world.lerp(_chest, _ease_out_cubic(p_line))
	var seg := line_end - tip_world
	var seg_len := seg.length()
	if seg_len > 0.02:
		_mark_core.visible = true
		_mark_shell.visible = true
		var mid := (tip_world + line_end) * 0.5
		var b := _spear_basis(seg / seg_len, _camera_position(), mid)
		var pulse_w := 1.0 + 0.25 * sin(windup_t * 28.0)
		var pulse_a := 0.85 + 0.15 * sin(windup_t * 28.0)
		_mark_core.global_transform = Transform3D(b * Basis.from_scale(Vector3(_view_scale, _view_scale, seg_len)), mid)
		_mark_shell.global_transform = Transform3D(b * Basis.from_scale(Vector3(pulse_w * _view_scale, pulse_w * _view_scale, seg_len)), mid)
		_mark_core_mat.set_shader_parameter("alpha", 0.90 * pulse_a * release_fade * _master_alpha)
		_mark_shell_mat.set_shader_parameter("alpha", 0.42 * pulse_a * release_fade * _master_alpha)

	if windup_t >= 0.15:
		_reticle_root.visible = true
		var p_ret := clampf((windup_t - 0.15) / 0.57, 0.0, 1.0)
		var ret_ease := _ease_out_cubic(p_ret)
		var b2 := _spear_basis(_axis, _camera_position(), _chest)
		b2 = b2.rotated(_axis, (1.0 - ret_ease) * PI)
		_reticle_root.global_transform = Transform3D(b2.scaled(Vector3.ONE * _view_scale), _chest)
		var ring_sc := lerpf(0.55, 0.18, ret_ease) * _impact_scale
		_reticle_ring.scale = Vector3.ONE * ring_sc
		var wedge_dist := lerpf(0.55, 0.18, ret_ease) * _impact_scale
		for w_idx in range(4):
			var a: float = float(w_idx) * PI * 0.5 + PI * 0.25
			var wedge: Node3D = _reticle_wedges[w_idx]
			wedge.position = Vector3(cos(a) * wedge_dist, sin(a) * wedge_dist, 0.0)
			wedge.rotation = Vector3(0.0, 0.0, a + PI)
			wedge.scale = Vector3.ONE * _impact_scale
		_reticle_mat.set_shader_parameter("alpha", clampf(p_ret * 1.2, 0.0, 0.92) * release_fade * _master_alpha)


## Coroa prismática de 7 lâminas em 2 camadas (0,75 a 1,10 s absolutos).
func _draw_crown(release_t: float, flight_duration: float) -> void:
	_crown_root.visible = false
	if release_t < 0.0 or release_t > RELEASE_END:
		return
	_crown_root.visible = true

	var gap := 0.0
	var flare_deg := 9.0
	if release_t <= 0.15:
		var q := _ease_out_cubic(release_t / 0.15)
		gap = lerpf(0.025, 0.25, q)
		flare_deg = lerpf(9.0, 25.0, q)
	else:
		var q2 := _ease_out_cubic((release_t - 0.15) / 0.20)
		gap = lerpf(0.25, 0.46, q2)
		flare_deg = lerpf(25.0, 36.0, q2)
	var layer_t := clampf(release_t / 0.15, 0.0, 1.0)

	var origin := _hand
	var dir := _axis
	var u_follow := clampf(release_t / flight_duration, 0.0, 1.0)
	var sample := _sample_center(u_follow, _view_scale)
	dir = sample["tangent"]
	var tip_now: Vector3 = (sample["pos"] as Vector3) + dir * (SPEAR_HALF * _view_scale)
	if release_t <= 0.15:
		var recoil := lerpf(0.0, 0.68 * _view_scale, _ease_out_cubic(release_t / 0.15))
		origin = tip_now - dir * recoil
	else:
		var s15 := _sample_center(clampf(0.15 / flight_duration, 0.0, 1.0), _view_scale)
		var d15: Vector3 = s15["tangent"]
		var tip15: Vector3 = (s15["pos"] as Vector3) + d15 * (SPEAR_HALF * _view_scale)
		var at15 := tip15 - d15 * (0.68 * _view_scale)
		var post := clampf((release_t - 0.15) / 0.20, 0.0, 1.0)
		origin = at15 - d15 * (_ease_out_cubic(post) * 0.38 * _view_scale)
		dir = d15

	var b := _spear_basis(dir, _camera_position(), origin)
	_crown_root.global_transform = Transform3D(b.scaled(Vector3.ONE * _view_scale), origin)

	var alpha := 0.85
	if release_t > 0.22:
		alpha = lerpf(0.65, 0.0, clampf((release_t - 0.22) / 0.13, 0.0, 1.0))
	else:
		alpha = lerpf(0.85, 0.65, clampf(release_t / 0.22, 0.0, 1.0))
	var thickness := 1.0
	if release_t > 0.27:
		thickness = lerpf(1.0, 0.35, clampf((release_t - 0.27) / 0.08, 0.0, 1.0))

	for i in range(CROWN_BLADES):
		var holder: Node3D = _crown_blades[i]
		var outer := i % 2 == 1
		var layer_off := 0.042 if outer else 0.0
		var layer_z := -0.055 if outer else 0.0
		var angle := float(i) * TAU / float(CROWN_BLADES)
		var r := gap + layer_off * layer_t
		holder.position = Vector3(cos(angle) * r, sin(angle) * r, layer_z * layer_t)
		var bb := Basis.IDENTITY
		bb = bb.rotated(Vector3.FORWARD, angle - PI * 0.5)
		# A cauda (base em -Z) abre para FORA do eixo; o ápice continua no tip.
		bb = bb.rotated(bb.x, deg_to_rad(flare_deg))
		holder.basis = bb
		holder.scale = Vector3(thickness, thickness, 1.0)

	_crown_solid_inner.set_shader_parameter("alpha", alpha * 0.82 * _master_alpha)
	_crown_solid_outer.set_shader_parameter("alpha", alpha * 0.78 * _master_alpha)
	_crown_edge.set_shader_parameter("alpha", minf(alpha * 1.25, 1.0) * _master_alpha)


## Pós-imagens 3D sólidas, feixe perfurante e o dardo em voo.
func _draw_flight_layer(stage: String, flight_u: float, flight_t: float, flight_duration: float,
		release_t: float, since_impact: float, crit: bool) -> void:
	var ghosts_on := stage == "flight" or stage == "impact"
	var ghost_fade := 1.0
	if stage == "impact":
		ghost_fade = 1.0 - clampf(since_impact / 0.11, 0.0, 1.0)
	for k in range(GHOST_COUNT):
		var node: MeshInstance3D = _ghost_nodes[k]
		var u_ghost := flight_u - float(k + 1) * 0.095
		var on := ghosts_on and u_ghost > 0.02 and u_ghost <= 1.0 and ghost_fade > 0.01
		node.visible = on
		if not on:
			continue
		var sample := _sample_center(u_ghost, _view_scale)
		var tangent: Vector3 = sample["tangent"]
		var b := _spear_basis(tangent, _camera_position(), sample["pos"])
		b = b.rotated(tangent, u_ghost * TAU * 3.5)
		node.global_transform = Transform3D(b.scaled(Vector3.ONE * _view_scale), sample["pos"])
		var base := (1.0 - float(k + 1) / 7.5) * 0.55
		_ghost_mats[k].set_shader_parameter("alpha", base * ghost_fade * _master_alpha)

	# Feixe perfurante volumétrico (mão -> dardo), com cauda que decai.
	var beam_on := (stage == "flight") or (stage == "impact" and since_impact <= 0.17)
	_beam.visible = beam_on
	if not beam_on:
		return
	var start := _hand
	var end := _hand + _axis * 0.1
	if stage == "flight":
		var sample2 := _sample_center(flight_u, _view_scale)
		end = sample2["pos"]  # até o centro do dardo; a ponta e a haste ficam legíveis
	else:
		end = _chest
	var seg := end - start
	var length := seg.length()
	if length <= 0.05:
		_beam.visible = false
		return
	var mid := (start + end) * 0.5
	var bb := _spear_basis(seg / length, _camera_position(), mid)
	_beam.global_transform = Transform3D(bb * Basis.from_scale(Vector3(_view_scale, _view_scale, length)), mid)
	var fade := 1.0
	if stage == "impact":
		fade = 1.0 - clampf(since_impact / 0.17, 0.0, 1.0)
	_beam_mat.set_shader_parameter("alpha", 0.42 * fade * _master_alpha)


## Perfuração em cruz 3D, flash crítico, anel atrasado, anel rasteiro, detritos e faíscas.
func _draw_impact(stage: String, since_impact: float, impact_chest: Vector3, crit: bool) -> void:
	if stage != "impact" or since_impact < 0.0:
		_impact_hide()
		return
	var S := _impact_scale * _view_scale
	# Os anéis e o flash são lidos como um halo em volta do corpo, não como uma cúpula
	# gigante a 37 m; a cruz e as faíscas mantêm a escala cheia para o crítico furar a leitura.
	var R := _impact_scale * sqrt(_view_scale)
	var b := _spear_basis(_axis, _camera_position(), impact_chest)
	var crit_k := 1.18 if crit else 1.0

	# 1. Cruz 3D (0,00 a 0,50 s).
	if since_impact <= IMPACT_CROSS_END:
		var p := clampf(since_impact / IMPACT_CROSS_END, 0.0, 1.0)
		var burst := clampf(since_impact / 0.06, 0.0, 1.0)
		var fade := 1.0 - pow(p, 1.6)
		var len_mult := lerpf(0.55, 1.15, _ease_out_cubic(p)) * burst
		var thick_mult := lerpf(1.25, 0.12, p) * burst
		var col := COL_SOLAR_CORE.lerp(COL_CRIT_CRIMSON, clampf(p, 0.0, 1.0))
		_cross_mat.set_shader_parameter("albedo_color", col)
		_cross_mat.set_shader_parameter("emission_color", col)
		_cross_mat.set_shader_parameter("alpha", clampf(fade * 0.96, 0.0, 1.0) * _master_alpha)
		_cross_edge_mat.set_shader_parameter("alpha", clampf(fade * 0.75, 0.0, 1.0) * _master_alpha)
		for c_idx in range(3):
			var blade: MeshInstance3D = _cross_blades[c_idx]
			blade.visible = true
			var length := 2.65 if c_idx < 2 else 2.95
			var width := 0.14 if c_idx < 2 else 0.16
			var bb := b
			if c_idx < 2:
				# As duas lâminas em X vivem no plano ORTOGONAL a `axis`; a longitudinal
				# atravessa o peito ao longo do próprio axis. Sem isso as três ficariam
				# todas apontando para o alvo e a cruz sumiria de lado.
				var plane_dir: Vector3 = b.x * cos(deg_to_rad(45.0)) + b.y * sin(deg_to_rad(45.0))
				if c_idx == 1:
					plane_dir = b.x * cos(deg_to_rad(-45.0)) + b.y * sin(deg_to_rad(-45.0))
				plane_dir = (plane_dir + _axis * tan(deg_to_rad(15.0))).normalized()
				bb = _spear_basis(plane_dir, _camera_position(), impact_chest)
			var s := Vector3(width * S * thick_mult, width * S * thick_mult, length * S * len_mult)
			blade.global_transform = Transform3D(bb * Basis.from_scale(s), impact_chest)
	else:
		for c in _cross_blades:
			c.visible = false

	# 2. Flash crítico volumétrico 3D (0,00 a 0,30 s).
	if since_impact <= IMPACT_FLASH_END:
		_flash_inner.visible = true
		_flash_outer.visible = true
		var p2 := clampf(since_impact / IMPACT_FLASH_END, 0.0, 1.0)
		var expand := _ease_out_cubic(clampf(since_impact / 0.08, 0.0, 1.0))
		var collapse := 1.0 - clampf((since_impact - 0.08) / 0.22, 0.0, 1.0)
		var fade2 := 1.0 - pow(p2, 1.5)
		_flash_inner.global_position = impact_chest
		_flash_outer.global_position = impact_chest
		_flash_inner.rotation = Vector3(since_impact * 7.0, since_impact * 9.0, 0.0)
		_flash_outer.rotation = Vector3(-since_impact * 5.0, since_impact * 6.0, since_impact * 4.0)
		_flash_inner.scale = Vector3.ONE * (0.38 * S * expand * (0.35 + 0.65 * collapse) * crit_k)
		_flash_outer.scale = Vector3.ONE * (0.62 * S * expand * collapse * crit_k)
		_flash_inner_mat.set_shader_parameter("alpha", fade2 * 0.92 * _master_alpha)
		_flash_outer_mat.set_shader_parameter("alpha", fade2 * 0.65 * _master_alpha)
	else:
		_flash_inner.visible = false
		_flash_outer.visible = false

	# 3. Anel fino 3D atrasado (+0,08 s).
	if since_impact >= IMPACT_DELAYED_RING_AT and since_impact <= IMPACT_DELAYED_RING_END:
		_delayed_ring.visible = true
		var p3 := clampf((since_impact - IMPACT_DELAYED_RING_AT) / (IMPACT_DELAYED_RING_END - IMPACT_DELAYED_RING_AT), 0.0, 1.0)
		var ease_quart := 1.0 - pow(1.0 - p3, 4.0)
		var radius := lerpf(0.18, 1.85, ease_quart) * S
		var ring_b := b.rotated(b.x, deg_to_rad(18.0))
		var tube := 0.022 * S
		_delayed_ring.mesh = _mesh_torus(maxf(radius - tube, 0.001), radius + tube, 24, 8, false)
		_delayed_ring.global_transform = Transform3D(ring_b, impact_chest)
		_delayed_ring_mat.set_shader_parameter("alpha", (1.0 - p3) * 0.90 * _master_alpha)
	else:
		_delayed_ring.visible = false

	# 4. Anel rasteiro, detritos e faíscas (0,00 a 0,65 s).
	if since_impact <= IMPACT_GROUND_END:
		var p4 := clampf(since_impact / IMPACT_GROUND_END, 0.0, 1.0)
		var ease_g := _ease_out_cubic(p4)
		_ground_ring.visible = true
		var g_pos := _feet + Vector3(0.0, 0.04, 0.0)
		var g_radius := lerpf(0.22, 1.45, ease_g) * S
		var g_tube := 0.065 * S
		_ground_ring.mesh = _mesh_torus(maxf(g_radius - g_tube, 0.001), g_radius + g_tube, 20, 8, true)
		_ground_ring.global_transform = Transform3D(Basis.IDENTITY, g_pos)
		_ground_ring_mat.set_shader_parameter("alpha", (1.0 - p4) * 0.78 * _master_alpha)

		# 8 espinhos 3D de terra/rocha (HTML Card C): nascem no anel, sobem e recolhem.
		var spike_pop := sin(clampf(p4 * 2.3, 0.0, 1.0) * PI)
		_spike_mat.set_shader_parameter("alpha", clampf(spike_pop * 1.05, 0.0, 1.0) * _master_alpha)
		for s_idx in range(_ground_spikes.size()):
			var s_holder: Node3D = _ground_spikes[s_idx]
			var s_mesh: MeshInstance3D = _spike_meshes[s_idx]
			s_holder.visible = spike_pop > 0.01
			if not s_holder.visible:
				continue
			var a := float(s_idx) * TAU / 8.0
			var r := (0.32 + ease_g * 1.20) * R
			s_holder.global_position = Vector3(_feet.x + cos(a) * r, _feet.y + 0.02, _feet.z + sin(a) * r)
			s_holder.rotation.y = -a
			s_mesh.scale = Vector3.ONE * maxf(spike_pop * 1.10 * R, 0.001)

		_debris_mat.set_shader_parameter("alpha", (1.0 - p4) * 0.90 * _master_alpha)
		for d_idx in range(DEBRIS_COUNT):
			var d: MeshInstance3D = _debris[d_idx]
			d.visible = true
			var vel: Vector3 = _debris_dirs[d_idx] * R
			var d_pos: Vector3 = g_pos + vel * since_impact + Vector3(0.0, -4.9 * since_impact * since_impact, 0.0)
			d_pos.y = maxf(d_pos.y, _feet.y + 0.03)
			d.global_position = d_pos
			d.rotation = Vector3(since_impact * 6.0 * float(d_idx + 1), since_impact * 4.5, since_impact * 5.0)
			var d_sc: float = (0.06 + float(d_idx % 3) * 0.035) * (1.0 - p4 * 0.65) * R
			d.scale = Vector3.ONE * d_sc

		_spark_mat.set_shader_parameter("alpha", (1.0 - p4) * 0.95 * _master_alpha)
		for s_idx in range(SPARK_COUNT):
			var s_node: MeshInstance3D = _sparks[s_idx]
			s_node.visible = true
			var local_dir: Vector3 = _spark_dirs[s_idx]
			var world_dir: Vector3 = (b * local_dir).normalized()
			var speed: float = (3.2 + float(s_idx % 4) * 0.85) * S
			var s_pos: Vector3 = impact_chest + world_dir * (speed * _ease_out_cubic(p4))
			var sb := _spear_basis(world_dir, _camera_position(), s_pos)
			var s_len: float = 0.24 * (1.0 - p4 * 0.7) * S
			var ssc := Vector3(0.044 * S, 0.044 * S, maxf(s_len, 0.01))
			s_node.global_transform = Transform3D(sb * Basis.from_scale(ssc), s_pos)
	else:
		_ground_ring.visible = false
		_spike_mat.set_shader_parameter("alpha", 0.0)
		for s in _ground_spikes:
			s.visible = false
		for d in _debris:
			d.visible = false
		for s in _sparks:
			s.visible = false


# ============================================================================
# BALLISTIC / BASIS / EASE
# ============================================================================

func _sample_center(u_raw: float, view_scale: float) -> Dictionary:
	var u := clampf(u_raw, 0.0, 1.0)
	var uf := pow(u, 0.88)
	var half := SPEAR_HALF * view_scale
	var end_center := _chest - _axis * (half - 0.32 * view_scale)
	var arc := minf(_distance * 0.035, 0.28 * view_scale)
	var pos := _hand.lerp(end_center, uf) + Vector3.UP * (4.0 * uf * (1.0 - uf) * arc)
	var u0 := maxf(u - 0.02, 0.0)
	var u1 := minf(u + 0.02, 1.0)
	var uf0 := pow(u0, 0.88)
	var uf1 := pow(u1, 0.88)
	var p0 := _hand.lerp(end_center, uf0) + Vector3.UP * (4.0 * uf0 * (1.0 - uf0) * arc)
	var p1 := _hand.lerp(end_center, uf1) + Vector3.UP * (4.0 * uf1 * (1.0 - uf1) * arc)
	var tangent := (p1 - p0).normalized()
	if tangent.length_squared() < 0.0001:
		tangent = _axis
	return {"pos": pos, "tangent": tangent}


func _spear_basis(forward_dir: Vector3, cam_pos: Vector3, origin: Vector3) -> Basis:
	var forward := forward_dir.normalized()
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	var up_ref := Vector3.UP
	if absf(forward.dot(up_ref)) > 0.98:
		up_ref = Vector3.FORWARD
	var right := up_ref.cross(forward).normalized()
	var up := forward.cross(right).normalized()
	var to_cam := cam_pos - origin
	var cam_proj := to_cam - forward * to_cam.dot(forward)
	var cam_roll := 0.22
	if cam_proj.length_squared() > 0.0001:
		cam_proj = cam_proj.normalized()
		cam_roll = atan2(cam_proj.dot(right), cam_proj.dot(up)) + 0.22
	var b := Basis(right, up, forward)
	return b.rotated(forward, cam_roll)


func _camera_position() -> Vector3:
	if _camera != null and _camera.is_inside_tree():
		return _camera.global_position
	var vp := get_viewport()
	if vp != null and vp.get_camera_3d() != null:
		return vp.get_camera_3d().global_position
	return _hand + Vector3(0.0, 2.5, 4.5)


func _ease_out_cubic(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - c, 3.0)


func _ease_out_back(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(c - 1.0, 3.0) + c1 * pow(c - 1.0, 2.0)


# ============================================================================
# CONSTRUÇÃO
# ============================================================================

func _build() -> void:
	if _built:
		return
	_built = true
	_init_shaders()
	_make_meshes()
	_build_spear()
	_build_mark_and_reticle()
	_build_crown()
	_build_ghosts_and_beam()
	_build_impact()
	_hide_all()


func _init_shaders() -> void:
	_shader_pbr = Shader.new()
	_shader_pbr.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform vec4 albedo_color : source_color = vec4(0.12, 0.16, 0.22, 1.0);
uniform vec4 emission_color : source_color = vec4(1.0, 0.82, 0.4, 1.0);
uniform float emission_energy : hint_range(0.0, 8.0) = 0.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
void fragment() {
	ALBEDO = albedo_color.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	EMISSION = emission_color.rgb * emission_energy;
	ALPHA = clamp(alpha * albedo_color.a, 0.0, 1.0);
}
"""
	_shader_glow = Shader.new()
	_shader_glow.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;
uniform vec4 albedo_color : source_color = vec4(1.0, 0.95, 0.77, 1.0);
uniform vec4 emission_color : source_color = vec4(1.0, 0.82, 0.4, 1.0);
uniform float emission_energy : hint_range(0.0, 8.0) = 2.5;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.2;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
void fragment() {
	float ndv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fres = pow(1.0 - ndv, fresnel_power);
	vec3 c = mix(albedo_color.rgb, emission_color.rgb, 0.45 + 0.55 * fres);
	ALBEDO = c * (1.0 + emission_energy * 0.16 * (0.35 + 0.65 * fres));
	ALPHA = clamp(alpha * albedo_color.a, 0.0, 1.0);
}
"""
	# Variante "x-ray" para o retículo do ponto fraco e para a cruz de perfuração:
	# a geometria continua 3D, mas é lida através do corpo do alvo (D-308: legível
	# de frente, de lado e de trás, sem virar billboard).
	_shader_xray = Shader.new()
	_shader_xray.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, unshaded;
uniform vec4 albedo_color : source_color = vec4(1.0, 0.95, 0.77, 1.0);
uniform vec4 emission_color : source_color = vec4(1.0, 0.82, 0.4, 1.0);
uniform float emission_energy : hint_range(0.0, 8.0) = 2.5;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.2;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
void fragment() {
	float ndv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fres = pow(1.0 - ndv, fresnel_power);
	vec3 c = mix(albedo_color.rgb, emission_color.rgb, 0.45 + 0.55 * fres);
	ALBEDO = c * (1.0 + emission_energy * 0.16 * (0.35 + 0.65 * fres));
	ALPHA = clamp(alpha * albedo_color.a, 0.0, 1.0);
}
"""
	_shader_add = Shader.new()
	_shader_add.code = """
shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;
uniform vec4 albedo_color : source_color = vec4(1.0, 0.95, 0.77, 1.0);
uniform vec4 emission_color : source_color = vec4(1.0, 0.82, 0.4, 1.0);
uniform float emission_energy : hint_range(0.0, 8.0) = 3.0;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.0;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
void fragment() {
	float ndv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fres = pow(1.0 - ndv, fresnel_power);
	vec3 c = mix(albedo_color.rgb, emission_color.rgb, 0.5 + 0.5 * fres);
	ALBEDO = c * (0.18 + emission_energy * 0.20) * (0.55 + 0.45 * fres);
	ALPHA = alpha;
}
"""


func _make_meshes() -> void:
	var r := SPEAR_RADIUS_SCALE
	_shaft_mesh = _mesh_cylinder_z(0.023 * r, 0.018 * r, 1.45, 8)
	_grip_mesh = _mesh_cylinder_z(0.030 * r, 0.030 * r, 0.38, 8)
	_collar_mesh = _mesh_cylinder_z(0.044 * r, 0.028 * r, 0.12, 8)
	_collar_ring_mesh = _mesh_torus(0.032, 0.048, 12, 6, false)
	_gold_ring_mesh = _mesh_torus(0.026 * r, 0.035 * r, 12, 6, false)
	_fin_mesh = _mesh_fin(0.012, 0.095, 0.28)
	_tip_mesh = _mesh_pyramid4(0.495, 0.052 * r)
	_tip_wire_mesh = _mesh_pyramid4_wire(0.495, 0.052 * r)
	_star_mesh = _mesh_octahedron(1.0)
	_pulse_torus_mesh = _mesh_torus(0.044, 0.066, 12, 6, false)
	_pulse_sleeve_mesh = _mesh_cylinder_z(0.055, 0.055, 0.20, 10, false)
	_line_core_mesh = _mesh_cylinder_z(0.010, 0.010, 1.0, 6)
	_line_shell_mesh = _mesh_cylinder_z(0.024, 0.024, 1.0, 6)
	_reticle_ring_mesh = _mesh_torus(0.98, 1.0, 8, 5, false)
	_wedge_mesh = _mesh_pyramid4(0.14, 0.045)
	_crown_blade_inner_mesh = _mesh_prism_blade(0.58, 0.048, 0.004)
	_crown_blade_outer_mesh = _mesh_prism_blade(0.46, 0.048, 0.004)
	_crown_edge_inner_mesh = _mesh_prism_wire(0.58, 0.050, 0.005)
	_crown_edge_outer_mesh = _mesh_prism_wire(0.46, 0.050, 0.005)
	_beam_mesh = _mesh_cylinder_z(0.018, 0.042, 1.0, 8)
	_diamond_mesh = _mesh_diamond(1.0, 1.0, 4)
	_diamond_wire_mesh = _mesh_diamond_wire(1.0, 1.0, 4)
	_flash_inner_mesh = _mesh_icosahedron(1.0)
	_flash_outer_mesh = _mesh_octahedron(2.0)
	_delayed_ring_mesh = _mesh_torus(0.956, 1.0, 24, 8, false)
	_ground_ring_mesh = _mesh_torus(0.91, 1.0, 20, 8, true)
	_spike_mesh = _mesh_pyramid4(0.48, 0.11)
	_rock_mesh = _mesh_icosahedron(0.5)
	_spark_mesh = _mesh_diamond(1.0, 1.0, 4)
	_ghost_mesh = _build_ghost_mesh()


func _pbr(albedo: Color, emission: Color, energy: float, metallic: float, roughness: float, alpha := 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader_pbr
	m.set_shader_parameter("albedo_color", albedo)
	m.set_shader_parameter("emission_color", emission)
	m.set_shader_parameter("emission_energy", energy)
	m.set_shader_parameter("metallic", metallic)
	m.set_shader_parameter("roughness", roughness)
	m.set_shader_parameter("alpha", alpha)
	return m


func _glow(albedo: Color, emission: Color, energy: float, alpha := 1.0, additive := false, xray := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	if additive:
		m.shader = _shader_add
	elif xray:
		m.shader = _shader_xray
	else:
		m.shader = _shader_glow
	m.set_shader_parameter("albedo_color", albedo)
	m.set_shader_parameter("emission_color", emission)
	m.set_shader_parameter("emission_energy", energy)
	m.set_shader_parameter("alpha", alpha)
	return m


func _mi(mesh: Mesh, mat: Material, node_name := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if not node_name.is_empty():
		mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _build_spear() -> void:
	_root = Node3D.new()
	_root.name = "JavelinThrowRoot"
	add_child(_root)
	_root.top_level = true
	_root.global_transform = Transform3D.IDENTITY

	_spear_root = Node3D.new()
	_spear_root.name = "Javelin"
	_root.add_child(_spear_root)

	# 0 — haste principal + anéis dourados.
	var p0 := Node3D.new()
	p0.name = "Shaft"
	var shaft_mat := _pbr(COL_OBSIDIAN, COL_SOLAR_GOLD, 0.35, 0.85, 0.25)
	var ring_mat := _glow(COL_SOLAR_GOLD, COL_SOLAR_CORE, 3.0, 1.0, false)
	var shaft_mi := _mi(_shaft_mesh, shaft_mat, "ShaftMesh")
	shaft_mi.position = Vector3(0.0, 0.0, -0.15)
	p0.add_child(shaft_mi)
	for z in [-0.60, -0.15, 0.30]:
		var ring := _mi(_gold_ring_mesh, ring_mat, "GoldBand")
		ring.position = Vector3(0.0, 0.0, z)
		p0.add_child(ring)
	_spear_root.add_child(p0)
	_spear_pieces.append(p0)
	_piece_mats.append([shaft_mat, ring_mat])

	# 1 — empunhadura.
	var p1 := Node3D.new()
	p1.name = "Grip"
	var grip_mat := _pbr(COL_CRIT_CRIMSON, COL_SOLAR_GOLD, 0.55, 0.10, 0.62)
	var grip_band_mat := _glow(COL_SOLAR_GOLD, COL_SOLAR_CORE, 2.8, 1.0, false)
	var grip_mi := _mi(_grip_mesh, grip_mat, "GripMesh")
	grip_mi.position = Vector3(0.0, 0.0, -0.05)
	p1.add_child(grip_mi)
	for z in [-0.22, 0.12]:
		var band := _mi(_gold_ring_mesh, grip_band_mat, "GripBand")
		band.position = Vector3(0.0, 0.0, z)
		p1.add_child(band)
	_spear_root.add_child(p1)
	_spear_pieces.append(p1)
	_piece_mats.append([grip_mat, grip_band_mat])

	# 2 — colar facetado.
	var p2 := Node3D.new()
	p2.name = "Collar"
	var collar_mat := _pbr(COL_OBSIDIAN, COL_SOLAR_GOLD, 0.55, 0.85, 0.25)
	var collar_ring_mat := _glow(COL_SOLAR_GOLD, COL_SOLAR_CORE, 2.8, 1.0, false)
	var collar_mi := _mi(_collar_mesh, collar_mat, "CollarMesh")
	collar_mi.position = Vector3(0.0, 0.0, 0.58)
	p2.add_child(collar_mi)
	var collar_ring := _mi(_collar_ring_mesh, collar_ring_mat, "CollarRing")
	collar_ring.position = Vector3(0.0, 0.0, 0.58)
	p2.add_child(collar_ring)
	_spear_root.add_child(p2)
	_spear_pieces.append(p2)
	_piece_mats.append([collar_mat, collar_ring_mat])

	# 3 — três penas estabilizadoras.
	var p3 := Node3D.new()
	p3.name = "Fins"
	var fin_mat := _glow(COL_CRIT_CRIMSON, COL_SOLAR_GOLD, 3.2, 1.0, false)
	for f in range(3):
		var holder := Node3D.new()
		holder.name = "Fin%d" % f
		var fin := _mi(_fin_mesh, fin_mat, "FinMesh")
		holder.add_child(fin)
		p3.add_child(holder)
	_spear_root.add_child(p3)
	_spear_pieces.append(p3)
	_piece_mats.append([fin_mat])

	# 4 — ponta perfurante (a última peça).
	var p4 := Node3D.new()
	p4.name = "Tip"
	var tip_mat := _glow(COL_SOLAR_CORE, COL_SOLAR_GOLD, 4.5, 1.0, false)
	var tip_edge_mat := _glow(COL_SOLAR_CORE, COL_SOLAR_GOLD, 2.8, 0.75, false)
	var tip := _mi(_tip_mesh, tip_mat, "TipMesh")
	tip.position = Vector3(0.0, 0.0, 0.58)
	p4.add_child(tip)
	var tip_edge := _mi(_tip_wire_mesh, tip_edge_mat, "TipEdges")
	tip_edge.position = Vector3(0.0, 0.0, 0.58)
	p4.add_child(tip_edge)
	_spear_root.add_child(p4)
	_spear_pieces.append(p4)
	_piece_mats.append([tip_mat, tip_edge_mat])

	# Pulso âmbar (torus + luva) e estrela de 3 octaedros.
	_charge_pulse = Node3D.new()
	_charge_pulse.name = "ChargePulse"
	var pulse_torus_mat := _glow(COL_AMBER_PULSE, COL_AMBER_GLOW, 2.5, 1.0, true)
	var pulse_sleeve_mat := _glow(COL_AMBER_PULSE, COL_AMBER_GLOW, 2.5, 1.0, true)
	_pulse_mats = [pulse_torus_mat, pulse_sleeve_mat]
	var pt := _mi(_pulse_torus_mesh, pulse_torus_mat, "PulseRing")
	_charge_pulse.add_child(pt)
	var ps := _mi(_pulse_sleeve_mesh, pulse_sleeve_mat, "PulseSleeve")
	_charge_pulse.add_child(ps)
	_spear_root.add_child(_charge_pulse)

	_tip_star = Node3D.new()
	_tip_star.name = "TipStar"
	_star_mat = _glow(COL_SOLAR_CORE, COL_SOLAR_GOLD, 4.5, 1.0, true)
	# A malha base é um octaedro alongado em Z; para obter os três eixos X/Y/Z
	# usamos a mesma escala (comprimento 0,42; espessura 0,055) e rotacionamos
	# X e Y. Assim os três eixos existem de verdade.
	for i in range(3):
		var spike := _mi(_star_mesh, _star_mat, "StarSpike%d" % i)
		spike.scale = Vector3(0.055, 0.055, 0.42)
		if i == 0:
			spike.rotation = Vector3(0.0, PI * 0.5, 0.0)
		elif i == 1:
			spike.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
		_tip_star.add_child(spike)
	_spear_root.add_child(_tip_star)


func _build_mark_and_reticle() -> void:
	_mark_core_mat = _glow(COL_SOLAR_CORE, COL_SOLAR_GOLD, 3.5, 0.9, false)
	_mark_shell_mat = _glow(COL_CRIT_CRIMSON, COL_CRIT_DEEP, 3.2, 0.42, true)
	_mark_core = _mi(_line_core_mesh, _mark_core_mat, "SightlineCore")
	_mark_shell = _mi(_line_shell_mesh, _mark_shell_mat, "SightlineShell")
	_root.add_child(_mark_core)
	_root.add_child(_mark_shell)

	_reticle_root = Node3D.new()
	_reticle_root.name = "WeakPointReticle"
	_reticle_mat = _glow(COL_CRIT_CRIMSON, COL_SOLAR_GOLD, 3.2, 0.9, false, true)
	_reticle_ring = _mi(_reticle_ring_mesh, _reticle_mat, "ReticleRing")
	_reticle_root.add_child(_reticle_ring)
	for w in range(4):
		var holder := Node3D.new()
		holder.name = "Wedge%d" % w
		var wedge := _mi(_wedge_mesh, _reticle_mat, "WedgeMesh")
		holder.add_child(wedge)
		_reticle_root.add_child(holder)
		_reticle_wedges.append(holder)
	_root.add_child(_reticle_root)


func _build_crown() -> void:
	_crown_root = Node3D.new()
	_crown_root.name = "PrismaticCrown3D"
	_crown_solid_inner = _glow(COL_SOLAR_GOLD, COL_SOLAR_CORE, 2.8, 0.9, false)
	_crown_solid_outer = _glow(COL_CRIT_CRIMSON, COL_SOLAR_GOLD, 3.2, 0.9, false)
	_crown_edge = _glow(COL_SOLAR_CORE, COL_SOLAR_GOLD, 3.2, 1.0, true)
	for i in range(CROWN_BLADES):
		var holder := Node3D.new()
		holder.name = "Blade%d" % i
		var outer := i % 2 == 1
		var solid := _mi(_crown_blade_outer_mesh if outer else _crown_blade_inner_mesh,
			_crown_solid_outer if outer else _crown_solid_inner, "Solid")
		holder.add_child(solid)
		var edge := _mi(_crown_edge_outer_mesh if outer else _crown_edge_inner_mesh, _crown_edge, "Edge")
		holder.add_child(edge)
		_crown_root.add_child(holder)
		_crown_blades.append(holder)
	_root.add_child(_crown_root)


func _build_ghosts_and_beam() -> void:
	for k in range(GHOST_COUNT):
		var late := k >= 3
		var mat := _glow(COL_CRIT_CRIMSON if late else COL_SOLAR_CORE,
			COL_CRIT_DEEP if late else COL_SOLAR_GOLD, 2.0, 0.36, true)
		mat.render_priority = 1
		_ghost_mats.append(mat)
		var mi := _mi(_ghost_mesh, mat, "Ghost%d" % (k + 1))
		mi.visible = false
		_root.add_child(mi)
		_ghost_nodes.append(mi)

	_beam_mat = _glow(COL_SOLAR_CORE, COL_CRIT_CRIMSON, 2.8, 0.30, true)
	_beam = _mi(_beam_mesh, _beam_mat, "PiercingBeam")
	_beam.visible = false
	_root.add_child(_beam)


func _build_impact() -> void:
	_cross_mat = _glow(COL_SOLAR_CORE, COL_CRIT_CRIMSON, 3.2, 0.95, false, true)
	_cross_mat.render_priority = 3
	_cross_edge_mat = _glow(COL_SOLAR_CORE, COL_SOLAR_GOLD, 2.8, 0.75, false, true)
	for i in range(3):
		var blade := _mi(_diamond_mesh, _cross_mat, "CrossBlade%d" % i)
		var edge := _mi(_diamond_wire_mesh, _cross_edge_mat, "CrossEdge")
		blade.add_child(edge)
		blade.visible = false
		_root.add_child(blade)
		_cross_blades.append(blade)

	_flash_inner_mat = _glow(COL_SOLAR_CORE, COL_SOLAR_GOLD, 4.5, 0.9, false)
	_flash_outer_mat = _glow(COL_CRIT_CRIMSON, COL_CRIT_DEEP, 3.2, 0.62, true)
	_flash_inner = _mi(_flash_inner_mesh, _flash_inner_mat, "CritFlashCore")
	_flash_outer = _mi(_flash_outer_mesh, _flash_outer_mat, "CritFlashShell")
	_flash_inner.visible = false
	_flash_outer.visible = false
	_root.add_child(_flash_inner)
	_root.add_child(_flash_outer)

	_delayed_ring_mat = _glow(COL_SOLAR_GOLD, COL_CRIT_CRIMSON, 3.2, 0.9, true)
	_delayed_ring = _mi(_delayed_ring_mesh, _delayed_ring_mat, "DelayedRing")
	_delayed_ring.visible = false
	_root.add_child(_delayed_ring)

	_ground_ring_mat = _glow(COL_AMBER_PULSE, COL_AMBER_GLOW, 2.5, 0.78, false)
	_ground_ring = _mi(_ground_ring_mesh, _ground_ring_mat, "GroundRing")
	_ground_ring.visible = false
	_root.add_child(_ground_ring)

	# HTML (Card C): 8 contained 3D earth/rock spikes that erupt around the ground ring.
	_spike_mat = _glow(COL_AMBER_PULSE, COL_AMBER_GLOW, 2.5, 0.75, false)
	for i in range(8):
		var holder := Node3D.new()
		holder.name = "GroundSpike%d" % i
		var spike := _mi(_spike_mesh, _spike_mat, "SpikeMesh")
		spike.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
		holder.add_child(spike)
		holder.visible = false
		_root.add_child(holder)
		_ground_spikes.append(holder)
		_spike_meshes.append(spike)

	_debris_mat = _glow(COL_AMBER_PULSE, COL_AMBER_GLOW, 2.5, 0.9, false)
	for d in range(DEBRIS_COUNT):
		var node := _mi(_rock_mesh, _debris_mat, "Debris%d" % d)
		node.visible = false
		_root.add_child(node)
		_debris.append(node)
		var ang := float(d) * TAU / float(DEBRIS_COUNT) + 0.3
		var h := 1.6 + float(d % 3) * 0.55
		var v := 2.2 + float(d % 4) * 0.45
		_debris_dirs.append(Vector3(cos(ang) * h, v, sin(ang) * h))

	_spark_mat = _glow(COL_SOLAR_CORE, COL_CRIT_CRIMSON, 3.2, 0.95, true)
	for s in range(SPARK_COUNT):
		var node2 := _mi(_spark_mesh, _spark_mat, "Spark%d" % s)
		node2.visible = false
		_root.add_child(node2)
		_sparks.append(node2)
		var ang2 := float(s) * TAU / float(SPARK_COUNT)
		var spread := 0.25 + float(s % 3) * 0.18
		_spark_dirs.append(Vector3(cos(ang2) * spread, sin(ang2) * spread, 1.0).normalized())


func _build_ghost_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var xforms := [
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -0.15)),
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -0.05)),
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 0.58)),
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 0.58)),
	]
	var meshes := [_shaft_mesh, _grip_mesh, _collar_mesh, _collar_ring_mesh]
	for i in range(meshes.size()):
		var mesh: ArrayMesh = meshes[i]
		for s in range(mesh.get_surface_count()):
			st.append_from(mesh, s, xforms[i])
	# anéis dourados da haste + faixas da empunhadura (silhueta completa)
	for z in [-0.60, -0.15, 0.30]:
		for s_ring in range(_gold_ring_mesh.get_surface_count()):
			st.append_from(_gold_ring_mesh, s_ring, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, z)))
	for z in [-0.22, 0.12]:
		for s_band in range(_gold_ring_mesh.get_surface_count()):
			st.append_from(_gold_ring_mesh, s_band, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, z)))
	# 3 penas
	for f in range(3):
		var ang := float(f) * TAU / 3.0
		var b := Basis(Vector3.FORWARD, ang - PI * 0.5)
		var xf := Transform3D(b, Vector3(cos(ang) * 0.032, sin(ang) * 0.032, -0.78))
		for s2 in range(_fin_mesh.get_surface_count()):
			st.append_from(_fin_mesh, s2, xf)
	# ponta
	for s3 in range(_tip_mesh.get_surface_count()):
		st.append_from(_tip_mesh, s3, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 0.58)))
	return st.commit()


func _piece_set_scale(piece: Node3D, s: float) -> void:
	piece.scale = Vector3.ONE * s


func _piece_set_alpha(i: int, a: float) -> void:
	for m in _piece_mats[i]:
		(m as ShaderMaterial).set_shader_parameter("alpha", a)


# ============================================================================
# GEOMETRIA (SurfaceTool; normais planas por face)
# ============================================================================

func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 0.0000001:
		return
	n = n.normalized()
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)


func _mesh_cylinder_z(top_r: float, bottom_r: float, length: float, segs: int, caps := true) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := length * 0.5
	for i in range(segs):
		var a0 := float(i) * TAU / float(segs)
		var a1 := float(i + 1) * TAU / float(segs)
		var p0t := Vector3(cos(a0) * top_r, sin(a0) * top_r, h)
		var p1t := Vector3(cos(a1) * top_r, sin(a1) * top_r, h)
		var p0b := Vector3(cos(a0) * bottom_r, sin(a0) * bottom_r, -h)
		var p1b := Vector3(cos(a1) * bottom_r, sin(a1) * bottom_r, -h)
		_add_tri(st, p0t, p0b, p1b)
		_add_tri(st, p0t, p1b, p1t)
	if caps:
		for i in range(segs):
			var a0 := float(i) * TAU / float(segs)
			var a1 := float(i + 1) * TAU / float(segs)
			var p0t := Vector3(cos(a0) * top_r, sin(a0) * top_r, h)
			var p1t := Vector3(cos(a1) * top_r, sin(a1) * top_r, h)
			var p0b := Vector3(cos(a0) * bottom_r, sin(a0) * bottom_r, -h)
			var p1b := Vector3(cos(a1) * bottom_r, sin(a1) * bottom_r, -h)
			_add_tri(st, Vector3(0, 0, h), p0t, p1t)
			_add_tri(st, Vector3(0, 0, -h), p1b, p0b)
	return st.commit()


func _mesh_pyramid4(length: float, base_r: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var apex := Vector3(0.0, 0.0, length)
	var base := [
		Vector3(base_r, 0.0, 0.0),
		Vector3(0.0, base_r, 0.0),
		Vector3(-base_r, 0.0, 0.0),
		Vector3(0.0, -base_r, 0.0),
	]
	for i in range(4):
		var nxt := (i + 1) % 4
		_add_tri(st, apex, base[i], base[nxt])
	_add_tri(st, base[0], base[2], base[1])
	_add_tri(st, base[0], base[3], base[2])
	return st.commit()


func _mesh_pyramid4_wire(length: float, base_r: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	var apex := Vector3(0.0, 0.0, length)
	var base := [
		Vector3(base_r, 0.0, 0.0),
		Vector3(0.0, base_r, 0.0),
		Vector3(-base_r, 0.0, 0.0),
		Vector3(0.0, -base_r, 0.0),
	]
	for i in range(4):
		var nxt := (i + 1) % 4
		st.add_vertex(apex)
		st.add_vertex(base[i])
		st.add_vertex(base[i])
		st.add_vertex(base[nxt])
	return st.commit()


func _mesh_prism_blade(length: float, base_r: float, tip_r: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top = []
	var bot = []
	for i in range(3):
		var a := float(i) * TAU / 3.0 + PI * 0.5
		top.append(Vector3(cos(a) * tip_r, sin(a) * tip_r, 0.0))
		bot.append(Vector3(cos(a) * base_r, sin(a) * base_r, -length))
	for i in range(3):
		var nxt := (i + 1) % 3
		_add_tri(st, top[i], bot[i], bot[nxt])
		_add_tri(st, top[i], bot[nxt], top[nxt])
	_add_tri(st, top[0], top[1], top[2])
	_add_tri(st, bot[0], bot[2], bot[1])
	return st.commit()


func _mesh_prism_wire(length: float, base_r: float, tip_r: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	var top = []
	var bot = []
	for i in range(3):
		var a := float(i) * TAU / 3.0 + PI * 0.5
		top.append(Vector3(cos(a) * tip_r, sin(a) * tip_r, 0.0))
		bot.append(Vector3(cos(a) * base_r, sin(a) * base_r, -length))
	for i in range(3):
		var nxt := (i + 1) % 3
		st.add_vertex(top[i])
		st.add_vertex(bot[i])
		st.add_vertex(top[i])
		st.add_vertex(top[nxt])
		st.add_vertex(bot[i])
		st.add_vertex(bot[nxt])
	return st.commit()


func _mesh_diamond(length: float, width: float, sides: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hz := length * 0.5
	var hw := width * 0.5
	var top := Vector3(0.0, 0.0, hz)
	var bot := Vector3(0.0, 0.0, -hz)
	var ring = []
	for i in range(sides):
		var a := float(i) * TAU / float(sides) + PI * 0.25
		ring.append(Vector3(cos(a) * hw, sin(a) * hw, 0.0))
	for i in range(sides):
		var nxt := (i + 1) % sides
		_add_tri(st, top, ring[i], ring[nxt])
		_add_tri(st, bot, ring[nxt], ring[i])
	return st.commit()


func _mesh_octahedron(diameter: float) -> ArrayMesh:
	return _mesh_diamond(diameter, diameter, 4)


func _mesh_diamond_wire(length: float, width: float, sides: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	var hz := length * 0.5
	var hw := width * 0.5
	var top := Vector3(0.0, 0.0, hz)
	var bot := Vector3(0.0, 0.0, -hz)
	var ring := []
	for i in range(sides):
		var a := float(i) * TAU / float(sides) + PI * 0.25
		ring.append(Vector3(cos(a) * hw, sin(a) * hw, 0.0))
	for i in range(sides):
		var nxt := (i + 1) % sides
		st.add_vertex(top)
		st.add_vertex(ring[i])
		st.add_vertex(bot)
		st.add_vertex(ring[i])
		st.add_vertex(ring[i])
		st.add_vertex(ring[nxt])
	return st.commit()


func _mesh_torus(inner_r: float, outer_r: float, rings: int, segs: int, flat_xz: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tube := (outer_r - inner_r) * 0.5
	var center := inner_r + tube
	for i in range(rings):
		var u0 := float(i) * TAU / float(rings)
		var u1 := float(i + 1) * TAU / float(rings)
		for j in range(segs):
			var v0 := float(j) * TAU / float(segs)
			var v1 := float(j + 1) * TAU / float(segs)
			var p00 := _torus_pt(u0, v0, center, tube, flat_xz)
			var p10 := _torus_pt(u1, v0, center, tube, flat_xz)
			var p01 := _torus_pt(u0, v1, center, tube, flat_xz)
			var p11 := _torus_pt(u1, v1, center, tube, flat_xz)
			_add_tri(st, p00, p10, p11)
			_add_tri(st, p00, p11, p01)
	return st.commit()


func _torus_pt(u: float, v: float, c: float, t: float, flat_xz: bool) -> Vector3:
	var r := c + cos(v) * t
	if flat_xz:
		return Vector3(cos(u) * r, sin(v) * t, sin(u) * r)
	return Vector3(cos(u) * r, sin(u) * r, sin(v) * t)


func _mesh_fin(thickness: float, height: float, length: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := [
		Vector2(0.0, 0.0),
		Vector2(height, -0.03),
		Vector2(height * 0.90, -length * 0.86),
		Vector2(0.0, -length),
	]
	var hx := thickness * 0.5
	for side in [-1.0, 1.0]:
		var x: float = hx * side
		for i in range(1, 3):
			var a := Vector3(x, pts[0].x, pts[0].y)
			var b := Vector3(x, pts[i].x, pts[i].y)
			var c := Vector3(x, pts[i + 1].x, pts[i + 1].y)
			if side > 0.0:
				_add_tri(st, a, b, c)
			else:
				_add_tri(st, a, c, b)
	# bordas
	for i in range(4):
		var nxt := (i + 1) % 4
		var a0 := Vector3(-hx, pts[i].x, pts[i].y)
		var a1 := Vector3(hx, pts[i].x, pts[i].y)
		var b0 := Vector3(-hx, pts[nxt].x, pts[nxt].y)
		var b1 := Vector3(hx, pts[nxt].x, pts[nxt].y)
		_add_tri(st, a0, a1, b1)
		_add_tri(st, a0, b1, b0)
	return st.commit()


func _mesh_icosahedron(radius: float) -> ArrayMesh:
	var t := (1.0 + sqrt(5.0)) * 0.5
	var v := [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
	]
	var faces := [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
	]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var norm := v.map(func(p): return p.normalized() * radius)
	for f in faces:
		_add_tri(st, norm[f[0]], norm[f[1]], norm[f[2]])
	return st.commit()
