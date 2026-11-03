extends Node3D
class_name SmtStageVfx

enum MoveType { TARUKAJA, RAKUNDA, SUKUNDA }

const COLORS := {
	MoveType.TARUKAJA: Color("#D7FD6A"), # Verde-Lima
	MoveType.RAKUNDA:  Color("#FF624F"), # Coral
	MoveType.SUKUNDA:  Color("#F7CB78")  # Amarelo/Ouro
}

const LABELS := {
	MoveType.TARUKAJA: "↗ ATK +1",
	MoveType.RAKUNDA:  "↘ DEF -1",
	MoveType.SUKUNDA:  "↯ SPD -1"
}

@export var move_type: MoveType = MoveType.TARUKAJA
@export var duration: float = 1.0

var _target: Node3D
var _target_orig_pos: Vector3
var _target_orig_scale: Vector3 = Vector3.ONE
var _elapsed: float = 0.0
var _active: bool = false
var _material: ShaderMaterial
var _rings: Array[MeshInstance3D] = []
var _orbitals: Array[MeshInstance3D] = []
var _orbital_pivot: Node3D
var _sigil_mesh: MeshInstance3D
var _sigil_mat: ShaderMaterial
var _special_root: Node3D
var _blades: Array[MeshInstance3D] = []
var _shield_shards: Array[MeshInstance3D] = []
var _shard_dirs: Array[Vector3] = []
var _stakes: Array[MeshInstance3D] = []
var _stasis_bands: Array[MeshInstance3D] = []
var _overlay_layer: CanvasLayer
var _label: Label

func setup(p_type: MoveType, p_target: Node3D, p_duration: float = 1.0) -> void:
	move_type = p_type
	_target = p_target
	duration = maxf(p_duration, 0.1)
	if is_instance_valid(_target):
		global_position = _target.global_position
		_target_orig_pos = _target.position
		_target_orig_scale = _target.scale
	_build_vfx()
	_build_overlay()
	_active = true

func _exit_tree() -> void:
	if is_instance_valid(_target):
		_target.position = _target_orig_pos
		_target.scale = _target_orig_scale

func _build_vfx() -> void:
	var shader := preload("res://shaders/smt_stage_vfx.gdshader")
	_material = ShaderMaterial.new()
	_material.shader = shader
	var col: Color = COLORS.get(move_type, Color.WHITE)
	_material.set_shader_parameter("vfx_color", col)
	_material.set_shader_parameter("fresnel_power", 1.8)
	_material.set_shader_parameter("pulse_speed", 5.0)
	_material.set_shader_parameter("alpha_mult", 1.0)

	# 1. Três anéis holográficos
	var rings_root := Node3D.new()
	rings_root.name = "RingsRoot"
	add_child(rings_root)

	for i in 3:
		var mi := MeshInstance3D.new()
		mi.name = "Ring_%d" % i
		var torus := TorusMesh.new()
		torus.inner_radius = 1.25 + float(i) * 0.1
		torus.outer_radius = 1.35 + float(i) * 0.1
		torus.rings = 32
		torus.ring_segments = 6
		mi.mesh = torus
		mi.material_override = _material
		rings_root.add_child(mi)
		_rings.append(mi)

	# 2. Pivô orbital com geometrias temáticas (D-035)
	_orbital_pivot = Node3D.new()
	_orbital_pivot.name = "OrbitalPivot"
	add_child(_orbital_pivot)

	match move_type:
		MoveType.TARUKAJA:
			# 4 Cones/Lanças apontando para cima
			for k in 4:
				var mi := MeshInstance3D.new()
				mi.name = "Lance_%d" % k
				var cone := CylinderMesh.new()
				cone.top_radius = 0.0
				cone.bottom_radius = 0.22
				cone.height = 0.75
				mi.mesh = cone
				mi.material_override = _material
				_orbital_pivot.add_child(mi)
				_orbitals.append(mi)

		MoveType.RAKUNDA:
			# 6 Cunhas invertidas apontando para baixo
			for k in 6:
				var mi := MeshInstance3D.new()
				mi.name = "Wedge_%d" % k
				var cone := CylinderMesh.new()
				cone.top_radius = 0.26
				cone.bottom_radius = 0.0
				cone.height = 0.85
				mi.mesh = cone
				mi.material_override = _material
				_orbital_pivot.add_child(mi)
				_orbitals.append(mi)

		MoveType.SUKUNDA:
			# 6 Cubos de inércia amarelos
			for k in 6:
				var mi := MeshInstance3D.new()
				mi.name = "InertiaBox_%d" % k
				var box := BoxMesh.new()
				box.size = Vector3(0.32, 0.58, 0.32)
				mi.mesh = box
				mi.material_override = _material
				_orbital_pivot.add_child(mi)
				_orbitals.append(mi)

	# 3. Selo Mágico Rúnico no Piso (D-037)
	_build_ground_sigil(col)

	# 4. Elementos Específicos D-037 (Lanças/Feixes, Escudo Fraturado, Estacas, Estase)
	_build_special_vfx(col)

