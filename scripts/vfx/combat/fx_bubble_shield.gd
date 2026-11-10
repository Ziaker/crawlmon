class_name FxBubbleShield
extends RefCounted
## D-323/D-324: Bubble Shield, visual aprovado no protótipo A+C.
## ALL ALLIES do lado do lançador. Uma membrana de sabão por aliado, escalada ao
## envelope do corpo, com o papel do wind-up em volta de cada um. O splash de
## impacto é sempre calculado no hemisfério voltado para a câmera do jogo, para
## aparecer na frente visível do personagem (nunca atrás).
## A reserva sem tipo e o tempo são autoridade de Battle/Combatant; aqui só se
## desenha o que esses eventos mandam.

const ShellShader: Shader = preload("res://shaders/bubble_shield_shell.gdshader")
const FacetShader: Shader = preload("res://shaders/bubble_shield_facets.gdshader")
const WaterShader: Shader = preload("res://shaders/bubble_shield_water.gdshader")
const PaperShader: Shader = preload("res://shaders/bubble_shield_paper.gdshader")

const SHELL_COLOR_A := Color("071e3f")
const SHELL_COLOR_B := Color("1450a8")
const SHELL_COLOR_C := Color("2e9bff")
const SHELL_COLOR_D := Color("8fe8ff")
const SHELL_WHITE := Color("f2ffff")
const PAPER_COLORS := [
	Color("1450a8"), Color("2e9bff"), Color("8fe8ff"), Color("f2ffff"),
]

static var _bubble_tex: ImageTexture
static var _drop_tex: ImageTexture
static var _spark_tex: ImageTexture
static var _shard_tex: ImageTexture
static var _flash_tex: ImageTexture
static var _sphere_mesh: SphereMesh
static var _tetra_mesh: ArrayMesh

var fx: BattleFx
var root: Node3D

var _windup_list: Array = []          ## BubbleShieldWindup, uma por aliado
var _bubbles: Dictionary = {}         ## Combatant -> BubbleShieldVisual
var _windup_released := false
var _debris: Array = []               ## gotas/esferas e lascas com física própria
var _light: OmniLight3D


func _init(p_fx: BattleFx) -> void:
	fx = p_fx
	root = Node3D.new()
	root.name = "BubbleShieldFX"
	fx.add_child(root)
	_light = OmniLight3D.new()
	_light.name = "BubbleShieldLight"
	_light.light_color = Color("6ec8ff")
	_light.light_energy = 0.0
	_light.omni_range = 4.0
	_light.shadow_enabled = false
	root.add_child(_light)


# --- Eventos de combate ------------------------------------------------------

## O Move de status começou a preparar (0,7 s): uma coroa de papel por aliado.
func begin_cast(caster: Combatant) -> void:
	clear_windups()
	_windup_released = false
	for c in team_of(caster):
		if c.is_alive():
			_windup_list.append(BubbleShieldWindup.new(self, c))
	var caster_model: Node3D = model_of(caster)
	if caster_model != null and is_instance_valid(caster_model):
		_light.global_position = caster_model.global_position + Vector3.UP * 1.2
	# Reaplicação: o escudo antigo do time se desfaz enquanto o novo é preparado.
	for c in team_of(caster):
		var old = _bubbles.get(c)
		if old != null:
			_bubbles.erase(c)
			old.expire()


func release_windups() -> void:
	_windup_released = true
	for w in _windup_list:
		if is_instance_valid(w.root):
			w.release()


func cancel_cast() -> void:
	if _windup_released:
		return
	clear_windups()


func clear_windups() -> void:
	for w in _windup_list:
		if is_instance_valid(w.root):
			w.free_now()
	_windup_list.clear()
	_windup_released = false


## O Move foi aplicado: cria (ou recria) a bolha de um aliado.
func on_shield_started(_caster: Combatant, target: Combatant) -> void:
	release_windups()
	var old = _bubbles.get(target)
	if old != null:
		old.free_now()
		_bubbles.erase(target)
	var model: Node3D = fx._models.get(target)
	if model == null or not is_instance_valid(model):
		return
	_bubbles[target] = BubbleShieldVisual.new(self, target, model)
	_light.global_position = model.global_position + Vector3.UP * 1.2
	light_pulse(1.0, 0.55)


