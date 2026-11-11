class_name JavelinThrowVfxHtml
extends Node3D
## Porte literal do VFX "Javelin Throw" do HTML Card C ("Lança do Ponto Fraco").
##
## Fonte visual oficial: D-1171. A geometria, os materiais, os tempos e o update
## seguem `buildFusionACVFX` / `updateFusionAC` do protótipo, não os números do
## prompt antigo. Regras: D-235 (âncoras reais), D-308 (fases), D-019/D-1040
## (esta classe não tem relógio de batalha), D-1103 (nada de regra de dano).
##
## `view_scale` é a única adaptação de batalha (D-1033): no laboratório de
## paridade ele é 1.0, então todos os números abaixo são os do HTML.

const WINDUP_END := 0.75
const RELEASE_FOLLOW := 0.90
const TRAJECTORY_END := 1.05
const PRISM_END := 1.10
const TOTAL_DURATION := 1.85

const TIP_LOCAL_Z := 1.30
const BLADE_LENGTH := 0.52
const GHOST_COUNT := 7
const CROWN_COUNT := 7
const DEBRIS_COUNT := 10
const SPARK_COUNT := 8

# D-1175: haste mais longa (2,30 m) e subida do wind-up.
# O comprimento total passa de 2,245 m para 2,695 m (ponta 1,30 / cauda -1,395).
const SHAFT_LENGTH := 2.30
const SHAFT_CENTER_Z := -0.245
const SHAFT_TAIL_Z := -1.395
const FIN_GROUP_Z := -1.12
const WINDUP_RAISE_FIXED := 0.08
const WINDUP_RAISE_AUTO_MAX := 0.12
const WINDUP_RAISE_MARGIN := 0.03

# D-1176: passagem perfurante (não trava no alvo).
const PASS_THROUGH_TIME := 0.45
const PASS_THROUGH_DISTANCE := 2.6

# FUSION_CONFIGS.C
const SHAFT_THICKNESS := 0.86
const SHAFT_COLOR := Color("#FEF9C3")
const GRIP_COLOR := Color("#451A03")
const COLLAR_COLOR := Color("#FF5555")
const COLLAR_EMISSIVE := Color("#991B1B")
const FIN_COLOR := Color("#FFFFFF")
const FIN_EMISSIVE := Color("#FEF08A")
const TIP_WIDTH_SCALE := 0.9
const TIP_COLOR := Color("#FFFFFF")
const TIP_EMISSIVE := Color("#FEF08A")
const STAR_COLOR := Color("#FFFFFF")
const STAR_SCALE := 1.32
const PULSE_COLOR := Color("#FEF08A")
const SIGHT_BEAM_RADIUS := 0.020
const SIGHT_COLOR := Color("#FF3B3B")
const SIGHT_INTENSITY := 1.25
const ASSEMBLY_SPEED := 1.15
const PRISM_LENGTH_SCALE := 0.96
const PRISM_WIDTH_SCALE := 0.94
const PRISM_INNER_COLOR := Color("#FEF08A")
const PRISM_INNER_EMISSIVE := Color("#F59E0B")
const PRISM_OUTER_COLOR := Color("#FF5555")
const PRISM_OUTER_EMISSIVE := Color("#DC2626")
const GHOST_COLOR_MAIN := Color("#FEF08A")
const GHOST_COLOR_ALT := Color("#FF5555")
const ARC_HEIGHT_FACTOR := 0.024
const FLIGHT_EXPONENT := 0.58
const GROUND_SHOCK_SCALE := 0.85
const CROSS_SCALE := 1.28
const CROSS_COLOR := Color("#FF5555")
const CROSS_EDGE_COLOR := Color("#FFFFFF")
const FLASH_COLOR_WARM := Color("#FEF08A")
const FLASH_COLOR_RED := Color("#FF3B3B")

var _camera: Camera3D
var _built := false
var _master_alpha := 1.0

var _hand := Vector3.ZERO
var _chest := Vector3.ZERO
var _feet := Vector3.ZERO
var _axis := Vector3(0.0, 0.0, 1.0)
var _distance := 1.0
var _target_radius := 0.5
var _view_scale := 1.0
var _target_view_scale := 1.0
var _attacker_body_box := AABB()
var _windup_raise := 0.0

var _root: Node3D
var _javelin_group: Node3D
var _part_shaft: MeshInstance3D
var _grip_group: Node3D
var _collar_group: Node3D
var _feathers_group: Node3D
var _tip_group: Node3D
var _tip_star_group: Node3D
var _star_spike_mat: StandardMaterial3D
var _star_core_mat: StandardMaterial3D
var _pulse_group: Node3D
var _pulse_mat: StandardMaterial3D
var _pulse_sleeve_mat: StandardMaterial3D
var _spearhead_mat: StandardMaterial3D

var _sightline_group: Node3D
var _sight_beam: MeshInstance3D
var _sight_beam_mat: StandardMaterial3D
var _reticle_holder: Node3D
var _ret_outer_mat: StandardMaterial3D
var _ret_inner_mat: StandardMaterial3D
var _ret_inner_mesh: MeshInstance3D

var _prism_crown_group: Node3D
var _inner_blades: Array = []
var _outer_blades: Array = []
var _prism_mat_inner: StandardMaterial3D
var _prism_mat_outer: StandardMaterial3D
var _prism_edge_mat: StandardMaterial3D

var _after_images: Array = []
var _pierce_beam: MeshInstance3D
var _pierce_beam_mat: StandardMaterial3D

var _ground_impact_group: Node3D
var _shock_torus: MeshInstance3D
var _shock_torus_mat: StandardMaterial3D
var _ground_spikes: Array = []
var _spike_mat: StandardMaterial3D
var _dust_blocks: Array = []
var _dust_mat: StandardMaterial3D

var _chest_impact_group: Node3D
var _cross1: MeshInstance3D
var _cross2: MeshInstance3D
var _cross3: MeshInstance3D
var _cross_mat: StandardMaterial3D
var _cross_edge_mat: StandardMaterial3D
var _crit_flash: MeshInstance3D
var _crit_flash_mat: StandardMaterial3D
var _delayed_ring1: MeshInstance3D
var _delayed_ring2: MeshInstance3D
var _delayed_ring_mat: StandardMaterial3D
var _delayed_ring_mat2: StandardMaterial3D
var _crit_sparks: Array = []
var _spark_mat: StandardMaterial3D

var _tip_emission := 0.4
var _star_visible := false
var _crown_visible := false
var _beam_visible := false
var _reticle_visible := false
var _cross_visible := false
var _spike0_visible := false
var _last_dt_impact := -1.0


func setup(camera: Camera3D) -> void:
	_camera = camera
	if not _built:
		_build()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	if not _built:
		_build()


