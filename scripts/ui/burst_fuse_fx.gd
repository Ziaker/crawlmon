extends Node
## D-1296: visual of the burst fuse over the FIGHT block of the FanMenu. UI, not a Move (D-1222 does not apply).
## - The rope is REAL 3D: a lit cylinder with a helix texture and a charred glowing tip, rendered by a transparent
##   SubViewport and drawn over the top edge of the block (creator: "perfeito" to the 3D rope of the prototype).
## - Wavy 2D flames (red, orange, yellow, white) inside the block, sliced to its slant.
## - Faceted flame / shard / smoke particles (head of the fuse and the small explosion of the click) are drawn
##   in 2D as cut polygons, ported from prototypes/burst_fuse/index.html.
## Everything runs on a REAL clock (the caller passes delta / time_scale), so the burst slow-motion does not slow it.

const SKEW := 8.0  ## Slant of the blocks (FanMenu._slant).
const SPEED := 1.9  ## Wave speed of the prototype ("SP").
const SCALE := 38.0 / 52.0  ## Prototype block was 52 px high, the game block is 38.
const WAVE_K := 320.0 / 232.0  ## Keeps the same number of waves across a narrower block.
const ROPE_RADIUS := 4.1
const TIP_LENGTH := 10.0
const VIEW_PAD := 20.0  ## Room of the rope viewport above/below the rope and at its ends.
const PX := 2  ## Rope viewport resolution (supersampling).

const LAYERS := [
	{"c": Color(224 / 255.0, 58 / 255.0, 30 / 255.0), "h": 80.0, "k": 0.05, "w": 2.4, "p": 0.0},
	{"c": Color(255 / 255.0, 171 / 255.0, 64 / 255.0), "h": 63.0, "k": 0.06, "w": 3.1, "p": 1.9},
	{"c": Color(255 / 255.0, 216 / 255.0, 74 / 255.0), "h": 45.0, "k": 0.072, "w": 3.8, "p": 3.4},
	{"c": Color(255 / 255.0, 248 / 255.0, 224 / 255.0), "h": 27.0, "k": 0.088, "w": 4.6, "p": 5.0},
]

## Cut polygons (128 x 128 sprite space) of the prototype.
const FLAME_POLY := [Vector2(64, 2), Vector2(84, 42), Vector2(74, 54), Vector2(100, 86), Vector2(86, 122), Vector2(42, 122), Vector2(28, 86), Vector2(54, 58), Vector2(44, 44)]
const SHARD_OUTER := [Vector2(64, 2), Vector2(84, 64), Vector2(64, 126), Vector2(44, 64)]
const SHARD_INNER := [Vector2(64, 22), Vector2(74, 64), Vector2(64, 106), Vector2(54, 64)]
const SMOKE_OUTER := [Vector2(22, 70), Vector2(40, 26), Vector2(82, 18), Vector2(112, 52), Vector2(104, 100), Vector2(62, 114), Vector2(30, 102)]
const SMOKE_LIGHT := [Vector2(40, 26), Vector2(82, 18), Vector2(70, 62), Vector2(44, 70)]

enum Kind { FLAME, SHARD, SMOKE }

var active := false
var _dur := 2.0
var _elapsed := 0.0
var _clock := 0.0
var _amp := 0.0
var _rng := RandomNumberGenerator.new()
var _parts: Array = []  # {k, x, y, vx, vy, age, life, size, rot, grav, grow}
var _acc_flame := 0.0
var _acc_spark := 0.0
var _acc_smoke := 0.0
var _pop_t := -1.0
var _pop_rect := Rect2()

var _vp: SubViewport
var _rope: MeshInstance3D
var _rope_mat: StandardMaterial3D
var _tip: MeshInstance3D
var _tip_mat: StandardMaterial3D
var _glow: OmniLight3D
var _vp_origin := Vector2.ZERO  # top-left of the rope viewport in the menu's local space
var _vp_size := Vector2.ZERO
var _head_x := 0.0  # head of the fuse, menu local x
var _rope_y := 0.0


func _ready() -> void:
	_rng.randomize()


