class_name FxGuard
extends RefCounted
## D-272: the Guard shield. A flat heater shield, white and translucent so the character can be seen
## through it, with no border, standing in front of the character (toward its opponent). It builds itself
## when the Guard starts (wedge pieces slide in and assemble). Over the 2 seconds of the Guard it CRACKS
## (straight cracks, like pizza slices, appear and grow, so you can see when it is about to end) and, when the time runs out, it breaks
## into irregular shards. When contact destroys it earlier, it flashes white and breaks the same way. "GUARD" (white, Impact)
## sits on top of the shield: it pops in letter by letter and is shot out in a fan on contact.
## The same for every character and every side of the field (D-235).
## The dome barrier is kept for a future Protect move in fx_barrier.gd (D-273).
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

const SHIELD_HEIGHT := 1.6  ## Shield height relative to the character's height.
const SHIELD_ASPECT := 0.85  ## Width / height.
const FRONT_DISTANCE := 0.45  ## How far in front of the character the shield stands, as a fraction of its width.
const FACE_ALPHA := 0.38  ## One flat translucent white: the character shows through. No border, no gradient.
const COLOR_BOOST := 1.7  ## The arena's tone mapping dulls flat colors; this keeps the white white.
const CURVE_STEPS := 9  ## Samples per curved side of the outline.
const BUILD_SECONDS := 0.28  ## How long each wedge takes to slide into place.
const BUILD_STAGGER := 0.012  ## Delay between one wedge and the next.
const FLASH_SECONDS := 0.08  ## The shield turns solid white this long before it breaks.
const SHARD_SECONDS := 0.6

const SLICES := 8  ## The shield is cut like a pizza: this many straight cracks from its center, and the same number of pieces.
const CRACK_WIDTH := 0.022  ## Crack thickness, as a fraction of the shield width.
const CRACK_COLOR := Color(0.04, 0.09, 0.2, 0.75)  ## Dark flat lines on the white face.

const FONT_NAMES := ["Impact", "Arial Black"]  ## The HUD title font.
const LETTERS := "GUARD"
const LETTER_GRAVITY := 12.0
const LETTER_SECONDS := 0.5  ## How long the flying letters live after the contact.
const LETTER_FADE := 0.2  ## They fade out during the last part of that time.
## The letters' size on screen (D-274 correction, from perception-tool findings). Glyph height as a fraction of the
## screen height: the ceiling is how large they already looked on the nearest character, the floor how small they
## looked on the middle one (both already approved), so far characters stay legible and near ones are unchanged.
const LETTER_MAX_SCREEN := 0.0733
const LETTER_MIN_SCREEN := 0.032
const LETTER_GLYPH := 0.79  ## Glyph height per unit of letter scale (font_size 110 x pixel_size 0.01 x cap height).
const LETTER_TOP_MARGIN := 0.05  ## The letters never go above this fraction of the screen from the top edge.

## Flat unlit color (from the vertex colors; white for the letters). A mesh can carry a reveal order in
## UV.x: parts with UV.x above `reveal` are hidden (the cracks grow this way). The letters are drawn over
## everything and face the camera (`billboard`); the shield keeps its place in the world.
const FLAT_SHADER := "
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled;
uniform float alpha = 1.0;
uniform float boost = 1.0;
uniform float billboard = 1.0;
uniform float reveal = 2.0;
varying float rv;
void vertex() {
	rv = UV.x;
	if (billboard > 0.5) {
		vec3 sc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sc.x, INV_VIEW_MATRIX[1] * sc.y, INV_VIEW_MATRIX[2] * sc.z, MODEL_MATRIX[3]);
	}
}
void fragment() {
	if (rv > reveal) {
		discard;
	}
	ALBEDO = COLOR.rgb * boost;
	ALPHA = clamp(COLOR.a * alpha, 0.0, 1.0);
}
"

var fx: BattleFx
var _shields: Dictionary = {}  ## Combatant -> Node3D (the shield, in the world)
var _letters: Dictionary = {}  ## Combatant -> Node3D holding the letters (in the world)
var _shader: Shader
var _shader_over: Shader  ## Same, drawn over everything (the letters).
var _font: Font


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