## O escudo acabou: "broken" (resistência zerada), "expired" (8 s) ou "battle_end".
func on_shield_ended(target: Combatant, reason: String) -> void:
	var v = _bubbles.get(target)
	if v == null:
		return
	match reason:
		"broken", "hit":
			v.break_shield()
		"expired":
			v.expire()
		_:
			v.fade_out()
	light_pulse(0.5, 0.35)


## Dano absorvido: a bolha afunda, pulsa e solta gotas/lascas no lado da câmera.
func on_hit(target: Combatant, _absorbed: int) -> void:
	var v = _bubbles.get(target)
	if v != null:
		v.hit()


func clear_all(reason := "battle_end") -> void:
	for c in _bubbles.keys():
		var v = _bubbles[c]
		if v != null:
			if reason == "battle_end":
				v.fade_out()
			else:
				v.break_shield()
	_bubbles.clear()
	clear_windups()
	for d in _debris:
		if is_instance_valid(d["node"]):
			d["node"].queue_free()
	_debris.clear()


func _visual_done(v) -> void:
	for c in _bubbles.keys():
		if _bubbles[c] == v:
			_bubbles.erase(c)
			return


func _windup_done(w) -> void:
	_windup_list.erase(w)


# --- Update ------------------------------------------------------------------

func process(delta: float) -> void:
	for w in _windup_list.duplicate():
		if not is_instance_valid(w.root):
			_windup_list.erase(w)
			continue
		w.update(delta)
		if w.done:
			_windup_list.erase(w)
	for c in _bubbles.keys():
		var v = _bubbles[c]
		if v == null:
			_bubbles.erase(c)
			continue
		v.update(delta)
		if v.done:
			_bubbles.erase(c)
	_update_debris(delta)
	_light_update(delta)


func _light_update(delta: float) -> void:
	if _light == null:
		return
	_light.light_energy = move_toward(_light.light_energy, 0.0, delta * 3.0)


func light_pulse(energy: float, _time: float) -> void:
	if _light != null:
		_light.light_energy = maxf(_light.light_energy, energy)


# --- Leitura do corpo e do ponto de impacto ----------------------------------

## Centro e raio do envelope do corpo, em unidades de mundo. Ignora armas, anéis
## e escudos auxiliares para a bolha não ficar maior do que o personagem.
static func body_envelope(model: Node3D) -> Dictionary:
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for child in n.get_children():
			stack.append(child)
		if not (n is MeshInstance3D):
			continue
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var parent_name := ""
		if mi.get_parent() != null:
			parent_name = String(mi.get_parent().name)
		var tag: String = (String(mi.name) + " " + parent_name).to_lower()
		if tag.contains("wmodel") or tag.contains("weapon") or tag.contains("ring") \
				or tag.contains("shadow") or tag.contains("guard") or tag.contains("shield"):
			continue
		for k in 8:
			var p: Vector3 = mi.global_transform * mi.get_aabb().get_endpoint(k)
			mn = mn.min(p)
			mx = mx.max(p)
	if mn.x == INF:
		var fallback := model.global_position + Vector3(0, 1.1, 0)
		return {"center": fallback, "radius": 1.15, "height": 2.2}
	var size := mx - mn
	var center := (mn + mx) * 0.5
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	var max_ext := maxf(hx, maxf(hy, hz))
	var half_diag := sqrt(hx * hx + hy * hy + hz * hz)
	var aabb_radius := (lerpf(max_ext, half_diag, 0.38) + 0.06) * 1.02
	var height_world := maxf(size.y, 0.8)
	return {"center": center, "radius": maxf(aabb_radius, 0.45), "height": height_world}