## Lights the fuse for `seconds` real seconds (the same time of the perfect-Evade slow-motion).
func start(seconds: float) -> void:
	_ensure_view()
	_dur = maxf(seconds, 0.01)
	_elapsed = 0.0
	_amp = 0.0
	active = true
	_acc_flame = 0.0
	_acc_spark = 0.0
	_acc_smoke = 0.0
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS


## Ends the fuse. `cut` = the player clicked FIGHT: the small explosion and the pop of the block play over `block`.
func stop(block: Rect2, cut: bool) -> void:
	if not active:
		return
	active = false
	if _vp != null:
		_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if cut:
		_explode(block.get_center())
		_pop_t = 0.0
		_pop_rect = block


## True while something must keep being redrawn (fuse, particles, pop).
func busy() -> bool:
	return active or not _parts.is_empty() or _pop_t >= 0.0


func advance(dt: float) -> void:
	_clock += dt
	if active:
		_elapsed += dt
		_amp = minf(1.0, _amp + dt * 5.0)
		_emit(dt)
	_step_particles(dt)
	if _pop_t >= 0.0:
		_pop_t += dt
		if _pop_t >= 0.32:
			_pop_t = -1.0


func _emit(dt: float) -> void:
	_acc_flame += 34.0 * dt
	_acc_spark += 70.0 * dt
	_acc_smoke += 12.0 * dt
	while _acc_flame >= 1.0:
		_acc_flame -= 1.0
		var sp := _rng.randf_range(40.0, 90.0) * SCALE
		_spawn(Kind.FLAME, Vector2(_head_x + _rng.randf_range(-3.0, 3.0), _rope_y - 2.0), Vector2(_rng.randf_range(-0.25, 0.25), -1.0) * sp, _rng.randf_range(0.2, 0.38), _rng.randf_range(15.0, 26.0) * SCALE, 0.0, 0.0, _rng.randf_range(-0.35, 0.35))
	while _acc_spark >= 1.0:
		_acc_spark -= 1.0
		var a := _rng.randf() * TAU
		var d := Vector2(cos(a) * 1.1, -(sin(a) * 0.9 + 0.35))
		var sp2 := _rng.randf_range(120.0, 300.0) * SCALE
		_spawn(Kind.SHARD, Vector2(_head_x, _rope_y), d * sp2, _rng.randf_range(0.3, 0.65), _rng.randf_range(7.0, 13.0) * SCALE, 380.0 * SCALE, 0.0, atan2(d.x, -d.y))
	while _acc_smoke >= 1.0:
		_acc_smoke -= 1.0
		var sp3 := _rng.randf_range(14.0, 30.0) * SCALE
		_spawn(Kind.SMOKE, Vector2(_head_x, _rope_y - 14.0 * SCALE), Vector2(_rng.randf_range(-0.35, 0.35), -1.0) * sp3, _rng.randf_range(0.9, 1.5), _rng.randf_range(8.0, 14.0) * SCALE, 0.0, 1.0, _rng.randf() * TAU)


func _explode(at: Vector2) -> void:
	for i in 13:
		var a := _rng.randf() * TAU
		var d := Vector2(cos(a), sin(a))
		_spawn(Kind.FLAME, at, d * _rng.randf_range(110.0, 250.0) * SCALE, _rng.randf_range(0.35, 0.65), _rng.randf_range(32.0, 56.0) * SCALE, 0.0, 0.0, atan2(d.x, -d.y))
	for i in 18:
		var a2 := _rng.randf() * TAU
		var d2 := Vector2(cos(a2), sin(a2))
		_spawn(Kind.SHARD, at, d2 * _rng.randf_range(180.0, 380.0) * SCALE, _rng.randf_range(0.3, 0.6), _rng.randf_range(9.0, 16.0) * SCALE, 0.0, 0.0, atan2(d2.x, -d2.y))
	for i in 3:
		var a3 := _rng.randf() * TAU
		var d3 := Vector2(cos(a3), sin(a3))
		_spawn(Kind.SMOKE, at, d3 * _rng.randf_range(40.0, 110.0) * SCALE, _rng.randf_range(0.5, 0.9), _rng.randf_range(12.0, 20.0) * SCALE, 0.0, 2.0, _rng.randf() * TAU)