func start(c: Combatant) -> void:
	var model: Node3D = fx._models.get(c)
	if model == null or not is_instance_valid(model):
		return
	_clear(c)
	var b := _bounds(model)
	var height_world: float = float(b.height) * model.global_transform.basis.get_scale().y
	var shield_h: float = height_world * SHIELD_HEIGHT
	var shield_w: float = shield_h * SHIELD_ASPECT
	var forward := model.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	# The tip of the shield touches the floor, so it stands on the ground in front of the character.
	var center := model.global_position + Vector3.UP * (shield_h * 0.5) + forward * (shield_w * FRONT_DISTANCE)
	var root := Node3D.new()
	root.name = "GuardShield"
	root.set_meta("size", Vector2(shield_w, shield_h))
	var base_angle := randf() * TAU  # Where the first crack points; the pieces break along the same lines.
	root.set_meta("base_angle", base_angle)
	fx.add_child(root)
	root.global_position = center
	root.look_at(center + forward, Vector3.UP, true)  # The shield's face (+Z) looks toward the opponent.
	# The finished shield is one seamless mesh, shown when the wedges have assembled.
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "ShieldMesh"
	mesh_node.mesh = _shield_mesh(shield_w, shield_h)
	mesh_node.material_override = _material(0.0, false)
	mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_node.visible = false
	root.add_child(mesh_node)
	var cracks_node := MeshInstance3D.new()
	cracks_node.name = "ShieldCracks"
	cracks_node.mesh = _crack_mesh(shield_w, shield_h, base_angle)
	var cracks_mat := _material(0.0, false)
	cracks_mat.render_priority = 1  # Over the face.
	cracks_mat.set_shader_parameter("reveal", 0.0)  # No crack yet; they grow with the Guard's time.
	cracks_node.material_override = cracks_mat
	cracks_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cracks_node.visible = false
	root.add_child(cracks_node)
	_shields[c] = root
	_build_animation(root, mesh_node, cracks_node, shield_w, shield_h)
	# The charge clip (looping) is the guarding pose.
	var gap := fx._anim_player(c)
	fx._play(c, "guard" if gap != null and gap.has_animation("guard") else "charge")  # D-1004
	fx._busy_for(c, Battle.GUARD_SECONDS + 0.4)
	_spawn_letters(c, center, shield_h)
	var tree := fx.get_tree()
	if tree != null and not tree.process_frame.is_connected(_on_frame):
		tree.process_frame.connect(_on_frame)


## The shield cracks as the guard time runs out: the cracks grow with the Guard's own timer.
func _on_frame() -> void:
	for c in _shields.keys():
		var root: Node3D = _shields[c]
		if root == null or not is_instance_valid(root):
			_shields.erase(c)
			continue
		var done := 1.0 - clampf((c as Combatant).guard_timer / Battle.GUARD_SECONDS, 0.0, 1.0)
		var cracks := root.get_node_or_null("ShieldCracks") as MeshInstance3D
		if cracks != null:
			(cracks.material_override as ShaderMaterial).set_shader_parameter("reveal", done)


## The shield builds itself: its wedge pieces slide in from outside, growing and fading in, then are
## replaced by the seamless mesh (the cracks then start to grow).
func _build_animation(root: Node3D, mesh_node: MeshInstance3D, cracks_node: MeshInstance3D, w: float, h: float) -> void:
	var outer := _outline(w, h, 1.0)
	var n := outer.size()
	var pieces := Node3D.new()
	pieces.name = "BuildPieces"
	root.add_child(pieces)
	var total := BUILD_SECONDS + BUILD_STAGGER * float(n)
	for i in n:
		var a := outer[i]
		var b := outer[(i + 1) % n]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_color(Color(1, 1, 1, FACE_ALPHA))
		for v in [Vector2.ZERO, a, b]:
			st.add_vertex(Vector3(v.x, v.y, 0.0))
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = _material(0.0, false)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pieces.add_child(mi)
		var mid := (a + b) * 0.5
		var away := mid.normalized() * (0.9 * h + randf_range(0.0, 0.3 * h))
		mi.position = Vector3(away.x, away.y, 0.0)  # In the shield's own plane.
		mi.scale = Vector3.ONE * 0.4
		var mat := mi.material_override as ShaderMaterial
		mat.set_shader_parameter("alpha", 0.0)
		var tw := mi.create_tween().set_parallel(true)
		var delay := BUILD_STAGGER * float(i)
		tw.tween_property(mi, "position", Vector3.ZERO, BUILD_SECONDS).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(mi, "scale", Vector3.ONE, BUILD_SECONDS).set_delay(delay)
		_alpha_tween(tw, mat, 0.0, 1.0, BUILD_SECONDS * 0.6, delay)
	var done := root.create_tween()
	done.tween_interval(total)
	done.tween_callback(func() -> void:
		if is_instance_valid(mesh_node):
			mesh_node.visible = true
		if is_instance_valid(cracks_node):
			cracks_node.visible = true
		if is_instance_valid(pieces):
			pieces.queue_free())