## Centro do tronco: média entre o quadril e a cabeça do esqueleto, atualizada
## a cada frame. Assim a bolha acompanha a animação e não desloca para a cauda.
func body_anchor(model: Node3D) -> Vector3:
	if model == null or not is_instance_valid(model):
		return Vector3.ZERO
	var sk: Skeleton3D = null
	if model.has_meta("bubble_skeleton"):
		sk = model.get_meta("bubble_skeleton")
	if sk == null or not is_instance_valid(sk):
		var found := model.find_children("*", "Skeleton3D", true, false)
		sk = found[0] as Skeleton3D if not found.is_empty() else null
		model.set_meta("bubble_skeleton", sk)
	if sk != null:
		var bones: Dictionary
		if model.has_meta("bubble_body_bones"):
			bones = model.get_meta("bubble_body_bones")
		else:
			bones = _body_bone_indices(sk)
			model.set_meta("bubble_body_bones", bones)
		var hips := int(bones.get("hips", -1))
		var head := int(bones.get("head", -1))
		if hips >= 0 and head >= 0:
			var local_center := (sk.get_bone_global_pose(hips).origin + sk.get_bone_global_pose(head).origin) * 0.5
			return sk.global_transform * local_center
		if hips >= 0:
			# Modelos sem osso de cabeça (ex.: Gible): usa o quadril para o
			# x/z e a altura do modelo para o centro vertical. O offset não pode
			# ser aplicado no espaço do esqueleto, que é rotacionado.
			var hips_world := sk.global_transform * sk.get_bone_global_pose(hips).origin
			var head_y := 2.0
			if model.has_meta("head_y"):
				head_y = float(model.get_meta("head_y"))
			hips_world.y = model.global_position.y + head_y * 0.5 * model.scale.y
			return hips_world
		if head >= 0:
			return sk.global_transform * sk.get_bone_global_pose(head).origin
	var head_y := 2.0
	if model.has_meta("head_y"):
		head_y = float(model.get_meta("head_y"))
	return model.global_position + Vector3.UP * (head_y * 0.5 * model.scale.y)


func _body_bone_indices(sk: Skeleton3D) -> Dictionary:
	var hips := -1
	var head := -1
	var spine := -1
	for i in sk.get_bone_count():
		var n := String(sk.get_bone_name(i)).to_lower()
		if hips < 0 and (n == "hips" or n == "n_hara" or n == "waist"):
			hips = i
		if head < 0 and (n == "head" or n == "n_head" or n == "n_kao"):
			head = i
		if spine < 0 and n.begins_with("spine"):
			spine = i
	if hips < 0:
		hips = spine
	return {"hips": hips, "head": head}


## Ponto no hemisfério voltado para a câmera, com leve variação lateral. É o
## mesmo cálculo do protótipo aprovado: o splash aparece na frente visível.
func camera_hit_point(center: Vector3, radius: float) -> Vector3:
	var cam := camera_position()
	var to_cam := Vector3(cam.x - center.x, 0.0, cam.z - center.z)
	if to_cam.length_squared() < 0.0001:
		to_cam = Vector3.BACK
	to_cam = to_cam.normalized()
	var side := Vector3(-to_cam.z, 0.0, to_cam.x)
	to_cam = (to_cam + side * randf_range(-0.35, 0.35)).normalized()
	var point := center + to_cam * radius * 0.92
	point.y += radius * 0.06
	return point


func camera_position() -> Vector3:
	if fx != null:
		return fx._cam_pos()
	return Vector3(0, 3, 8)


func model_of(c: Combatant) -> Node3D:
	return fx._models.get(c)


func team_of(caster: Combatant) -> Array[Combatant]:
	var out: Array[Combatant] = []
	if caster == null:
		return out
	var battle := fx.battle if fx != null else null
	if battle == null:
		if caster.is_player:
			for c in fx._models.keys():
				if c is Combatant:
					out.append(c)
		return out
	var list: Array[Combatant] = battle.party if caster.is_player else battle.enemies
	for c in list:
		if c.is_alive():
			out.append(c)
	return out


# --- Partículas e detritos ---------------------------------------------------