func _spawn(kind: int, pos: Vector2, vel: Vector2, life: float, size: float, grav: float, grow: float, rot: float) -> void:
	_parts.append({"k": kind, "x": pos.x, "y": pos.y, "vx": vel.x, "vy": vel.y, "age": 0.0, "life": life, "size": size, "rot": rot, "grav": grav, "grow": grow})


func _step_particles(dt: float) -> void:
	var i := _parts.size() - 1
	while i >= 0:
		var p: Dictionary = _parts[i]
		p["age"] = float(p["age"]) + dt
		if float(p["age"]) >= float(p["life"]):
			_parts.remove_at(i)
		else:
			p["vy"] = float(p["vy"]) + float(p["grav"]) * dt
			p["x"] = float(p["x"]) + float(p["vx"]) * dt
			p["y"] = float(p["y"]) + float(p["vy"]) * dt
		i -= 1


# ---------------------------------------------------------------- 2D wavy flames

## Wavy flames of the four layers inside the FIGHT block `r` (before its text is drawn).
func draw_flames(ci: CanvasItem, r: Rect2) -> void:
	if not active or _amp <= 0.01:
		return
	var top := r.position.y
	var bot := r.end.y
	var hgt := r.size.y
	var u0 := r.position.x
	var u1 := r.end.x - SKEW
	var step := 3.0
	var n := int(ceil((u1 - u0) / step))
	for L in LAYERS:
		var h: float = float(L["h"]) * SCALE * _amp
		var k: float = float(L["k"])
		var w: float = float(L["w"])
		var ph: float = float(L["p"])
		var col: Color = L["c"]
		var pulse := 0.78 + 0.22 * sin(_clock * w * SPEED * 1.3 + ph * 3.0)
		var prev_u := u0
		var prev_y := _flame_y(u0 - r.position.x, bot, top, h, k, w, ph)
		for i in n:
			var ub := minf(u1, u0 + (i + 1) * step)
			var yb := _flame_y(ub - r.position.x, bot, top, h, k, w, ph)
			var pa := Vector2(_shear(prev_u, prev_y, top, hgt), prev_y)
			var pb := Vector2(_shear(ub, yb, top, hgt), yb)
			var pc := Vector2(ub, bot)
			var pd := Vector2(prev_u, bot)
			var ca := Color(col, _flame_alpha(prev_y, bot, h) * pulse)
			var cb := Color(col, _flame_alpha(yb, bot, h) * pulse)
			var cc := Color(col, pulse)
			ci.draw_polygon(PackedVector2Array([pa, pb, pc, pd]), PackedColorArray([ca, cb, cc, cc]))
			prev_u = ub
			prev_y = yb


func _flame_y(local_u: float, bot: float, top: float, h: float, k: float, w: float, ph: float) -> float:
	var x := local_u * WAVE_K + 60.0
	var th := x * k - _clock * w * SPEED + ph
	var f := 0.5 + 0.5 * sin(th + 0.9 * sin(th * 0.5 + _clock * 2.2))
	var g := 0.5 + 0.5 * sin(x * 0.021 + _clock * w * SPEED * 0.6 + ph * 2.0)
	return maxf(top, bot - h * (0.3 + 0.7 * pow(f, 2.4)) * (0.75 + 0.25 * g))


## x of a point of the strip at height y: the left/right edges of the block lean by SKEW.
func _shear(u: float, y: float, top: float, hgt: float) -> float:
	return u + SKEW * (1.0 - (y - top) / hgt)


func _flame_alpha(y: float, bot: float, h: float) -> float:
	if h <= 0.01:
		return 0.0
	var t := clampf((bot - y) / h, 0.0, 1.0)
	return lerpf(1.0, 0.7, t / 0.45) if t < 0.45 else lerpf(0.7, 0.12, (t - 0.45) / 0.55)


# ---------------------------------------------------------------- 3D rope + particles