## reason: "hit" / "broken" flash and shatter it where it stands; "expired" shatters it (it has cracked all
## along); "battle_end" fades it out.
func stop(c: Combatant, reason: String) -> void:
	var root: Node3D = _shields.get(c)
	_shields.erase(c)
	fx._busy_until.erase(c)  # The guarding pose is over: the character goes back to its idle.
	fx.fx_motion._reset_idle(c)
	var holder: Node3D = _letters.get(c)
	_letters.erase(c)
	var broke := reason == "hit" or reason == "broken"
	if holder != null and is_instance_valid(holder):
		if broke:
			var model_for_dir: Node3D = fx._models.get(c)
			var fwd := Vector3.FORWARD
			if model_for_dir != null:
				fwd = model_for_dir.global_transform.basis.z
			_fling_letters(holder, fwd, reason == "broken")
		else:
			var ltw := holder.create_tween()
			ltw.tween_method(func(k: float) -> void: _set_letters_alpha(holder, 1.0 - k), 0.0, 1.0, 0.3)
			ltw.tween_callback(holder.queue_free)
	if root == null or not is_instance_valid(root):
		return
	var mesh_node := root.get_node_or_null("ShieldMesh") as MeshInstance3D
	if mesh_node == null or not mesh_node.visible:
		root.queue_free()  # Still assembling: it just goes.
		return
	if broke:
		# Contact: a quick solid-white flash (the cracks vanish into it), then the shards.
		var cracks_node := root.get_node_or_null("ShieldCracks") as MeshInstance3D
		if cracks_node != null:
			cracks_node.visible = false
		var flash := root.create_tween()
		_alpha_tween(flash, mesh_node.material_override as ShaderMaterial, 1.0, 3.0, FLASH_SECONDS)
		flash.tween_callback(func() -> void: _shatter(root, reason == "broken", 3.0))
	elif reason == "expired":
		_shatter(root, false, 1.0)  # The cracks it grew over the Guard give way.
	else:
		var tw := root.create_tween()
		_alpha_tween(tw, mesh_node.material_override as ShaderMaterial, 1.0, 0.0, 0.3)
		tw.tween_callback(root.queue_free)


func _clear(c: Combatant) -> void:
	var old: Node3D = _shields.get(c)
	if old != null and is_instance_valid(old):
		old.queue_free()
	_shields.erase(c)
	var old_letters: Node3D = _letters.get(c)
	if old_letters != null and is_instance_valid(old_letters):
		old_letters.queue_free()
	_letters.erase(c)


func _alpha_tween(tw: Tween, mat: ShaderMaterial, from: float, to: float, dur: float, delay := 0.0) -> void:
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("alpha", v), from, to, dur).set_delay(delay)


func _material(billboard: float, over_everything := true) -> ShaderMaterial:
	if _shader == null:
		_shader_over = Shader.new()
		_shader_over.code = FLAT_SHADER
		_shader = Shader.new()
		_shader.code = FLAT_SHADER.replace(", depth_test_disabled", "")
	var mat := ShaderMaterial.new()
	mat.shader = _shader_over if over_everything else _shader
	mat.set_shader_parameter("alpha", 1.0)
	mat.set_shader_parameter("boost", COLOR_BOOST)
	mat.set_shader_parameter("billboard", billboard)
	return mat