func _build_ground_sigil(col: Color) -> void:
	var sigil_shader := preload("res://shaders/smt_sigil.gdshader")
	_sigil_mat = ShaderMaterial.new()
	_sigil_mat.shader = sigil_shader
	_sigil_mat.set_shader_parameter("sigil_color", col)
	var st: int = 0
	match move_type:
		MoveType.TARUKAJA: st = 0
		MoveType.RAKUNDA: st = 1
		MoveType.SUKUNDA: st = 2
	_sigil_mat.set_shader_parameter("sigil_type", st)
	_sigil_mat.set_shader_parameter("rotation_speed", 2.2 if move_type != MoveType.RAKUNDA else -2.2)
	_sigil_mat.set_shader_parameter("alpha_mult", 1.0)
	_sigil_mat.set_shader_parameter("jam_factor", 0.0)

	_sigil_mesh = MeshInstance3D.new()
	_sigil_mesh.name = "GroundSigil"
	var quad := QuadMesh.new()
	quad.size = Vector2(3.6, 3.6)
	_sigil_mesh.mesh = quad
	_sigil_mesh.material_override = _sigil_mat
	_sigil_mesh.position = Vector3(0.0, 0.02, 0.0)
	_sigil_mesh.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	add_child(_sigil_mesh)

func _build_special_vfx(_col: Color) -> void:
	_special_root = Node3D.new()
	_special_root.name = "SpecialRoot"
	add_child(_special_root)

	match move_type:
		MoveType.TARUKAJA:
			# 8 Lanças / Feixes angulares cortantes ascendentes (Spikes de energia)
			var blade_mesh := PrismMesh.new()
			blade_mesh.size = Vector3(0.18, 1.6, 0.04)
			for i in 8:
				var mi := MeshInstance3D.new()
				mi.name = "EnergyBlade_%d" % i
				mi.mesh = blade_mesh
				mi.material_override = _material
				_special_root.add_child(mi)
				_blades.append(mi)

		MoveType.RAKUNDA:
			# Escudo de defesa frontal hexagonal fraturável em 6 cacos
			var shard_mesh := PrismMesh.new()
			shard_mesh.size = Vector3(0.35, 0.35, 0.05)
			for i in 6:
				var mi := MeshInstance3D.new()
				mi.name = "ShieldShard_%d" % i
				mi.mesh = shard_mesh
				mi.material_override = _material
				var a := (TAU / 6.0) * float(i)
				_shard_dirs.append(Vector3(cos(a), sin(a), randf_range(-0.5, 0.5)).normalized())
				_special_root.add_child(mi)
				_shield_shards.append(mi)

			# 4 Estacas de maldição / gravidade
			var stake_mesh := CylinderMesh.new()
			stake_mesh.top_radius = 0.0
			stake_mesh.bottom_radius = 0.16
			stake_mesh.height = 1.3
			stake_mesh.radial_segments = 6
			for i in 4:
				var mi := MeshInstance3D.new()
				mi.name = "GravityStake_%d" % i
				mi.mesh = stake_mesh
				mi.material_override = _material
				_special_root.add_child(mi)
				_stakes.append(mi)

		MoveType.SUKUNDA:
			# 3 Faixas / Arcos de estase no solo
			for i in 3:
				var mi := MeshInstance3D.new()
				mi.name = "StasisBand_%d" % i
				var band := TorusMesh.new()
				band.inner_radius = 0.55 + float(i) * 0.12
				band.outer_radius = 0.65 + float(i) * 0.12
				band.rings = 24
				band.ring_segments = 6
				mi.mesh = band
				mi.material_override = _material
				mi.position = Vector3(0.0, 0.18 + float(i) * 0.14, 0.0)
				_special_root.add_child(mi)
				_stasis_bands.append(mi)