## Rope, tip and particles over the top edge of the FIGHT block `r` (after the rows). The rope is rendered
## by the SubViewport: its nodes are placed here, in real time.
func draw_over(ci: CanvasItem, r: Rect2) -> void:
	if active:
		var left := r.position.x + SKEW
		var right := r.end.x
		var f := clampf(_elapsed / _dur, 0.0, 1.0)
		_head_x = lerpf(left, right, f)
		_rope_y = r.position.y - ROPE_RADIUS - 0.3
		_place_rope(right)
		if _vp != null and _vp.get_texture() != null:
			ci.draw_texture_rect(_vp.get_texture(), Rect2(_vp_origin, _vp_size), false)
	_draw_particles(ci)


func _draw_particles(ci: CanvasItem) -> void:
	for p in _parts:
		var u := float(p["age"]) / float(p["life"])
		var alpha := 1.0 - u
		var center := Vector2(float(p["x"]), float(p["y"]))
		var size := float(p["size"])
		match int(p["k"]):
			Kind.FLAME:
				size *= _bez(1.0, 0.9, 0.6, 0.1, u)
				var anchor := Vector2(64, 122)
				_poly(ci, FLAME_POLY, Color("e03a1e", alpha), center, size, float(p["rot"]), 1.0, anchor)
				_poly(ci, FLAME_POLY, Color("ffab40", alpha), center, size, float(p["rot"]), 0.68, anchor)
				_poly(ci, FLAME_POLY, Color("ffe066", alpha), center, size, float(p["rot"]), 0.4, anchor)
			Kind.SHARD:
				size *= _bez(1.0, 0.9, 0.6, 0.1, u)
				_poly(ci, SHARD_OUTER, Color("ffd23a", alpha), center, size, float(p["rot"]), 1.0, Vector2(64, 64))
				_poly(ci, SHARD_INNER, Color("fff6d6", alpha), center, size, float(p["rot"]), 1.0, Vector2(64, 64))
			Kind.SMOKE:
				var base := 0.6 if float(p["grow"]) == 1.0 else 0.7
				size *= _bez(base, 1.0, 1.4, 1.8, u)
				_poly(ci, SMOKE_OUTER, Color("7d8590", alpha * 0.85), center, size, float(p["rot"]), 1.0, Vector2(64, 64))
				_poly(ci, SMOKE_LIGHT, Color("a6adb8", alpha * 0.85), center, size, float(p["rot"]), 1.0, Vector2(64, 64))


## Cubic bezier of the prototype's SizeOverLife (values at the 4 control points, evaluated at u).
func _bez(a: float, b: float, c: float, d: float, u: float) -> float:
	var v := 1.0 - u
	return v * v * v * a + 3.0 * v * v * u * b + 3.0 * v * u * u * c + u * u * u * d


## One cut polygon of the 128-px sprite space: scaled by `shrink` about `anchor`, sized to `size`, rotated by `rot`.
func _poly(ci: CanvasItem, pts: Array, color: Color, center: Vector2, size: float, rot: float, shrink: float, anchor: Vector2) -> void:
	var out := PackedVector2Array()
	var cs := cos(rot)
	var sn := sin(rot)
	for q in pts:
		var v: Vector2 = anchor + (q - anchor) * shrink
		var off: Vector2 = (v - Vector2(64, 64)) / 128.0 * size
		out.append(center + Vector2(off.x * cs - off.y * sn, off.x * sn + off.y * cs))
	ci.draw_colored_polygon(out, color)


## Pop of the block at the click (the prototype's `bpop`: scale 1.08 x 1.16 with a flash, 0.32 s).
func draw_pop(ci: CanvasItem) -> void:
	if _pop_t < 0.0:
		return
	var u := _pop_t / 0.32
	var c := _pop_rect.get_center()
	var sx := lerpf(1.0, 1.08, sin(u * PI))
	var sy := lerpf(1.0, 1.16, sin(u * PI))
	var hw := _pop_rect.size.x * 0.5 * sx
	var hh := _pop_rect.size.y * 0.5 * sy
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - hw + SKEW, c.y - hh), Vector2(c.x + hw, c.y - hh),
		Vector2(c.x + hw - SKEW, c.y + hh), Vector2(c.x - hw, c.y + hh)]), Color(1.0, 0.82, 0.55, (1.0 - u) * 0.85))


# ---------------------------------------------------------------- 3D scene