## Chaves aceitas: stage ("windup"|"flight"|"impact"|"miss"|"done"),
## hand/chest/feet/axis/distance/target_radius/view_scale, windup_t,
## flight_u, release_t, since_impact, impact_chest, miss_t, master_alpha.
func draw(p: Dictionary) -> void:
	if not _built:
		_build()
	_read_state(p)
	_master_alpha = clampf(float(p.get("master_alpha", 1.0)), 0.0, 1.0)
	var stage := String(p.get("stage", "done"))
	if stage == "done" or _master_alpha <= 0.001:
		_hide_all()
		return

	_javelin_group.visible = true
	_reset_frame()

	var basis := compute_orthonormal_basis(_axis)
	var windup_t := clampf(float(p.get("windup_t", 0.0)), 0.0, WINDUP_END)
	var flight_u := clampf(float(p.get("flight_u", 0.0)), 0.0, 1.0)
	var release_t := float(p.get("release_t", -1.0))
	var since_impact := float(p.get("since_impact", -1.0))
	var miss_t := maxf(float(p.get("miss_t", 0.0)), 0.0)
	var impact_chest: Vector3 = p.get("impact_chest", _chest)

	if stage == "windup":
		if windup_t < WINDUP_END:
			_update_windup(windup_t, basis)
		else:
			_update_release(0.0, 0.0, basis, false, -1.0)
	elif stage == "flight":
		var dt_release := maxf(release_t, 0.0)
		_update_release(dt_release, flight_u, basis, false, -1.0)
	elif stage == "impact":
		var dt_rel := maxf(release_t, 0.0)
		_update_release(dt_rel, 1.0, basis, true, maxf(since_impact, 0.0), impact_chest)
	elif stage == "miss":
		_update_miss(miss_t, basis)


func _read_state(p: Dictionary) -> void:
	_hand = p.get("hand", Vector3.ZERO)
	_chest = p.get("chest", Vector3.ZERO)
	var feet_in: Variant = p.get("feet", null)
	if feet_in == null:
		_feet = Vector3(_chest.x, 0.0, _chest.z)
	else:
		_feet = feet_in
	var axis_in: Vector3 = p.get("axis", _chest - _hand)
	if axis_in.length_squared() < 1e-8:
		axis_in = Vector3(0.0, 0.0, 1.0)
	_axis = axis_in.normalized()
	_distance = maxf(float(p.get("distance", _hand.distance_to(_chest))), 0.001)
	_target_radius = maxf(float(p.get("target_radius", 0.5)), 0.05)
	_view_scale = clampf(float(p.get("view_scale", 1.0)), 0.25, 4.0)
	_target_view_scale = clampf(float(p.get("target_view_scale", _view_scale)), 0.25, 4.0)
	var body_box_in: Variant = p.get("attacker_body_box", AABB())
	if body_box_in is AABB:
		_attacker_body_box = body_box_in
	else:
		_attacker_body_box = AABB()
	_windup_raise = _compute_windup_raise()


## D-1175: sobe a javelin no wind-up com um pequeno fixo + folga automática
## calculada contra o corpo real do atacante. Sem body box (laboratório de
## paridade HTML), a subida é zero para manter o A/B original.
func _compute_windup_raise() -> float:
	if _attacker_body_box.size.length() < 0.01 or _attacker_body_box.size.y < 0.1:
		return 0.0
	var b := _attacker_body_box
	var core_pos := b.position + Vector3(b.size.x * 0.15, b.size.y * 0.15, b.size.z * 0.15)
	var core_size := Vector3(b.size.x * 0.7, b.size.y * 0.85, b.size.z * 0.7)
	var core_end := core_pos + core_size
	var tail := _hand - _axis * (absf(SHAFT_TAIL_Z) * _view_scale)
	var need := 0.0
	for i in range(11):
		var sample := _hand.lerp(tail, float(i) / 10.0)
		if sample.x >= core_pos.x and sample.x <= core_end.x \
				and sample.z >= core_pos.z and sample.z <= core_end.z \
				and sample.y >= core_pos.y and sample.y <= core_end.y:
			need = maxf(need, core_end.y + WINDUP_RAISE_MARGIN - sample.y)
	return WINDUP_RAISE_FIXED + minf(need, WINDUP_RAISE_AUTO_MAX)


## D-1176: ponta real da javelin (ápice do spearhead), para o Dread seguir.
func javelin_tip() -> Vector3:
	if not _built or _javelin_group == null:
		return _chest
	return _javelin_group.to_global(Vector3(0.0, 0.0, TIP_LOCAL_Z))


func debug_state() -> Dictionary:
	if not _built:
		return {}
	return {		"hand": _hand,
		"chest": _chest,
		"axis": _axis,
		"tip": _javelin_group.to_global(Vector3(0.0, 0.0, TIP_LOCAL_Z)),
		"tail": _javelin_group.to_global(Vector3(0.0, 0.0, SHAFT_TAIL_Z)),
		"basis_z": _javelin_group.global_transform.basis.z,
		"spear_visible": _javelin_group.visible,
		"piece0_visible": _part_shaft.visible,
		"piece4_visible": _tip_group.visible,
		"piece0_alpha": _mat_alpha(_part_shaft.material_override),
		"piece4_alpha": _mat_alpha(_tip_group.get_child(0).material_override if _tip_group.get_child_count() > 0 else null),
		"tip_emission": _spearhead_mat.emission_energy_multiplier if _spearhead_mat != null else -1.0,
		"star_visible": _star_visible,
		"crown_visible": _crown_visible,
		"beam_visible": _beam_visible,
		"reticle_visible": _reticle_visible,
		"reticle_ring_scale": _reticle_holder.scale.x if _reticle_holder != null else 0.0,
		"flash_outer_scale": _crit_flash.scale.x if _crit_flash != null else 0.0,
		"flash_outer_radius": _crit_flash.scale.x if _crit_flash != null else 0.0,
		"flash_inner_radius": 0.0,
		"spike0_visible": _spike0_visible,
		"cross_vis": _cross_visible,
		"cross_pos": _cross1.global_position if _cross1 != null else Vector3.ZERO,
		"cross_scale": _cross1.scale if _cross1 != null else Vector3.ZERO,
		"cross_alpha": _cross_mat.albedo_color.a if _cross_mat != null else -1.0,
	}


func _mat_alpha(m: Material) -> float:
	if m is StandardMaterial3D:
		return (m as StandardMaterial3D).albedo_color.a
	return -1.0


func _reset_frame() -> void:
	_sightline_group.visible = false
	_prism_crown_group.visible = false
	_pierce_beam.visible = false
	_ground_impact_group.visible = false
	_chest_impact_group.visible = false
	_pulse_group.visible = false
	_tip_star_group.visible = false
	_star_visible = false
	_crown_visible = false
	_beam_visible = false
	_reticle_visible = false
	_cross_visible = false
	_spike0_visible = false
	_star_spike_mat.albedo_color.a = 0.0
	_star_core_mat.albedo_color.a = 0.0
	for gi in _after_images:
		(gi["group"] as Node3D).visible = false


func _hide_all() -> void:
	_javelin_group.visible = false
	_reset_frame()