func _build_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "SmtScreenOverlay"
	add_child(_overlay_layer)

	_label = Label.new()
	_label.name = "StageLabel"
	_label.text = LABELS.get(move_type, "")
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var col: Color = COLORS.get(move_type, Color.WHITE)
	_label.add_theme_color_override("font_color", col)
	_label.add_theme_color_override("font_outline_color", Color(0.03, 0.06, 0.1, 0.95))
	_label.add_theme_constant_override("outline_size", 8)
	_label.add_theme_font_size_override("font_size", 28)

	_overlay_layer.add_child(_label)

func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta
	var p: float = clampf(_elapsed / duration, 0.0, 1.0)

	if is_instance_valid(_target):
		global_position = _target.global_position

	# Atualizar transparência geral via curva seno suave
	var alpha_curve := sin(p * PI)
	if _material:
		_material.set_shader_parameter("alpha_mult", alpha_curve)

	# Animar anéis
	for i in range(_rings.size()):
		var ring := _rings[i]
		var stagger: float = float(i) * 0.15
		var ring_p: float = clampf((p * 1.3) - stagger, 0.0, 1.0)

		match move_type:
			MoveType.TARUKAJA:
				# Ascendente: 0.1 -> 3.2
				var y := 0.1 + ring_p * 3.1
				ring.position = Vector3(0.0, y, 0.0)
				var scale_factor: float = 1.0 + sin(ring_p * PI) * 0.25
				ring.scale = Vector3(scale_factor, 1.0, scale_factor)

			MoveType.RAKUNDA, MoveType.SUKUNDA:
				# Descendente: 3.4 -> 0.15
				var y := 3.4 * (1.0 - ring_p) + 0.15
				ring.position = Vector3(0.0, y, 0.0)
				var scale_factor: float = 1.0 - (ring_p * 0.18)
				ring.scale = Vector3(scale_factor, 1.0, scale_factor)

	# Animar orbitais
	var orbital_count := _orbitals.size()
	if orbital_count > 0:
		var rot_speed := 4.2 if move_type != MoveType.RAKUNDA else -3.8
		_orbital_pivot.rotation.y += delta * rot_speed

		for k in range(orbital_count):
			var mi := _orbitals[k]
			var angle: float = (TAU / float(orbital_count)) * float(k)
			var radius: float = 1.45

			match move_type:
				MoveType.TARUKAJA:
					var py: float = 0.4 + fmod((p * 3.0 + float(k) * 0.25), 2.6)
					mi.position = Vector3(cos(angle) * radius, py, sin(angle) * radius)
					mi.rotation = Vector3(0.0, angle, 0.0)

				MoveType.RAKUNDA:
					var py: float = 3.2 * (1.0 - fmod((p * 1.4 + float(k) * 0.15), 1.0)) + 0.3
					mi.position = Vector3(cos(angle) * radius, py, sin(angle) * radius)
					mi.rotation = Vector3(PI, angle, 0.0)

				MoveType.SUKUNDA:
					var cur_radius: float = radius * (1.0 - p * 0.25)
					var py: float = 2.6 * (1.0 - p * 0.6) + sin(float(k) + _elapsed * 4.0) * 0.2
					mi.position = Vector3(cos(angle) * cur_radius, py, sin(angle) * cur_radius)
					mi.rotation += Vector3(delta * 2.5, delta * 3.5, delta * 1.5)

	# Atualizar overlay 2D em tela
	_update_overlay(p, alpha_curve)

	# Animar Selo Mágico no Piso (D-037)
	if _sigil_mat:
		_sigil_mat.set_shader_parameter("alpha_mult", alpha_curve)
		if move_type == MoveType.SUKUNDA:
			var jam: float = clampf((p - 0.35) / 0.15, 0.0, 1.0)
			_sigil_mat.set_shader_parameter("jam_factor", jam)

	# Animar Elementos Específicos D-037
	match move_type:
		MoveType.TARUKAJA:
			# Feixes pontiagudos de energia subindo com aceleração rápida e estiramento
			var blade_count := _blades.size()
			for i in range(blade_count):
				var mi := _blades[i]
				var a: float = (TAU / float(blade_count)) * float(i)
				var radius: float = 1.25
				var blade_p: float = fmod(p * 2.8 + float(i) * 0.14, 1.0)
				var py: float = blade_p * 3.6
				mi.position = Vector3(cos(a) * radius, py, sin(a) * radius)
				mi.rotation = Vector3(0.0, a, 0.12)
				var stretch: float = 1.0 + sin(blade_p * PI) * 0.7
				mi.scale = Vector3(1.0, stretch, 1.0)

		MoveType.RAKUNDA:
			# 4 Estacas de maldição despencando do alto (p: 0.0 -> 0.36)
			var stake_count := _stakes.size()
			for i in range(stake_count):
				var mi := _stakes[i]
				var a: float = (TAU / float(stake_count)) * float(i) + PI / 4.0
				var radius: float = 1.45
				var fall_p: float = clampf(p / 0.36, 0.0, 1.0)
				var ease_fall := fall_p * fall_p
				var py: float = lerpf(4.5, 0.65, ease_fall)
				mi.position = Vector3(cos(a) * radius, py, sin(a) * radius)
				mi.rotation = Vector3(PI, a, 0.0)

			# Escudo frontal hexagonal: intacto até p=0.38, depois se estilhaça em 6 cacos
			var shield_center := Vector3(0.0, 1.25, 0.75)
			var shard_count := _shield_shards.size()
			if p < 0.38:
				for i in range(shard_count):
					var mi := _shield_shards[i]
					var a := (TAU / float(shard_count)) * float(i)
					mi.position = shield_center + Vector3(cos(a) * 0.28, sin(a) * 0.28, 0.0)
					mi.rotation = Vector3(0.0, 0.0, a)
					mi.scale = Vector3.ONE
			else:
				var shatter_p: float = (p - 0.38) / 0.62
				for i in range(shard_count):
					var mi := _shield_shards[i]
					var dir: Vector3 = _shard_dirs[i] if i < _shard_dirs.size() else Vector3.UP
					var fly_dist := shatter_p * 2.2
					var py: float = shield_center.y + dir.y * fly_dist - (shatter_p * shatter_p * 1.8)
					mi.position = Vector3(shield_center.x + dir.x * fly_dist, maxf(py, 0.05), shield_center.z + dir.z * fly_dist)
					mi.rotation += Vector3(delta * 8.0, delta * 6.0, delta * 4.0)
					mi.scale = Vector3.ONE * maxf(1.0 - shatter_p * 0.7, 0.05)

			# Squash & Jitter físico no alvo (p entre 0.36 e 0.75)
			if is_instance_valid(_target):
				if p >= 0.36 and p <= 0.75:
					var phase := (p - 0.36) / 0.39
					var squash := sin(phase * PI) * 0.18
					_target.scale = Vector3(_target_orig_scale.x * (1.0 + squash * 0.5), _target_orig_scale.y * (1.0 - squash), _target_orig_scale.z * (1.0 + squash * 0.5))
					var jitter := sin(_elapsed * 55.0) * 0.06 * (1.0 - phase)
					_target.position = _target_orig_pos + Vector3(jitter, 0.0, 0.0)
				else:
					_target.scale = _target_orig_scale
					_target.position = _target_orig_pos

		MoveType.SUKUNDA:
			# Arcos de estase contraindo nos tornozelos
			var band_count := _stasis_bands.size()
			for i in range(band_count):
				var mi := _stasis_bands[i]
				var contract_p: float = clampf(p / 0.38, 0.0, 1.0)
				var cur_r: float = lerpf(1.6, 0.70, contract_p)
				mi.scale = Vector3(cur_r, 1.0, cur_r)
				mi.rotation.y += delta * (8.0 if p < 0.38 else 0.5)

			# Stutter temporal no alvo
			if is_instance_valid(_target):
				if p >= 0.38 and p <= 0.82:
					var stutter: float = snappedf(sin(_elapsed * 45.0), 0.5) * 0.04
					_target.position = _target_orig_pos + Vector3(stutter, 0.0, 0.0)
				else:
					_target.position = _target_orig_pos

	if p >= 1.0:
		_active = false
		if is_instance_valid(_target):
			_target.position = _target_orig_pos
			_target.scale = _target_orig_scale
		queue_free()

func _update_overlay(p: float, alpha_curve: float) -> void:
	if not is_instance_valid(_label):
		return

	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return

	var head_pos := global_position + Vector3(0.0, 2.0 + (p * 0.5), 0.0)
	if cam.is_position_behind(head_pos):
		_label.visible = false
		return

	var screen_pos := cam.unproject_position(head_pos)
	_label.visible = true
	_label.position = screen_pos - Vector2(100.0, 20.0)
	_label.size = Vector2(200.0, 40.0)
	_label.modulate.a = alpha_curve
	var s: float = 1.0 + (1.0 - alpha_curve) * 0.25
	_label.scale = Vector2(s, s)