## The heater-shield outline around (0, 0): flat top, straight sides, then both sides curve in to the
## bottom point.
func _outline(w: float, h: float, grow: float) -> PackedVector2Array:
	var hw := 0.5 * w * grow
	var top := 0.5 * h * grow
	var shoulder := 0.12 * h * grow
	var tip := -0.5 * h * grow
	var pts := PackedVector2Array()
	pts.append(Vector2(-hw, top))
	pts.append(Vector2(hw, top))
	pts.append(Vector2(hw, shoulder))
	# Right side: quadratic Bezier from the shoulder to the tip, bulging out.
	var ctrl_r := Vector2(hw, tip * 0.55)
	for i in range(1, CURVE_STEPS + 1):
		var t := float(i) / float(CURVE_STEPS)
		pts.append((1.0 - t) * (1.0 - t) * Vector2(hw, shoulder) + 2.0 * (1.0 - t) * t * ctrl_r + t * t * Vector2(0.0, tip))
	# Left side, mirrored, back up.
	var ctrl_l := Vector2(-hw, tip * 0.55)
	for i in range(CURVE_STEPS - 1, -1, -1):
		var t2 := float(i) / float(CURVE_STEPS)
		pts.append((1.0 - t2) * (1.0 - t2) * Vector2(-hw, shoulder) + 2.0 * (1.0 - t2) * t2 * ctrl_l + t2 * t2 * Vector2(0.0, tip))
	return pts


## The flat shield: one translucent white fan from the center over the outline.
func _shield_mesh(w: float, h: float) -> ArrayMesh:
	var outer := _outline(w, h, 1.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(1, 1, 1, FACE_ALPHA))
	var n := outer.size()
	for i in n:
		for v in [Vector2.ZERO, outer[i], outer[(i + 1) % n]]:
			st.add_vertex(Vector3(v.x, v.y, 0.0))
	return st.commit()


## Where a ray from the shield's center (0, 0) leaves the outline. The outline is convex, so the hit is unique.
func _ray_hit(outline: PackedVector2Array, angle: float) -> Vector2:
	var d := Vector2(cos(angle), sin(angle))
	var best := INF
	var n := outline.size()
	for i in n:
		var a := outline[i]
		var b := outline[(i + 1) % n]
		var hit: Variant = Geometry2D.segment_intersects_segment(Vector2.ZERO, d * 100.0, a, b)
		if hit != null:
			best = minf(best, (hit as Vector2).length())
	return d * (best if best < INF else 0.5)