func _update_windup(t: float, basis: Basis) -> void:
	var w := t / WINDUP_END
	var drawback := smoothstep(0.12, 0.74, w) * 0.36
	var current_grip := _hand - _axis * (drawback * _view_scale) + Vector3.UP * _windup_raise
	_javelin_group.global_transform = Transform3D(
		basis * Basis.from_scale(Vector3.ONE * _view_scale), current_grip)

	var spd := ASSEMBLY_SPEED
	var p1 := ease_out_back(clampf((t * spd) / 0.16, 0.0, 1.0))
	_part_shaft.visible = t >= 0.0
	_part_shaft.position = Vector3((1.0 - p1) * 0.45, (1.0 - p1) * 0.35, SHAFT_CENTER_Z - (1.0 - p1) * 0.5)
	_part_shaft.rotation = Vector3((1.0 - p1) * 0.9, (1.0 - p1) * -0.7, 0.0)
	_part_shaft.scale = Vector3.ONE * clampf((t * spd) / 0.08, 0.001, 1.0)

	var p2 := ease_out_back(clampf(((t - 0.11) * spd) / 0.16, 0.0, 1.0))
	_grip_group.visible = t >= 0.11
	_grip_group.position = Vector3((1.0 - p2) * -0.45, (1.0 - p2) * 0.3, (1.0 - p2) * -0.3)
	_grip_group.rotation = Vector3(0.0, 0.0, (1.0 - p2) * PI * 1.5)
	_grip_group.scale = Vector3.ONE * clampf(((t - 0.11) * spd) / 0.08, 0.001, 1.0)

	var p3 := ease_out_back(clampf(((t - 0.22) * spd) / 0.16, 0.0, 1.0))
	_collar_group.visible = t >= 0.22
	_collar_group.position = Vector3(0.0, (1.0 - p3) * 0.42, 0.42 + (1.0 - p3) * 0.55)
	_collar_group.rotation = Vector3((1.0 - p3) * 0.8, 0.0, (1.0 - p3) * -1.2)
	_collar_group.scale = Vector3.ONE * clampf(((t - 0.22) * spd) / 0.08, 0.001, 1.0)

	var p4 := ease_out_back(clampf(((t - 0.33) * spd) / 0.16, 0.0, 1.0))
	_feathers_group.visible = t >= 0.33
	_feathers_group.position = Vector3((1.0 - p4) * 0.35, (1.0 - p4) * -0.35, FIN_GROUP_Z - (1.0 - p4) * 0.55)
	_feathers_group.rotation = Vector3(0.0, 0.0, (1.0 - p4) * 1.8)
	_feathers_group.scale = Vector3.ONE * clampf(((t - 0.33) * spd) / 0.08, 0.001, 1.0)

	var p5 := ease_out_back(clampf(((t - 0.44) * spd) / 0.14, 0.0, 1.0))
	_tip_group.visible = t >= 0.44
	_tip_group.position = Vector3((1.0 - p5) * 0.28, (1.0 - p5) * 0.48, 0.78 + (1.0 - p5) * 0.75)
	_tip_group.rotation = Vector3((1.0 - p5) * -0.95, (1.0 - p5) * 0.65, (1.0 - p5) * PI)
	_tip_group.scale = Vector3.ONE * clampf(((t - 0.44) * spd) / 0.07, 0.001, 1.0)

	# Mira 3D: beam do grip até o chest + retículo octaédrico duplo.
	_sightline_group.visible = true
	var beam_origin := current_grip + _axis * (0.45 * _view_scale)
	var beam_dir := (_chest - beam_origin)
	var beam_dist := maxf(beam_dir.length(), 0.1)
	beam_dir = beam_dir / beam_dist
	var beam_basis := compute_orthonormal_basis(beam_dir)
	_sight_beam.global_transform = Transform3D(
		beam_basis * Basis.from_scale(Vector3(_view_scale, _view_scale, beam_dist)),
		beam_origin)
	_sight_beam_mat.albedo_color.a = clampf(
		(0.25 + 0.65 * smoothstep(0.15, 0.72, w)) * SIGHT_INTENSITY, 0.0, 1.0) * _master_alpha
	_reticle_holder.global_transform = Transform3D(Basis.IDENTITY, _chest)
	_reticle_holder.rotation = Vector3(t * 2.8, t * 3.6, t * 1.5)
	var lock_scale := lerpf(1.85, 0.78, ease_out_cubic(w)) * (_target_radius / 0.5) * _target_view_scale
	_reticle_holder.scale = Vector3.ONE * lock_scale
	_ret_inner_mesh.visible = true
	_ret_outer_mat.albedo_color.a = 0.95 * _master_alpha
	_ret_inner_mat.albedo_color.a = 0.85 * _master_alpha
	_reticle_visible = true

	_spearhead_mat.emission_energy_multiplier = 0.4
	if t >= 0.56:
		var u_pulse := clampf((t - 0.56) / (0.75 - 0.56), 0.0, 1.0)
		_pulse_group.visible = true
		_pulse_group.position = Vector3(0.0, 0.0, lerpf(0.0, TIP_LOCAL_Z, ease_out_cubic(u_pulse)))
		var pulse_alpha := sin(u_pulse * PI * 0.85) + 0.35
		_pulse_mat.albedo_color.a = clampf(pulse_alpha * 0.92, 0.0, 1.0) * _master_alpha
		_pulse_sleeve_mat.albedo_color.a = clampf(pulse_alpha * 0.78, 0.0, 1.0) * _master_alpha
		_spearhead_mat.emission_energy_multiplier = 0.45 + u_pulse * 2.4

		var star_glow := smoothstep(0.0, 0.85, u_pulse)
		_star_spike_mat.albedo_color.a = star_glow * 0.96 * _master_alpha
		_star_core_mat.albedo_color.a = star_glow * _master_alpha
		_tip_star_group.scale = Vector3.ONE * ((0.45 + star_glow * 1.15) * STAR_SCALE)
		_tip_star_group.rotation.z = u_pulse * PI * 0.5
		_tip_star_group.visible = true
		_star_visible = true
	_tip_emission = _spearhead_mat.emission_energy_multiplier


func _lock_assembled_parts() -> void:
	_part_shaft.visible = true
	_part_shaft.position = Vector3(0.0, 0.0, SHAFT_CENTER_Z)
	_part_shaft.rotation = Vector3.ZERO
	_part_shaft.scale = Vector3.ONE
	_grip_group.visible = true
	_grip_group.position = Vector3.ZERO
	_grip_group.rotation = Vector3.ZERO
	_grip_group.scale = Vector3.ONE
	_collar_group.visible = true
	_collar_group.position = Vector3(0.0, 0.0, 0.42)
	_collar_group.rotation = Vector3.ZERO
	_collar_group.scale = Vector3.ONE
	_feathers_group.visible = true
	_feathers_group.position = Vector3(0.0, 0.0, FIN_GROUP_Z)
	_feathers_group.rotation = Vector3.ZERO
	_feathers_group.scale = Vector3.ONE
	_tip_group.visible = true
	_tip_group.position = Vector3(0.0, 0.0, 0.78)
	_tip_group.rotation = Vector3.ZERO
	_tip_group.scale = Vector3.ONE