## Burst de billboards com a mesma leitura do protótipo: cor A→B, tamanho que
## cresce e volta, gravidade positiva no eixo Y.
func burst(tex: Texture2D, pos: Vector3, count: int, color_a: Color, color_b: Color,
		speed_min: float, speed_max: float, size_min: float, size_max: float,
		life_min: float, life_max: float, radius: float, gravity: float,
		additive := true) -> void:
	var p := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.material = VfxLib.particle_mat(tex, additive)
	p.mesh = quad
	p.amount = maxi(count, 1)
	p.lifetime = maxf(life_max, 0.05)
	p.lifetime_randomness = clampf((life_max - life_min) / maxf(life_max, 0.05), 0.0, 1.0)
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed_min
	p.initial_velocity_max = speed_max
	p.gravity = Vector3(0.0, gravity, 0.0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = maxf(radius, 0.01)
	p.scale_amount_min = size_min
	p.scale_amount_max = size_max
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.65))
	curve.add_point(Vector2(0.5, 1.35))
	curve.add_point(Vector2(1.0, 0.86))
	p.scale_amount_curve = curve
	var ca := color_a
	ca.a = 0.0
	var cb := color_b
	cb.a = 1.0
	var ce := color_b
	ce.a = 0.0
	p.color_ramp = VfxLib.ramp([ca, cb, ce], [0.0, 0.08, 1.0])
	p.position = pos
	root.add_child(p)
	p.emitting = true
	if fx.get_tree() != null:
		fx.get_tree().create_timer(p.lifetime + 0.6).timeout.connect(p.queue_free)


## Splash anelar de gotas na superfície, perpendicular à direção do impacto.
func impact_splash(center: Vector3, radius: float, point: Vector3, normal: Vector3, n := 14) -> void:
	var up := Vector3.UP
	var tangent := normal.cross(up)
	if tangent.length_squared() < 0.001:
		tangent = Vector3.RIGHT
	tangent = tangent.normalized()
	var bitangent := normal.cross(tangent).normalized()
	for i in n:
		var a := (float(i) / float(n)) * TAU
		var outward := tangent * cos(a) + bitangent * sin(a)
		var size := radius * 0.022 * (0.7 + randf() * 0.8)
		var pos := point + outward * radius * 0.05
		var vel := outward * (0.8 + randf() * 0.8) + normal * (0.35 + randf() * 0.4)
		vel += Vector3.UP * (0.35 + randf() * 0.4)
		_spawn_sphere_debris(pos, size, Color("8fd4ff"), 0.85, 0.45 + randf() * 0.35, vel, 1.1, 0.0)


## Gotas maiores do estouro/expiração, nascidas na casca.
func water_debris(center: Vector3, radius: float, n: int) -> void:
	for i in n:
		var a := randf() * TAU
		var z := randf() * 2.0 - 1.0
		var h := sqrt(maxf(0.0, 1.0 - z * z))
		var dir := Vector3(cos(a) * h, z, sin(a) * h)
		var size := radius * (0.018 + randf() * 0.029)
		var pos := center + dir * radius * (0.75 + randf() * 0.22)
		var vel := dir * (0.8 * (0.45 + randf() * 1.2)) + Vector3.UP * (0.2 + randf() * 0.65)
		_spawn_sphere_debris(pos, size, Color("8fd4ff"), 0.82, 1.0 + randf() * 0.5, vel, 1.1, 0.6)


## Lascas de cristal da concha facetada. "hit" é pequeno; "break" usa aditivo.
func facet_shards(center: Vector3, radius: float, mode: String, n: int, origin = null) -> void:
	var base: Vector3 = origin if origin != null else center
	var spread := radius * (0.14 if origin != null else 0.72)
	var colors := [Color("6fc8ff"), Color("9fe6dc"), Color("7a6cff"), Color("bfe9e0")]
	var hard := mode == "break"
	var hit := mode == "hit"
	var mesh := tetra_mesh()
	for i in n:
		var a := randf() * TAU
		var z := randf() * 2.0 - 1.0
		var h := sqrt(maxf(0.0, 1.0 - z * z))
		var dir := Vector3(cos(a) * h, z, sin(a) * h)
		var size := radius * (0.018 if hit else 0.032) * (0.65 + randf() * 0.8)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if hard else BaseMaterial3D.BLEND_MODE_MIX
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mat.albedo_color = colors[i % colors.size()]
		mat.albedo_color.a = 0.9
		mi.material_override = mat
		mi.position = base + dir * (spread + radius * randf() * (0.06 if origin != null else 0.2))
		mi.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		mi.scale = Vector3.ONE * size
		root.add_child(mi)
		var speed := (0.9 if hit else (2.2 if hard else 1.3)) * (0.6 + randf() * 1.15)
		var vel := dir * speed + Vector3.UP * ((1.5 if hard else 0.8) + randf() * 0.8)
		_debris.append({
			"node": mi, "vel": vel,
			"spin": Vector3((randf() - 0.5) * 9.0, (randf() - 0.5) * 9.0, (randf() - 0.5) * 9.0),
			"age": 0.0,
			"life": (0.45 if hit else (0.85 if hard else 1.35)) + randf() * 0.45,
			"gravity": 4.6 if hard else 2.4,
			"grow": 0.35,
			"base_alpha": 0.9,
		})


