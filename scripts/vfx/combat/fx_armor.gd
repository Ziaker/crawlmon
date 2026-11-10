class_name FxArmor
extends RefCounted
## D-1026: the look of the ARMOR badge on a model and of Armored Bulk. The model gets a low-opacity chrome film
## (material_overlay with shaders/armor_chrome.gdshader) that does not hide its textures: a wave of chrome climbs from the
## feet to the head (0.38 s), a flash seats it, and it stays at a low opacity until the badge ends. The particles (glints,
## shock ring, sparks) are an ArmorVfx on the Motion Composer. Everything is measured from the real model (D-235).
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

const SHADER := preload("res://shaders/armor_chrome.gdshader")
const WAVE := 0.38  ## seconds the chrome wave takes to reach the head
const SETTLED_ALPHA := 0.45  ## the film's resting opacity: low, so the textures stay readable
const WAVE_ALPHA := 0.55  ## opacity while the wave climbs
const FLASH := 0.30  ## the seating flash (kept low: the model must never turn white)
const SKIP_PREFIXES := ["Guard", "Shield", "BurstRing", "ReadyRing", "Armor"]

var fx: BattleFx
var _aura: Dictionary = {}  ## Combatant -> ArmorVfx (the sparkles while the badge lasts)
var _film: Dictionary = {}  ## Combatant -> {mat, meshes: Array[MeshInstance3D], tween, pending}


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


## Armored Bulk starts (its wind-up is instant): the victory animation, the climbing wave and the particle layer.
func begin(inc) -> void:
	var c: Combatant = inc.attacker
	var m: Node3D = fx._models.get(c)
	if m == null or not is_instance_valid(m):
		return
	fx._play(c, "victory")  # creator: the character's victory animation, whole
	var box := _body_box(m)
	var h := box.size.y if box.size.y > 0.1 else 1.6
	print("[armor] body h=%.2f for %s" % [h, c.name])
	ArmorVfx.spawn(fx, ArmorVfx.Mode.BULK, Vector3(m.global_position.x, 0.0, m.global_position.z), h)
	# D-1061: the eco textual "ARMOR!" lands with the release (the chrome wave reaching the head).
	var top := box.end.y if box.size.y > 0.1 else 1.6
	fx.get_tree().create_timer(WAVE, false).timeout.connect(func() -> void:
		if is_instance_valid(m) and fx != null and fx.is_inside_tree():
			ArmorEcho.spawn(fx, m, top, h))
	if _film.has(c):
		_pulse(c, FLASH)  # a recast on a live badge: only a pulse, the film is already there
		return
	var film := _make(c, m, box)
	if film.is_empty():
		return
	film["pending"] = true
	var mat: ShaderMaterial = film["mat"]
	mat.set_shader_parameter("reveal", 0.0)
	mat.set_shader_parameter("alpha", WAVE_ALPHA)
	var tw := fx.create_tween()
	film["tween"] = tw
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("reveal", v), 0.0, 1.0, WAVE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void: mat.set_shader_parameter("flash", FLASH))  # the release: the flash seats the film
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("flash", v), FLASH, 0.0, 0.22)
	tw.parallel().tween_method(func(v: float) -> void: mat.set_shader_parameter("alpha", v), WAVE_ALPHA, SETTLED_ALPHA, 0.40)


## Battle.armor_changed: "started", "extended", "hit", "expired" or "battle_end".
func on_armor_changed(c: Combatant, state: String) -> void:
	match state:
		"started":
			_start_aura(c)
			if _film.has(c):
				_film[c]["pending"] = false
			else:
				var m: Node3D = fx._models.get(c)
				if m != null and is_instance_valid(m):
					var film := _make(c, m, _body_box(m))  # armor from some other path (debug room): the film appears seated
					if not film.is_empty():
						(film["mat"] as ShaderMaterial).set_shader_parameter("alpha", SETTLED_ALPHA)
		"extended":
			_pulse(c, FLASH)
		"hit":
			_stop_aura(c)
			_break_burst(c)
			_fade(c, 0.08)  # the film leaves as plates (ArmorVfx BREAK), so it is gone at once
		"expired", "battle_end":
			_stop_aura(c)
			_fade(c, 0.4)


## The status pause ended: a film whose badge never came (the caster was cancelled) goes away.
func on_status_pause_ended(inc) -> void:
	var c: Combatant = inc.attacker
	if _film.has(c) and bool(_film[c].get("pending", false)) and not c.is_armored():
		_fade(c, 0.3)


func _start_aura(c: Combatant) -> void:
	if _aura.has(c) and is_instance_valid(_aura[c]):
		return
	var m: Node3D = fx._models.get(c)
	if m == null or not is_instance_valid(m):
		return
	var box := _body_box(m)
	_aura[c] = ArmorVfx.spawn_aura(fx, c, m, box.size.y if box.size.y > 0.1 else 1.6)


func _stop_aura(c: Combatant) -> void:
	if _aura.has(c) and is_instance_valid(_aura[c]):
		(_aura[c] as ArmorVfx).queue_free()
	_aura.erase(c)


func _make(c: Combatant, m: Node3D, box: AABB) -> Dictionary:
	var meshes: Array[MeshInstance3D] = []
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null or _skip(String(m3.name)):
			continue
		meshes.append(m3)
	if meshes.is_empty():
		return {}
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("base_y", box.position.y)
	mat.set_shader_parameter("top_y", box.end.y)
	mat.set_shader_parameter("alpha", SETTLED_ALPHA)
	for m3 in meshes:
		m3.material_overlay = mat
	var film := {"mat": mat, "meshes": meshes, "tween": null, "pending": false}
	_film[c] = film
	return film


func _pulse(c: Combatant, strength: float) -> void:
	if not _film.has(c):
		return
	var mat: ShaderMaterial = _film[c]["mat"]
	mat.set_shader_parameter("flash", strength)
	var tw := fx.create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("flash", v), strength, 0.0, 0.25)


func _fade(c: Combatant, seconds: float) -> void:
	if not _film.has(c):
		return
	var film: Dictionary = _film[c]
	_film.erase(c)
	if film["tween"] != null and (film["tween"] as Tween).is_valid():
		(film["tween"] as Tween).kill()
	var mat: ShaderMaterial = film["mat"]
	var tw := fx.create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("alpha", v), float(mat.get_shader_parameter("alpha")), 0.0, seconds)
	tw.tween_callback(func() -> void:
		for m3 in film["meshes"]:
			if is_instance_valid(m3) and (m3 as MeshInstance3D).material_overlay == mat:
				(m3 as MeshInstance3D).material_overlay = null)


func _break_burst(c: Combatant) -> void:
	var m: Node3D = fx._models.get(c)
	if m == null or not is_instance_valid(m):
		return
	var box := _body_box(m)
	var chest := Vector3(m.global_position.x, box.get_center().y if box.size.y > 0.1 else 1.1, m.global_position.z)
	ArmorVfx.spawn(fx, ArmorVfx.Mode.BREAK, chest, box.size.y if box.size.y > 0.1 else 1.6)


static func _skip(node_name: String) -> bool:
	for p in SKIP_PREFIXES:
		if node_name.begins_with(p):
			return true
	return false


## Public so other echoes (MP) measure the same real body.
func body_box_of(m: Node3D) -> AABB:
	return _body_box(m)


## The world box of the real model's meshes (helper rings, shields and our own overlay excluded).
func _body_box(m: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null or _skip(String(m3.name)):
			continue
		var b := m3.global_transform * m3.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box if not first else AABB()