func _arc_point(u: float) -> Vector3:
	var end_grip := _chest - _axis * (TIP_LOCAL_Z * 0.72 * _view_scale)
	var arc_peak := clampf(_distance * ARC_HEIGHT_FACTOR, 0.08, 0.72) * _view_scale
	var start := _hand + Vector3.UP * (_windup_raise * (1.0 - u))
	var p := start.lerp(end_grip, u)
	p.y += 4.0 * arc_peak * u * (1.0 - u)
	return p


func _update_release(dt_release: float, u_raw: float, basis: Basis, is_impact: bool,
		dt_impact: float, impact_chest := Vector3.ZERO) -> void:
	_lock_assembled_parts()
	var current_tangent := _axis
	var flight_basis := basis
	var u_flight := pow(clampf(u_raw, 0.0, 1.0), FLIGHT_EXPONENT)

	if not is_impact:
		var cur := _arc_point(u_flight)
		var nxt := _arc_point(clampf(u_flight + 0.015, 0.0, 1.0))
		if u_flight < 0.98:
			current_tangent = (nxt - cur).normalized()
		flight_basis = compute_orthonormal_basis(current_tangent)
		var jb := flight_basis * Basis(Vector3(0.0, 0.0, 1.0), u_raw * PI * 5.0)
		_javelin_group.global_transform = Transform3D(
			jb * Basis.from_scale(Vector3.ONE * _view_scale), cur)
		_spearhead_mat.emission_energy_multiplier = lerpf(2.4, 0.7, u_raw)
		_tip_emission = _spearhead_mat.emission_energy_multiplier

		_pierce_beam.visible = true
		_beam_visible = true
		_pierce_beam.global_transform = Transform3D(
			basis * Basis.from_scale(Vector3(
				_view_scale * (1.0 - u_raw * 0.65),
				_view_scale * (1.0 - u_raw * 0.65),
				_distance * u_flight)),
			_hand + Vector3.UP * _windup_raise)
		_pierce_beam_mat.albedo_color.a = (1.0 - u_raw * 0.75) * 0.82 * _master_alpha

		for idx in range(_after_images.size()):
			var gi: Dictionary = _after_images[idx]
			var frac := float(idx + 1) / float(_after_images.size() + 1)
			if u_flight >= frac * 0.88:
				var g_pos := _arc_point(frac)
				var g_next := _arc_point(clampf(frac + 0.015, 0.0, 1.0))
				var g_tan := (g_next - g_pos).normalized()
				var g_basis := compute_orthonormal_basis(g_tan)
				var gb := g_basis * Basis(Vector3(0.0, 0.0, 1.0), frac * PI * 3.0)
				var gnode: Node3D = gi["group"]
				gnode.visible = true
				gnode.global_transform = Transform3D(
					gb * Basis.from_scale(Vector3.ONE * _view_scale), g_pos)
				var fade_age := clampf((u_raw - frac * 0.55) / 0.65, 0.0, 1.0)
				var gmat: StandardMaterial3D = gi["mat"]
				gmat.albedo_color.a = (1.0 - fade_age) * 0.72 * _master_alpha
	else:
		var u_imp := clampf(dt_impact / (TOTAL_DURATION - TRAJECTORY_END), 0.0, 1.0)
		var shudder := exp(-dt_impact * 15.0) * sin(dt_impact * 80.0) * 0.055
		var contact_grip := _chest - _axis * (TIP_LOCAL_Z * 0.68 * _view_scale)
		if impact_chest != Vector3.ZERO:
			contact_grip = impact_chest - _axis * (TIP_LOCAL_Z * 0.68 * _view_scale)
		# D-1176: em vez de fincar, a javelin continua no eixo e atravessa o alvo.
		var pass_t := clampf(dt_impact / PASS_THROUGH_TIME, 0.0, 1.0)
		var pass_dist := PASS_THROUGH_DISTANCE * _view_scale * pass_t
		var pass_grip := contact_grip + _axis * pass_dist
		var jb2 := basis * Basis(Vector3(1.0, 0.0, 0.0), shudder)
		_javelin_group.global_transform = Transform3D(
			jb2 * Basis.from_scale(Vector3.ONE * _view_scale), pass_grip)
		_javelin_group.visible = dt_impact <= PASS_THROUGH_TIME
		_spearhead_mat.emission_energy_multiplier = lerpf(1.8, 0.25, u_imp)
		_tip_emission = _spearhead_mat.emission_energy_multiplier

		if dt_impact < 0.14:
			var linger := 1.0 - dt_impact / 0.14
			for idx in range(_after_images.size()):
				var gi2: Dictionary = _after_images[idx]
				var frac2 := float(idx + 1) / float(_after_images.size() + 1)
				var gnode2: Node3D = gi2["group"]
				gnode2.visible = true
				gnode2.global_transform = Transform3D(
					basis * Basis.from_scale(Vector3.ONE * _view_scale), _arc_point(frac2))
				var gmat2: StandardMaterial3D = gi2["mat"]
				gmat2.albedo_color.a = linger * 0.45 * (float(idx) / float(_after_images.size())) * _master_alpha

	# Coroa prismática: 7 internas + 7 externas, sem giro próprio.
	if dt_release <= 0.35:
		_prism_crown_group.visible = true
		_crown_visible = true
		var tip_now := _javelin_group.to_global(Vector3(0.0, 0.0, TIP_LOCAL_Z))
		var apex := tip_now
		if dt_release <= 0.15:
			var k_follow := dt_release / 0.15
			var recede := lerpf(0.0, 1.22, ease_out_cubic(k_follow)) * _view_scale
			apex = tip_now - current_tangent * recede
		else:
			var u_at15 := pow(0.15 / (TRAJECTORY_END - WINDUP_END), FLIGHT_EXPONENT)
			var grip_at15 := _arc_point(u_at15)
			var tip_at15 := grip_at15 + _axis * (TIP_LOCAL_Z * _view_scale)
			var k_after := (dt_release - 0.15) / 0.20
			var recede2 := 1.22 + lerpf(0.0, 1.15, ease_out_cubic(k_after))
			apex = tip_at15 - _axis * ((recede2 - k_after * 0.42) * _view_scale)

		var cam_roll := 0.0
		var to_cam := _camera_position() - apex
		if to_cam.length_squared() > 1e-8:
			to_cam = to_cam.normalized()
			var cam_x := to_cam.dot(flight_basis.x)
			var cam_y := to_cam.dot(flight_basis.y)
			cam_roll = atan2(cam_y, cam_x) + PI / 14.0
		var cb := flight_basis * Basis(Vector3(0.0, 0.0, 1.0), cam_roll)
		_prism_crown_group.global_transform = Transform3D(
			cb * Basis.from_scale(Vector3.ONE * _view_scale), apex)

		var open_progress := ease_out_cubic(clampf(dt_release / 0.35, 0.0, 1.0))
		var gap_inner := lerpf(0.015, 0.80 * PRISM_WIDTH_SCALE, open_progress)
		var gap_outer := lerpf(0.055, 1.05 * PRISM_WIDTH_SCALE, open_progress)
		var flare := lerpf(0.14, 0.56, open_progress)

		for i in range(_inner_blades.size()):
			var b: Dictionary = _inner_blades[i]
			var holder: Node3D = b["holder"]
			var mesh: MeshInstance3D = b["mesh"]
			var angle: float = b["angle"]
			holder.position = Vector3(cos(angle) * gap_inner, sin(angle) * gap_inner, 0.0)
			holder.rotation = Vector3(0.0, 0.0, angle - PI * 0.5)
			mesh.rotation = Vector3(flare, 0.0, 0.0)
		for i in range(_outer_blades.size()):
			var b2: Dictionary = _outer_blades[i]
			var holder2: Node3D = b2["holder"]
			var mesh2: MeshInstance3D = b2["mesh"]
			var angle2: float = b2["angle"]
			holder2.position = Vector3(cos(angle2) * gap_outer, sin(angle2) * gap_outer, -0.18 * open_progress)
			holder2.rotation = Vector3(0.0, 0.0, angle2 - PI * 0.5)
			mesh2.rotation = Vector3(flare * 1.22, 0.0, 0.0)

		var alpha_fade := 1.0
		if dt_release >= 0.16:
			alpha_fade = clampf(1.0 - (dt_release - 0.16) / (0.35 - 0.16), 0.0, 1.0)
		_prism_mat_inner.albedo_color.a = 0.92 * alpha_fade * _master_alpha
		_prism_mat_outer.albedo_color.a = 0.80 * alpha_fade * _master_alpha
		_prism_edge_mat.albedo_color.a = 0.98 * alpha_fade * _master_alpha
	else:
		_prism_crown_group.visible = false
		_crown_visible = false

	if is_impact:
		_update_impact(dt_impact, basis, impact_chest)