## The cracks: dark thin STRAIGHT lines, like pizza cuts: SLICES rays from the shield's center out to its
## edge, no branches, appearing one after another. Each vertex carries its reveal order in UV.x (0..1), so
## the shader grows them as the Guard's time passes.
func _crack_mesh(w: float, h: float, base_angle: float) -> ArrayMesh:
	var outline := _outline(w, h, 1.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_width := CRACK_WIDTH * w * 0.5
	for k in SLICES:
		var angle := base_angle + TAU * float(k) / float(SLICES)
		var tip := _ray_hit(outline, angle)
		var t0 := 0.5 * float(k) / float(SLICES)  # Staggered over the Guard's duration.
		_crack_line(st, Vector2.ZERO, tip, t0, t0 + 0.45, half_width)
	return st.commit()


## One straight crack line from a to b, revealed from reveal_a to reveal_b along its length.
func _crack_line(st: SurfaceTool, a: Vector2, b: Vector2, reveal_a: float, reveal_b: float, half_width: float) -> void:
	var dir := (b - a).normalized()
	var perp := Vector2(-dir.y, dir.x) * half_width
	var quad: Array = [[a + perp, reveal_a], [b + perp, reveal_b], [b - perp, reveal_b], [a + perp, reveal_a], [b - perp, reveal_b], [a - perp, reveal_a]]
	for q in quad:
		st.set_color(CRACK_COLOR)
		st.set_uv(Vector2(q[1], 0.0))
		st.add_vertex(Vector3(q[0].x, q[0].y, 0.0))


func _text_font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(FONT_NAMES)
		_font = f
	return _font


## "GUARD", white, letter by letter, on top of the shield and facing the camera.
func _spawn_letters(c: Combatant, center: Vector3, shield_h: float) -> void:
	var cam := fx._cam_pos()
	var size := shield_h * 0.30
	var camera := fx.get_viewport().get_camera_3d() if fx.is_inside_tree() else null
	if camera != null:  # Keep the letters readable (and inside the screen) whatever the distance and height.
		var view_h := 2.0 * camera.global_position.distance_to(center) * tan(deg_to_rad(camera.fov) * 0.5)
		size = clampf(size, LETTER_MIN_SCREEN * view_h / LETTER_GLYPH, LETTER_MAX_SCREEN * view_h / LETTER_GLYPH)
	var base := center + Vector3.UP * (shield_h * 0.5 + size * 0.7)
	if camera != null:
		var screen_h := float(fx.get_viewport().get_visible_rect().size.y)
		var glyph := LETTER_GLYPH * size
		var steps := 0
		while steps < 60 and not camera.is_position_behind(base) and camera.unproject_position(base + Vector3.UP * glyph).y < LETTER_TOP_MARGIN * screen_h and base.y > center.y:
			base.y -= glyph * 0.1  # Too high for the screen: lower the word onto the shield.
			steps += 1
	var yaw := atan2(cam.x - base.x, cam.z - base.z)
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var gap := 0.5 * size
	var holder := Node3D.new()
	holder.name = "GuardLetters"
	fx.add_child(holder)
	for i in LETTERS.length():
		var tm := TextMesh.new()
		tm.text = LETTERS[i]
		tm.font = _text_font()
		tm.font_size = 110
		tm.pixel_size = 0.01
		tm.depth = 0.0
		var mi := MeshInstance3D.new()
		mi.name = "Letter_%s_%d" % [LETTERS[i], i]
		mi.mesh = tm
		mi.material_override = _material(1.0, true)  # White, flat, facing the camera.
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)
		mi.global_position = base + right * ((float(i) - (LETTERS.length() - 1) * 0.5) * gap)
		mi.scale = Vector3.ZERO
		var tw := mi.create_tween()
		tw.tween_interval(float(i) * 0.05)
		tw.tween_property(mi, "scale", Vector3.ONE * size * 1.4, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(mi, "scale", Vector3.ONE * size, 0.1)
	_letters[c] = holder


func _set_letters_alpha(holder: Node3D, a: float) -> void:
	for l in holder.get_children():
		var mi := l as MeshInstance3D
		if mi != null:
			(mi.material_override as ShaderMaterial).set_shader_parameter("alpha", clampf(a, 0.0, 1.0))


## The contact destroys the shield: the letters are shot out each in a random direction, all around, fall a little with gravity, and vanish after LETTER_SECONDS (fading at the end).
func _fling_letters(holder: Node3D, forward: Vector3, big: bool) -> void:
	var letters := holder.get_children()
	var vel: Array[Vector3] = []
	var boost := 1.3 if big else 1.0
	for l in letters:
		# Each letter is shot in its own random direction, all around (the creator asked for every direction,
		# not a fan toward one side). Only the horizontal direction is random; the lift is always upward.
		var dir := Vector3.FORWARD.rotated(Vector3.UP, randf_range(-PI, PI))
		var spd := randf_range(5.0, 9.0) * boost  # Shot out fast: they only live half a second.
		vel.append(dir * spd + Vector3.UP * randf_range(1.5, 3.5) * boost)
	var last := [0.0]  # An array: a lambda copies plain variables, but shares arrays.
	var fade_from := 1.0 - LETTER_FADE / LETTER_SECONDS
	var tw := holder.create_tween()
	tw.tween_method(func(k: float) -> void:
		var dt := (k - float(last[0])) * LETTER_SECONDS
		last[0] = k
		for n in letters.size():
			var li := letters[n] as MeshInstance3D
			var v: Vector3 = vel[n]
			v.y -= LETTER_GRAVITY * dt
			vel[n] = v
			li.global_position += v * dt
		_set_letters_alpha(holder, 1.0 - clampf((k - fade_from) / (1.0 - fade_from), 0.0, 1.0)),
		0.0, 1.0, LETTER_SECONDS)
	tw.tween_callback(holder.queue_free)


## The body's height in the model's own space. The rings, the shield and the letters are not part of
## the body.
func _bounds(model: Node3D) -> Dictionary:
	var inv := model.global_transform.affine_inverse()
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for ch in n.get_children():
			stack.append(ch)
		if not (n is MeshInstance3D) or n.name.contains("Ring") or n.name.contains("Guard") or n.name.contains("Shield"):
			continue
		var mi := n as MeshInstance3D
		var t: Transform3D = inv * mi.global_transform
		for k in 8:
			var p: Vector3 = t * mi.get_aabb().get_endpoint(k)
			mn = mn.min(p)
			mx = mx.max(p)
	if mn.x == INF:
		return {"height": 2.2}
	return {"height": maxf(mx.y - mn.y, 0.8)}


## The pieces the shield breaks into: SLICES pizza slices, cut along the same lines as the cracks. Each is a
## polygon starting at the center, then the points on the edge (the outline's own corners and curve points
## between the two cracks, so a slice follows the shield's shape).
func _slices(w: float, h: float, base_angle: float) -> Array:
	var outline := _outline(w, h, 1.0)
	var result: Array = []
	for k in SLICES:
		var a0 := base_angle + TAU * float(k) / float(SLICES)
		var a1 := base_angle + TAU * float(k + 1) / float(SLICES)
		var pts: Array[Vector2] = [Vector2.ZERO, _ray_hit(outline, a0)]
		for v in outline:
			var ang := fposmod(atan2(v.y, v.x) - a0, TAU)
			if ang > 0.0 and ang < (a1 - a0):
				pts.append(v)
		pts.sort_custom(func(p: Vector2, q: Vector2) -> bool: return false)  # (keeps order; sorted by angle below)
		var rim: Array[Vector2] = []
		for i in range(1, pts.size()):
			rim.append(pts[i])
		rim.sort_custom(func(p: Vector2, q: Vector2) -> bool: return fposmod(atan2(p.y, p.x) - a0, TAU) < fposmod(atan2(q.y, q.x) - a0, TAU))
		rim.append(_ray_hit(outline, a1))
		var poly: Array[Vector2] = [Vector2.ZERO]
		poly.append_array(rim)
		result.append(poly)
	return result


## The shield breaks into its pizza slices, which fly apart, spin and fade.
func _shatter(root: Node3D, big: bool, start_alpha := 3.0) -> void:
	if not is_instance_valid(root):
		return
	var size: Vector2 = root.get_meta("size", Vector2(2.0, 2.4))
	var holder := Node3D.new()
	holder.name = "GuardShards"
	fx.add_child(holder)
	holder.global_transform = root.global_transform  # Same place and facing as the shield: local XY is its plane.
	var base_angle: float = root.get_meta("base_angle", 0.0)
	for poly in _slices(size.x, size.y, base_angle):
		var centroid := Vector2.ZERO
		for pt in poly:
			centroid += pt
		centroid /= float(poly.size())
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_color(Color(1, 1, 1, FACE_ALPHA))
		for i in range(1, poly.size() - 1):
			for v in [poly[0], poly[i], poly[i + 1]]:
				var local: Vector2 = v - centroid  # The piece spins around its own center.
				st.add_vertex(Vector3(local.x, local.y, 0.0))
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = _material(0.0, false)  # Billboard off: the piece keeps the shield's facing and tumbles.
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)
		mi.position = Vector3(centroid.x, centroid.y, 0.0)
		var out2 := centroid.normalized() * (randf_range(2.4, 3.6) if big else randf_range(1.5, 2.4))
		var out := Vector3(out2.x, out2.y + (1.2 if big else 0.6), randf_range(0.0, 0.5))
		var spin := randf_range(-4.0, 4.0)
		var start_pos := mi.position
		var tw := mi.create_tween().set_parallel(true)
		tw.tween_method(func(k: float) -> void:
			mi.position = start_pos + out * k + Vector3(0.0, -2.0 * k * k, 0.0),
			0.0, 1.0, SHARD_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(mi, "rotation:z", spin, SHARD_SECONDS)
		_alpha_tween(tw, mi.material_override as ShaderMaterial, start_alpha, 0.0, SHARD_SECONDS, 0.05)  # After a contact it starts as bright as the flash.
	root.queue_free()
	var cleanup := holder.create_tween()
	cleanup.tween_interval(SHARD_SECONDS + 0.2)
	cleanup.tween_callback(holder.queue_free)