func _ensure_view() -> void:
	if _vp != null:
		return
	_vp = SubViewport.new()
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.85
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.environment = env
	cam.position = Vector3(0, 0, 200)
	_vp.add_child(cam)
	_cam = cam
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.5
	_vp.add_child(sun)
	sun.look_at_from_position(Vector3(-200, 420, 520), Vector3.ZERO)
	_glow = OmniLight3D.new()
	_glow.light_color = Color("ff7a20")
	_glow.omni_range = 140.0 * SCALE
	_glow.omni_attenuation = 0.0
	_vp.add_child(_glow)
	var cyl := CylinderMesh.new()
	cyl.top_radius = ROPE_RADIUS
	cyl.bottom_radius = ROPE_RADIUS
	cyl.height = 1.0
	cyl.radial_segments = 20
	cyl.rings = 1
	_rope_mat = StandardMaterial3D.new()
	_rope_mat.albedo_texture = _rope_texture()
	_rope_mat.texture_repeat = true
	_rope_mat.roughness = 0.9
	_rope = MeshInstance3D.new()
	_rope.mesh = cyl
	_rope.material_override = _rope_mat
	_rope.rotation_degrees = Vector3(0, 0, 90)
	_vp.add_child(_rope)
	var tip_mesh := CylinderMesh.new()
	tip_mesh.top_radius = ROPE_RADIUS - 0.4
	tip_mesh.bottom_radius = ROPE_RADIUS + 0.2
	tip_mesh.height = 1.0
	tip_mesh.radial_segments = 20
	tip_mesh.rings = 1
	_tip_mat = StandardMaterial3D.new()
	_tip_mat.albedo_color = Color("2a1a12")
	_tip_mat.roughness = 1.0
	_tip_mat.emission_enabled = true
	_tip_mat.emission = Color("ff4a08")
	_tip = MeshInstance3D.new()
	_tip.mesh = tip_mesh
	_tip.material_override = _tip_mat
	_tip.rotation_degrees = Vector3(0, 0, 90)
	_vp.add_child(_tip)


var _cam: Camera3D


## Rope colors and diagonal stripes of the prototype (cream #ead2a0, brown #9a6a3a, dark top edge).
func _rope_texture() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var cream := Color("ead2a0")
	var brown := Color("9a6a3a")
	for y in 64:
		for x in 64:
			var d := fposmod(float(y) + float(x) * 0.25 + 2.0, 16.0)
			var c := brown if d <= 10.0 else cream
			if y < 3:
				c = c.lerp(Color(60 / 255.0, 30 / 255.0, 10 / 255.0), 0.35)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Moves the 3D nodes to the current head position and sizes the viewport around the rope.
func _place_rope(right: float) -> void:
	var left := _head_x - VIEW_PAD
	var width := right - left + VIEW_PAD * 2.0
	var height := (ROPE_RADIUS + VIEW_PAD) * 2.0
	_vp_origin = Vector2(left, _rope_y - height * 0.5)
	_vp_size = Vector2(width, height)
	var px := Vector2i(int(ceil(width * PX)), int(ceil(height * PX)))
	if _vp.size != px:
		_vp.size = px
	_cam.size = height
	_cam.position = Vector3(width * 0.5, 0.0, 200.0)
	var flick := 0.85 + 0.15 * sin(_clock * 1000.0 / 38.0) + 0.1 * sin(_clock * 1000.0 / 23.0)
	var wx := _head_x - left  # world x (1 unit = 1 menu px), origin at the viewport's left
	var rlen := maxf(0.01, right - (_head_x + TIP_LENGTH))
	_rope.visible = rlen > 1.0
	_rope.scale = Vector3(1, rlen, 1)
	_rope.position = Vector3(wx + TIP_LENGTH + rlen * 0.5, 0.0, 0.0)
	_rope_mat.uv1_scale = Vector3(1.0, rlen / 12.0, 1.0)
	_tip.scale = Vector3(1, TIP_LENGTH, 1)
	_tip.position = Vector3(wx + TIP_LENGTH * 0.5, 0.0, 0.0)
	_tip_mat.emission_energy_multiplier = 1.2 + flick
	_glow.position = Vector3(wx + 6.0, 0.0, 26.0)
	_glow.light_energy = 2.4 + 1.6 * flick