func _update_impact(dt_impact: float, basis: Basis, impact_chest: Vector3) -> void:
	_last_dt_impact = dt_impact
	var u_imp := clampf(dt_impact / (TOTAL_DURATION - TRAJECTORY_END), 0.0, 1.0)
	var body_scale := _target_radius / 0.5
	var chest := impact_chest if impact_chest != Vector3.ZERO else _chest

	# 1. Solo: anel, 8 espinhos, 10 blocos de poeira.
	_ground_impact_group.visible = true
	_ground_impact_group.global_transform = Transform3D(
		Basis.IDENTITY * Basis.from_scale(Vector3.ONE * _target_view_scale), _feet)
	var ground_expand := ease_out_cubic(u_imp) * 2.35 * GROUND_SHOCK_SCALE * body_scale
	_shock_torus.scale = Vector3(
		0.48 + ground_expand, 0.48 + ground_expand, lerpf(1.35, 0.32, u_imp))
	_shock_torus.position = Vector3(0.0, 0.08, 0.0)
	_shock_torus_mat.albedo_color.a = (1.0 - u_imp) * 0.92 * _master_alpha
	_spike_mat.albedo_color.a = clampf(1.2 - u_imp * 1.55, 0.0, 1.0) * _master_alpha
	for sp in _ground_spikes:
		var r := 0.32 + ground_expand * 0.76
		var angle: float = sp["angle"]
		var mesh: MeshInstance3D = sp["mesh"]
		mesh.position = Vector3(cos(angle) * r, 0.0, sin(angle) * r)
		mesh.rotation = Vector3(0.0, -angle + PI * 0.5, -0.52)
		var pop := sin(clampf(u_imp * 2.3, 0.0, 1.0) * PI)
		var sc := clampf(pop * 1.1 * body_scale, 0.001, 1.5)
		mesh.scale = Vector3.ONE * sc
	_spike0_visible = _ground_impact_group.visible and _ground_spikes[0]["mesh"].scale.x > 0.01

	_dust_mat.albedo_color.a = clampf((1.0 - u_imp) * 0.82, 0.0, 1.0) * _master_alpha
	for idx in range(_dust_blocks.size()):
		var d: Dictionary = _dust_blocks[idx]
		var mesh2: MeshInstance3D = d["mesh"]
		var angle2: float = d["angle"]
		var speed: float = d["speed"]
		var lift: float = d["lift"]
		var r2 := 0.24 + ease_out_cubic(u_imp) * 1.75 * speed * body_scale
		var py := 0.14 + sin(u_imp * PI) * lift + u_imp * 0.38
		mesh2.position = Vector3(cos(angle2) * r2, py, sin(angle2) * r2)
		mesh2.rotation = Vector3(u_imp * 3.0, float(idx), u_imp * 2.0)
		var s := (0.55 + sin(u_imp * PI) * 0.8) * (1.0 - u_imp * 0.45) * body_scale
		mesh2.scale = Vector3.ONE * maxf(0.01, s)

	# 2. Peito: cruz 5,94 m, flash octaédrico e anel atrasado.
	_chest_impact_group.visible = true
	_chest_impact_group.global_transform = Transform3D(
		basis * Basis.from_scale(Vector3.ONE * _target_view_scale), chest)

	var cross_stretch := ease_out_back(clampf(u_imp * 3.1, 0.0, 1.0)) * 1.38 * body_scale
	var cross_thin := clampf(1.0 - u_imp * 0.75, 0.15, 1.0)
	_cross1.visible = true
	_cross2.visible = true
	_cross3.visible = true
	_cross1.scale = Vector3(cross_thin, cross_stretch * 16.0, cross_thin)
	_cross2.scale = Vector3(cross_thin, cross_stretch * 16.0, cross_thin)
	_cross3.scale = Vector3(cross_thin, cross_stretch * 0.85 * 16.0, cross_thin)
	var cross_alpha := clampf((1.0 - u_imp * 1.22) * 1.1, 0.0, 1.0)
	_cross_mat.albedo_color.a = cross_alpha * _master_alpha
	_cross_edge_mat.albedo_color.a = cross_alpha * _master_alpha
	_cross_visible = true

	var flash_window := clampf(1.0 - dt_impact / 0.28, 0.0, 1.0)
	_crit_flash.visible = flash_window > 0.0
	if _crit_flash.visible:
		_crit_flash.scale = Vector3.ONE * ((0.48 + (1.0 - flash_window) * 1.65) * body_scale)
		_crit_flash_mat.albedo_color.a = flash_window * 0.86 * _master_alpha
		var flash_color := FLASH_COLOR_WARM if dt_impact < 0.09 else FLASH_COLOR_RED
		_crit_flash_mat.albedo_color = Color(flash_color.r, flash_color.g, flash_color.b,
			_crit_flash_mat.albedo_color.a)

	if dt_impact > 0.08:
		var u_ring1 := clampf((dt_impact - 0.08) / 0.48, 0.0, 1.0)
		_delayed_ring1.visible = true
		_delayed_ring1.scale = Vector3.ONE * ((0.35 + ease_out_cubic(u_ring1) * 2.25) * body_scale)
		_delayed_ring_mat.albedo_color.a = (1.0 - u_ring1) * 0.95 * _master_alpha
	else:
		_delayed_ring1.visible = false
	_delayed_ring2.visible = false

	_spark_mat.albedo_color.a = clampf(1.0 - u_imp * 1.35, 0.0, 1.0) * _master_alpha
	for i in range(_crit_sparks.size()):
		var s2: Dictionary = _crit_sparks[i]
		var mesh3: MeshInstance3D = s2["mesh"]
		var angle3: float = s2["angle"]
		var r3 := 0.25 + ease_out_cubic(u_imp) * 1.95 * body_scale
		var z_spread := (float(i % 3) - 1.0) * u_imp * 0.65
		mesh3.position = Vector3(cos(angle3) * r3, sin(angle3) * r3, z_spread)
		mesh3.rotation = Vector3(0.0, 0.0, angle3)