func flash(pos: Vector3, color: Color, size: float, life: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = QuadMesh.new()
	(mi.mesh as QuadMesh).size = Vector2.ONE
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.albedo_texture = flash_texture()
	mat.albedo_color = color
	mat.albedo_color.a = 0.95
	mi.material_override = mat
	mi.position = pos
	mi.scale = Vector3.ONE * size * 0.35
	root.add_child(mi)
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * size * 1.7, life)
	tw.tween_property(mat, "albedo_color:a", 0.0, life)
	tw.chain().tween_callback(mi.queue_free)


func _spawn_sphere_debris(pos: Vector3, size: float, color: Color, opacity: float,
		life: float, vel: Vector3, gravity: float, stretch: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = sphere_mesh()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.albedo_color = color
	mat.albedo_color.a = opacity
	mi.material_override = mat
	mi.position = pos
	mi.scale = Vector3.ONE * (size * 2.0)
	root.add_child(mi)
	_debris.append({
		"node": mi, "vel": vel, "spin": Vector3.ZERO,
		"age": 0.0, "life": life, "gravity": gravity,
		"grow": stretch, "base_alpha": opacity,
	})


func _update_debris(delta: float) -> void:
	for i in range(_debris.size() - 1, -1, -1):
		var d: Dictionary = _debris[i]
		var node: MeshInstance3D = d["node"]
		if not is_instance_valid(node):
			_debris.remove_at(i)
			continue
		d["age"] = float(d["age"]) + delta
		var t := float(d["age"]) / maxf(float(d["life"]), 0.001)
		if t >= 1.0:
			node.queue_free()
			_debris.remove_at(i)
			continue
		d["vel"] = (d["vel"] as Vector3) + Vector3.DOWN * float(d["gravity"]) * delta
		node.position += (d["vel"] as Vector3) * delta
		var spin: Vector3 = d["spin"]
		node.rotation += spin * delta
		var grow := float(d["grow"])
		if grow > 0.0:
			node.scale = Vector3(node.scale.x, node.scale.y * (1.0 + delta * grow), node.scale.z * (1.0 + delta * grow * 0.35))
		var mat := node.material_override as StandardMaterial3D
		if mat != null:
			mat.albedo_color.a = pow(1.0 - t, 1.35) * float(d["base_alpha"])


# --- Texturas procedurais (mesmas do protótipo) ------------------------------

static func bubble_texture() -> ImageTexture:
	if _bubble_tex != null:
		return _bubble_tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(
				(float(x) - n * 0.42) / float(n),
				(float(y) - n * 0.38) / float(n)
			).length()
			var a := _gradient(d, [0.0, 0.55, 0.82, 0.95, 1.0], [0.05, 0.10, 0.55, 0.95, 0.0])
			var r := Vector2(x - n * 0.5 + 0.5, y - n * 0.5 + 0.5).length() / float(n)
			if absf(r - 0.43) < 0.009:
				a = maxf(a, 0.7)
			var hl := Vector2((x - n * 0.34) / float(n), (y - n * 0.30) / float(n)).length()
			if hl < 0.034:
				a = 0.95
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_bubble_tex = ImageTexture.create_from_image(img)
	return _bubble_tex


static func drop_texture() -> ImageTexture:
	if _drop_tex != null:
		return _drop_tex
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(
				(float(x) - n * 0.44) / float(n),
				(float(y) - n * 0.38) / float(n)
			).length()
			var a := _gradient(d, [0.0, 0.4, 0.8, 1.0], [0.95, 0.65, 0.18, 0.0])
			var r := Vector2(x - n * 0.5 + 0.5, y - n * 0.54 + 0.5).length() / float(n)
			if r > 0.38:
				a = 0.0
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_drop_tex = ImageTexture.create_from_image(img)
	return _drop_tex


static func spark_texture() -> ImageTexture:
	if _spark_tex != null:
		return _spark_tex
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var p := Vector2((float(x) - n * 0.5 + 0.5) / float(n), (float(y) - n * 0.5 + 0.5) / float(n))
			var r := p.length() * 2.0
			var a := _gradient(r, [0.0, 0.18, 0.6, 1.0], [1.0, 0.85, 0.18, 0.0])
			var star := maxf(
				maxf(1.0 - absf(p.x) * 14.0, 1.0 - absf(p.y) * 14.0),
				maxf(1.0 - absf(p.x + p.y) * 18.0, 1.0 - absf(p.x - p.y) * 18.0)
			)
			a = maxf(a, clampf(star, 0.0, 1.0) * 0.9)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_spark_tex = ImageTexture.create_from_image(img)
	return _spark_tex


static func shard_texture() -> ImageTexture:
	if _shard_tex != null:
		return _shard_tex
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var a := 0.0
			var px := float(x) / float(n)
			var py := float(y) / float(n)
			# Triângulo cheio do protótipo.
			if py >= 0.08 and py <= 0.84:
				var half := lerpf(0.0, 0.36, (py - 0.08) / 0.50)
				if absf(px - 0.5) <= half:
					a = 0.9
			var edge := absf(px - 0.5) - lerpf(0.0, 0.36, clampf((py - 0.08) / 0.50, 0.0, 1.0))
			if absf(edge) < 0.02 and py >= 0.08 and py <= 0.84:
				a = 1.0
			img.set_pixel(x, y, Color(0.92, 1.0, 1.0, a))
	_shard_tex = ImageTexture.create_from_image(img)
	return _shard_tex


static func flash_texture() -> ImageTexture:
	if _flash_tex != null:
		return _flash_tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x - n * 0.5 + 0.5, y - n * 0.5 + 0.5).length() / float(n)
			var a := _gradient(d, [0.0, 0.12, 0.34, 0.7, 1.0], [1.0, 0.95, 0.35, 0.08, 0.0])
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_flash_tex = ImageTexture.create_from_image(img)
	return _flash_tex