func _update_miss(miss_t: float, basis: Basis) -> void:
	_lock_assembled_parts()
	var end := _arc_point(1.0)
	var pos := end + _axis * (miss_t * 9.0 * _view_scale)
	_javelin_group.global_transform = Transform3D(
		basis * Basis.from_scale(Vector3.ONE * _view_scale), pos)
	_spearhead_mat.emission_energy_multiplier = 0.7
	_tip_emission = 0.7
	if miss_t >= 0.22:
		_javelin_group.visible = false
	var fade := 1.0 - clampf(miss_t / 0.22, 0.0, 1.0)
	# O HTML não tem "miss"; esta camada usa o mesmo dardo e some rápido.
	for gi in _after_images:
		var g: Node3D = gi["group"]
		g.visible = false
	


func compute_orthonormal_basis(direction: Vector3) -> Basis:
	var forward := direction.normalized()
	if forward.length_squared() < 1e-6:
		forward = Vector3(0.0, 0.0, 1.0)
	var dot := Vector3.UP.dot(forward)
	var up_ref: Vector3
	if absf(dot) > 0.999:
		up_ref = Vector3(0.0, 0.0, 1.0) - forward * dot
	else:
		up_ref = Vector3.UP - forward * dot
	up_ref = up_ref.normalized()
	var right := up_ref.cross(forward).normalized()
	var up := forward.cross(right).normalized()
	return Basis(right, up, forward)