static func _gradient(x: float, stops: Array, alphas: Array) -> float:
	if x <= float(stops[0]):
		return float(alphas[0])
	for i in range(1, stops.size()):
		if x <= float(stops[i]):
			var t := (x - float(stops[i - 1])) / maxf(float(stops[i]) - float(stops[i - 1]), 0.0001)
			return lerpf(float(alphas[i - 1]), float(alphas[i]), t)
	return 0.0


# --- Malhas ------------------------------------------------------------------

static func helix_mesh(radius: float, turns: float, width: float, y0: float, y1: float,
		phase: float, segments := 96) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segments + 1:
		var t := float(i) / float(segments)
		var ang := phase + t * TAU * turns
		var rad := radius + 0.10 * sin(t * TAU * 2.0 + phase)
		var y := lerpf(y0, y1, t)
		var cx := cos(ang) * rad
		var cz := sin(ang) * rad
		var wx := cos(ang) * 0.02
		var wz := sin(ang) * 0.02
		for j in 2:
			var off := (float(j) - 0.5) * width
			st.set_uv(Vector2(t, float(j)))
			st.add_vertex(Vector3(cx + wx * off, y + off, cz + wz * off))
	for i in segments:
		var a0 := i * 2
		st.add_index(a0)
		st.add_index(a0 + 1)
		st.add_index(a0 + 2)
		st.add_index(a0 + 1)
		st.add_index(a0 + 3)
		st.add_index(a0 + 2)
	return st.commit()


static func ring_mesh(inner: float, outer: float, segments := 96) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segments + 1:
		var a := float(i) / float(segments) * TAU
		var c := cos(a)
		var s := sin(a)
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(c * inner, 0.0, s * inner))
		st.add_vertex(Vector3(c * outer, 0.0, s * outer))
	for i in segments:
		var a0 := i * 2
		st.add_index(a0)
		st.add_index(a0 + 2)
		st.add_index(a0 + 1)
		st.add_index(a0 + 1)
		st.add_index(a0 + 2)
		st.add_index(a0 + 3)
	return st.commit()


static func circle_mesh(radius: float, segments := 12) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.BACK)
	st.add_vertex(Vector3.ZERO)
	for i in segments + 1:
		var a := float(i) / float(segments) * TAU
		st.set_normal(Vector3.BACK)
		st.add_vertex(Vector3(cos(a) * radius, sin(a) * radius, 0.0))
	for i in segments:
		st.add_index(0)
		st.add_index(i + 1)
		st.add_index(i + 2)
	return st.commit()


## Polígono plano (x, y) triangulado.
static func paper_mesh(points: PackedVector2Array) -> ArrayMesh:
	var indices := Geometry2D.triangulate_polygon(points)
	if indices.is_empty():
		indices = PackedInt32Array()
		for i in range(1, points.size() - 1):
			indices.append(0)
			indices.append(i)
			indices.append(i + 1)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in points:
		st.set_normal(Vector3.BACK)
		st.set_uv(Vector2(p.x, p.y))
		st.add_vertex(Vector3(p.x, p.y, 0.0))
	for idx in indices:
		st.add_index(idx)
	return st.commit()


static func outline_mesh(points: PackedVector2Array, z := 0.002) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		mesh.surface_add_vertex(Vector3(p.x, p.y, z))
	mesh.surface_add_vertex(Vector3(points[0].x, points[0].y, z))
	mesh.surface_end()
	return mesh


static func tetra_mesh() -> ArrayMesh:
	if _tetra_mesh != null:
		return _tetra_mesh
	var v := [
		Vector3(1, 1, 1).normalized(),
		Vector3(1, -1, -1).normalized(),
		Vector3(-1, 1, -1).normalized(),
		Vector3(-1, -1, 1).normalized(),
	]
	var faces := [[0, 1, 2], [0, 3, 1], [0, 2, 3], [1, 3, 2]]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var a: Vector3 = v[f[0]]
		var b: Vector3 = v[f[1]]
		var c: Vector3 = v[f[2]]
		var n := (b - a).cross(c - a).normalized()
		for p in [a, b, c]:
			st.set_normal(n)
			st.set_uv(Vector2(p.x * 0.5 + 0.5, p.y * 0.5 + 0.5))
			st.add_vertex(p)
	_tetra_mesh = st.commit()
	return _tetra_mesh


static func sphere_mesh() -> SphereMesh:
	if _sphere_mesh == null:
		_sphere_mesh = SphereMesh.new()
		_sphere_mesh.radius = 0.5
		_sphere_mesh.height = 1.0
		_sphere_mesh.radial_segments = 8
		_sphere_mesh.rings = 6
	return _sphere_mesh


static func ico_sphere_mesh(radius: float, subdivisions := 3) -> ArrayMesh:
	var t := (1.0 + sqrt(5.0)) * 0.5
	var verts: Array[Vector3] = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
	]
	for i in verts.size():
		verts[i] = verts[i].normalized()
	var faces: Array = [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
	]
	for _s in subdivisions:
		var next: Array = []
		for f in faces:
			var a: Vector3 = verts[f[0]]
			var b: Vector3 = verts[f[1]]
			var c: Vector3 = verts[f[2]]
			var ab := (a + b).normalized()
			var bc := (b + c).normalized()
			var ca := (c + a).normalized()
			var ia := verts.size()
			verts.append(ab)
			verts.append(bc)
			verts.append(ca)
			next.append([f[0], ia, ia + 2])
			next.append([f[1], ia + 1, ia])
			next.append([f[2], ia + 2, ia + 1])
			next.append([ia, ia + 1, ia + 2])
		faces = next
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var a: Vector3 = verts[f[0]] * radius
		var b: Vector3 = verts[f[1]] * radius
		var c: Vector3 = verts[f[2]] * radius
		var n := (b - a).cross(c - a).normalized()
		for p in [a, b, c]:
			st.set_normal(n)
			var uv := Vector2(atan2(p.z, p.x) / TAU + 0.5, p.y / (2.0 * radius) + 0.5)
			st.set_uv(uv)
			st.add_vertex(p)
	return st.commit()