func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t := clampf((x - edge0) / maxf(edge1 - edge0, 0.0000001), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


func ease_out_back(x: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	var p := clampf(x, 0.0, 1.0) - 1.0
	return 1.0 + c3 * pow(p, 3.0) + c1 * pow(p, 2.0)


func _camera_position() -> Vector3:
	if _camera != null and is_instance_valid(_camera):
		return _camera.global_position
	var vp := get_viewport()
	if vp != null:
		var c := vp.get_camera_3d()
		if c != null:
			return c.global_position
	return _chest + Vector3(0.0, 0.0, 1.0)


# ---------------------------------------------------------------------------
# Construção (buildFusionACVFX)
# ---------------------------------------------------------------------------


func _std_mat(color: Color, roughness: float, metallic: float, emission: Color,
		emission_energy: float, alpha: float, double_sided := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = roughness
	m.metallic = metallic
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = emission_energy
	if double_sided:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _basic_mat(color: Color, alpha := 1.0, double_sided := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if double_sided:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	return m


func _line_mat(color: Color, alpha := 1.0) -> StandardMaterial3D:
	return _basic_mat(color, alpha, true)


func _mi(mesh: Mesh, mat: Material, node_name := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if node_name != "":
		mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _line_mi(edges: Array, mat: Material, node_name := "") -> MeshInstance3D:
	return _mi(HtmlMeshLib.lines(edges), mat, node_name)


func _build() -> void:
	_root = Node3D.new()
	_root.name = "JavelinThrowHtmlRoot"
	add_child(_root)
	_root.top_level = true
	_root.global_transform = Transform3D.IDENTITY
	_build_javelin()
	_build_sightline()
	_build_crown()
	_build_afterimages()
	_build_impact()
	_built = true


func _build_javelin() -> void:
	_javelin_group = Node3D.new()
	_javelin_group.name = "Javelin"
	_root.add_child(_javelin_group)

	var shaft_mat := _std_mat(SHAFT_COLOR, 0.48, 0.25, Color.BLACK, 0.0, 1.0)
	_part_shaft = _mi(HtmlMeshLib.cylinder_z(
		0.032 * SHAFT_THICKNESS, 0.042 * SHAFT_THICKNESS, -1.15, 1.15, 8),
		shaft_mat, "Shaft")
	_part_shaft.position = Vector3(0.0, 0.0, SHAFT_CENTER_Z)
	_javelin_group.add_child(_part_shaft)

	_grip_group = Node3D.new()
	_grip_group.name = "Grip"
	var grip_mat := _std_mat(GRIP_COLOR, 0.65, 0.0, Color.BLACK, 0.0, 1.0)
	_grip_group.add_child(_mi(HtmlMeshLib.cylinder_z(
		0.052 * SHAFT_THICKNESS, 0.052 * SHAFT_THICKNESS, -0.22, 0.22, 8),
		grip_mat, "GripMesh"))
	_javelin_group.add_child(_grip_group)

	_collar_group = Node3D.new()
	_collar_group.name = "Collar"
	var collar_mat := _std_mat(COLLAR_COLOR, 0.25, 0.85, COLLAR_EMISSIVE, 0.45, 1.0)
	_collar_group.add_child(_mi(HtmlMeshLib.cylinder_z(
		0.080 * SHAFT_THICKNESS, 0.056 * SHAFT_THICKNESS, -0.11, 0.11, 6),
		collar_mat, "CollarMesh"))
	_collar_group.position = Vector3(0.0, 0.0, 0.42)
	_javelin_group.add_child(_collar_group)

	_feathers_group = Node3D.new()
	_feathers_group.name = "Fins"
	var fin_mat := _std_mat(FIN_COLOR, 0.35, 0.0, FIN_EMISSIVE, 0.35, 1.0)
	var fin_mesh := HtmlMeshLib.fin_extrude()
	for i in range(3):
		var pivot := Node3D.new()
		pivot.name = "Fin%d" % i
		pivot.rotation = Vector3(0.0, 0.0, float(i) * TAU / 3.0)
		pivot.add_child(_mi(fin_mesh, fin_mat, "FinMesh"))
		_feathers_group.add_child(pivot)
	_feathers_group.position = Vector3(0.0, 0.0, FIN_GROUP_Z)
	_javelin_group.add_child(_feathers_group)

	_tip_group = Node3D.new()
	_tip_group.name = "Tip"
	_spearhead_mat = _std_mat(TIP_COLOR, 0.15, 0.92, TIP_EMISSIVE, 0.4, 1.0)
	var tip_mesh := HtmlMeshLib.cylinder_z(
		0.0, 0.105 * TIP_WIDTH_SCALE, 0.0, BLADE_LENGTH, 4)
	var tip_mi := _mi(tip_mesh, _spearhead_mat, "TipMesh")
	tip_mi.add_child(_line_mi(
		HtmlMeshLib.cone_edges(0.105 * TIP_WIDTH_SCALE, 0.0, BLADE_LENGTH, 4),
		_line_mat(Color("#FFFFFF"), 0.92), "TipEdges"))
	_tip_group.add_child(tip_mi)
	_tip_group.position = Vector3(0.0, 0.0, 0.78)
	_javelin_group.add_child(_tip_group)

	_tip_star_group = Node3D.new()
	_tip_star_group.name = "TipStar"
	_tip_star_group.position = Vector3(0.0, 0.0, BLADE_LENGTH)
	_star_spike_mat = _basic_mat(STAR_COLOR, 0.0)
	_star_spike_mat.render_priority = 2
	_star_core_mat = _basic_mat(Color("#FFFFFF"), 0.0)
	_star_core_mat.render_priority = 2
	var spike_mesh := HtmlMeshLib.octahedron(0.052, 0)
	var star_v := _mi(spike_mesh, _star_spike_mat, "StarSpikeV")
	star_v.scale = Vector3(1.0, 8.2, 1.0)
	_tip_star_group.add_child(star_v)
	var star_h := _mi(spike_mesh, _star_spike_mat, "StarSpikeH")
	star_h.scale = Vector3(1.0, 8.2, 1.0)
	star_h.rotation = Vector3(0.0, 0.0, PI * 0.5)
	_tip_star_group.add_child(star_h)
	_tip_star_group.add_child(_mi(HtmlMeshLib.octahedron(0.11, 0), _star_core_mat, "StarCore"))
	_tip_group.add_child(_tip_star_group)

	_pulse_group = Node3D.new()
	_pulse_group.name = "ChargePulse"
	_pulse_mat = _basic_mat(PULSE_COLOR, 0.0)
	_pulse_mat.render_priority = 2
	var pulse_mesh := HtmlMeshLib.octahedron(0.14, 0)
	var pulse_mi := _mi(pulse_mesh, _pulse_mat, "PulseDiamond")
	pulse_mi.scale = Vector3(1.0, 1.0, 2.2)
	_pulse_group.add_child(pulse_mi)
	_pulse_sleeve_mat = _basic_mat(Color("#FFFBEB"), 0.0, true)
	_pulse_sleeve_mat.render_priority = 2
	_pulse_group.add_child(_mi(HtmlMeshLib.cylinder_z(0.16, 0.06, -0.19, 0.19, 7, false),
		_pulse_sleeve_mat, "PulseSleeve"))
	_javelin_group.add_child(_pulse_group)


func _build_sightline() -> void:
	_sightline_group = Node3D.new()
	_sightline_group.name = "Sightline"
	_root.add_child(_sightline_group)

	_sight_beam_mat = _basic_mat(SIGHT_COLOR, 0.0)
	_sight_beam_mat.render_priority = 1
	_sight_beam = _mi(HtmlMeshLib.cylinder_z(
		SIGHT_BEAM_RADIUS, SIGHT_BEAM_RADIUS, 0.0, 1.0, 6, false),
		_sight_beam_mat, "SightBeam")
	_sightline_group.add_child(_sight_beam)

	_reticle_holder = Node3D.new()
	_reticle_holder.name = "WeakPointReticle"
	_ret_outer_mat = _line_mat(SIGHT_COLOR, 0.95)
	_ret_outer_mat.render_priority = 2
	_ret_inner_mat = _line_mat(PULSE_COLOR, 0.85)
	_ret_inner_mat.render_priority = 2
	_reticle_holder.add_child(_line_mi(HtmlMeshLib.octahedron_edges(0.32),
		_ret_outer_mat, "ReticleOuter"))
	_ret_inner_mesh = _line_mi(HtmlMeshLib.octahedron_edges(0.18),
		_ret_inner_mat, "ReticleInner")
	_reticle_holder.add_child(_ret_inner_mesh)
	_sightline_group.add_child(_reticle_holder)


func _build_crown() -> void:
	_prism_crown_group = Node3D.new()
	_prism_crown_group.name = "PrismaticCrown3D"
	_root.add_child(_prism_crown_group)

	_prism_mat_inner = _std_mat(
		PRISM_INNER_COLOR, 0.14, 0.15, PRISM_INNER_EMISSIVE, 1.45, 0.92, true)
	_prism_mat_inner.render_priority = 2
	_prism_mat_outer = _std_mat(
		PRISM_OUTER_COLOR, 0.18, 0.20, PRISM_OUTER_EMISSIVE, 1.15, 0.80, true)
	_prism_mat_outer.render_priority = 2
	_prism_edge_mat = _line_mat(Color("#FFFBEB"), 0.96)
	_prism_edge_mat.render_priority = 3

	var inner_len := 1.08 * PRISM_LENGTH_SCALE
	var outer_len := 0.80 * PRISM_LENGTH_SCALE
	var inner_radius := 0.115 * PRISM_WIDTH_SCALE
	var outer_radius := 0.095 * PRISM_WIDTH_SCALE
	var inner_mesh := HtmlMeshLib.cylinder_z(0.0, inner_radius, -inner_len, 0.0, 3)
	var outer_mesh := HtmlMeshLib.cylinder_z(0.0, outer_radius, -outer_len, 0.0, 3)
	var inner_edges := HtmlMeshLib.cone_edges(inner_radius, 0.0, -inner_len, 3)
	var outer_edges := HtmlMeshLib.cone_edges(outer_radius, 0.0, -outer_len, 3)

	for i in range(CROWN_COUNT):
		var angle := float(i) * TAU / float(CROWN_COUNT)
		var holder := Node3D.new()
		holder.name = "Blade%d" % i
		var mesh := _mi(inner_mesh, _prism_mat_inner, "Solid")
		mesh.add_child(_line_mi(inner_edges, _prism_edge_mat, "Edge"))
		holder.add_child(mesh)
		_prism_crown_group.add_child(holder)
		_inner_blades.append({"holder": holder, "mesh": mesh, "angle": angle})

	for i in range(CROWN_COUNT):
		var angle2 := float(i) * TAU / float(CROWN_COUNT) + PI / float(CROWN_COUNT)
		var holder2 := Node3D.new()
		holder2.name = "Blade%d" % (CROWN_COUNT + i)
		var mesh2 := _mi(outer_mesh, _prism_mat_outer, "Solid")
		mesh2.add_child(_line_mi(outer_edges, _prism_edge_mat, "Edge"))
		holder2.add_child(mesh2)
		_prism_crown_group.add_child(holder2)
		_outer_blades.append({"holder": holder2, "mesh": mesh2, "angle": angle2})


func _build_afterimages() -> void:
	var ghost_tip_edges := HtmlMeshLib.cone_edges(0.095, 0.78, 1.30, 4)
	for i in range(GHOST_COUNT):
		var group := Node3D.new()
		group.name = "Ghost%d" % (i + 1)
		var is_crimson := i % 2 == 1
		var col := GHOST_COLOR_ALT if is_crimson else GHOST_COLOR_MAIN
		var mat := _std_mat(col, 0.2, 0.0, col, 1.1, 0.0)
		mat.render_priority = 1
		var shaft := _mi(HtmlMeshLib.cylinder_z(0.026, 0.034, -1.15, 1.15, 6),
			mat, "AfterShaft")
		shaft.position = Vector3(0.0, 0.0, SHAFT_CENTER_Z)
		group.add_child(shaft)
		var collar := _mi(HtmlMeshLib.cylinder_z(0.068, 0.048, -0.10, 0.10, 6),
			mat, "AfterCollar")
		collar.position = Vector3(0.0, 0.0, 0.42)
		group.add_child(collar)
		var tip := _mi(HtmlMeshLib.cylinder_z(0.0, 0.095, 0.78, 1.30, 4),
			mat, "AfterTip")
		tip.add_child(_line_mi(ghost_tip_edges, _line_mat(Color("#FFFBEB"), 0.75), "AfterTipEdges"))
		group.add_child(tip)
		group.visible = false
		_root.add_child(group)
		_after_images.append({"group": group, "mat": mat})

	_pierce_beam_mat = _basic_mat(PULSE_COLOR, 0.0)
	_pierce_beam_mat.render_priority = 2
	_pierce_beam = _mi(HtmlMeshLib.cylinder_z(0.025, 0.025, 0.0, 1.0, 6, false),
		_pierce_beam_mat, "PiercingBeam")
	_pierce_beam.visible = false
	_root.add_child(_pierce_beam)


func _build_impact() -> void:
	_ground_impact_group = Node3D.new()
	_ground_impact_group.name = "GroundImpact"
	_root.add_child(_ground_impact_group)

	_shock_torus_mat = _std_mat(PRISM_INNER_COLOR, 0.3, 0.0, PRISM_INNER_EMISSIVE, 0.45, 0.0)
	_shock_torus_mat.render_priority = 1
	_shock_torus = _mi(HtmlMeshLib.torus(
		0.62, 0.085 * GROUND_SHOCK_SCALE, 6, 14, true), _shock_torus_mat, "ShockTorus")
	_shock_torus.position = Vector3(0.0, 0.08, 0.0)
	_ground_impact_group.add_child(_shock_torus)

	_spike_mat = _std_mat(Color("#FBBF24"), 0.5, 0.0, Color("#92400E"), 0.5, 0.0)
	_spike_mat.render_priority = 1
	var spike_mesh := HtmlMeshLib.cone_y(0.11, 0.48 * GROUND_SHOCK_SCALE, 4)
	for i in range(8):
		var sp := _mi(spike_mesh, _spike_mat, "GroundSpike%d" % i)
		_ground_impact_group.add_child(sp)
		_ground_spikes.append({"mesh": sp, "angle": float(i) * TAU / 8.0})

	_dust_mat = _std_mat(Color("#A89F91"), 0.85, 0.0, Color("#443C30"), 0.25, 0.0)
	_dust_mat.render_priority = 1
	var dust_mesh := HtmlMeshLib.dodecahedron(0.14 * GROUND_SHOCK_SCALE)
	for i in range(DEBRIS_COUNT):
		var d := _mi(dust_mesh, _dust_mat, "Debris%d" % i)
		_ground_impact_group.add_child(d)
		_dust_blocks.append({
			"mesh": d,
			"angle": float(i) * TAU / float(DEBRIS_COUNT) + 0.15,
			"speed": 0.85 + float(i % 3) * 0.28,
			"lift": 0.20 + float(i % 3) * 0.16,
		})

	_chest_impact_group = Node3D.new()
	_chest_impact_group.name = "ChestImpact"
	_root.add_child(_chest_impact_group)

	_cross_mat = _basic_mat(CROSS_COLOR, 0.0)
	_cross_mat.render_priority = 1
	_cross_edge_mat = _line_mat(CROSS_EDGE_COLOR, 0.0)
	_cross_edge_mat.render_priority = 2
	var cross_mesh := HtmlMeshLib.octahedron(0.145 * CROSS_SCALE, 0)
	var cross_edges := HtmlMeshLib.octahedron_edges(0.145 * CROSS_SCALE)
	_cross1 = _mi(cross_mesh, _cross_mat, "CrossBlade0")
	_cross1.add_child(_line_mi(cross_edges, _cross_edge_mat, "CrossEdge"))
	_cross1.rotation = Vector3(0.0, 0.0, PI * 0.25)
	_chest_impact_group.add_child(_cross1)
	_cross2 = _mi(cross_mesh, _cross_mat, "CrossBlade1")
	_cross2.add_child(_line_mi(cross_edges, _cross_edge_mat, "CrossEdge"))
	_cross2.rotation = Vector3(0.0, 0.0, -PI * 0.25)
	_chest_impact_group.add_child(_cross2)
	_cross3 = _mi(cross_mesh, _cross_mat, "CrossBlade2")
	_cross3.add_child(_line_mi(cross_edges, _cross_edge_mat, "CrossEdge"))
	_cross3.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	_chest_impact_group.add_child(_cross3)

	_crit_flash_mat = _basic_mat(FLASH_COLOR_RED, 0.0)
	_crit_flash_mat.render_priority = 3
	_crit_flash = _mi(HtmlMeshLib.octahedron(0.62 * CROSS_SCALE, 1),
		_crit_flash_mat, "CritFlash")
	_chest_impact_group.add_child(_crit_flash)

	_delayed_ring_mat = _basic_mat(Color("#FEF08A"), 0.0)
	_delayed_ring_mat.render_priority = 3
	_delayed_ring_mat2 = _basic_mat(Color("#FEF08A"), 0.0)
	_delayed_ring_mat2.render_priority = 3
	var ring_mesh := HtmlMeshLib.torus(0.82, 0.024, 6, 24, false)
	_delayed_ring1 = _mi(ring_mesh, _delayed_ring_mat, "DelayedRing1")
	_chest_impact_group.add_child(_delayed_ring1)
	_delayed_ring2 = _mi(ring_mesh, _delayed_ring_mat2, "DelayedRing2")
	_chest_impact_group.add_child(_delayed_ring2)

	_spark_mat = _basic_mat(Color("#FEF08A"), 0.0)
	_spark_mat.render_priority = 4
	var spark_mesh := HtmlMeshLib.octahedron(0.058, 0)
	for i in range(SPARK_COUNT):
		var sp2 := _mi(spark_mesh, _spark_mat, "Spark%d" % i)
		sp2.scale = Vector3(0.65, 0.65, 3.4)
		_chest_impact_group.add_child(sp2)
		_crit_sparks.append({"mesh": sp2, "angle": float(i) * TAU / float(SPARK_COUNT) + 0.25})

	_ground_impact_group.visible = false
	_chest_impact_group.visible = false
