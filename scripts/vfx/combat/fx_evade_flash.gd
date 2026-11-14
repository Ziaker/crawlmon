class_name FxEvadeFlash
extends RefCounted
const DrainSpearMove = preload("res://scripts/data/drain_spear_move.gd")
## D-986: the Evade window (the PERFECT_WINDOW seconds of an enemy's strike that end PRELUDE_GAP before the contact, D-988) shown as a VFX on the
## attacker, like the Melee Counter tell of Metroid Dread: a bright white-yellow star burst (core + long thin rays)
## inside a thin golden ring, facing the camera. It replaces the gold highlight that the wind-up tag used to have.
## D-1029: the Fire Bullet is the only exception: its tell rides the tip of its own projectile, at the projectile's speed.
## Only visual: it reads Incoming.can_evade_now() and never touches the combat (D-019). Sizes and placement come from
## the attacker's real body and, for the Fire Bullet, from the real projectile: never from a name, species or side (D-235).

const RAYS := 12
const POP := 0.06  ## s: the ring snaps open
const FADE := 0.1  ## s: fades after the window closes
const FIRE_END_GAP := 0.12  ## D-1039: the Fire Bullet's Dread is gone this long before the hit
const FIRE_FADE := 0.02  ## D-1039: and its fade lasts this long inside that gap
const FIRE_SIZE := 1.2  ## D-1052: the Fire Bullet's Dread is 1.2x the body-derived size
## D-1202: every projectile Move (Skill.Kind.PROJECTILE) shows its tell ON THE PLAYER, up and to the side of the attacker,
## in the same window; Fire Bullet (D-1029) and Javelin Throw (D-1176) keep their own tip anchors. This replaces the
## D-1078 "no Dread" list (Tidal Surge, Bubble Shot).
const PLAYER_SCALE := 0.8  ## D-1202: the player-side tell is 20% smaller than the body-derived size
const PLAYER_ABOVE := 0.1  ## D-1202: its center sits this many tell radii above the top of the body (a bit above the ears)
const PLAYER_GAP := 0.25  ## D-1202: gap between the body's side and the ring center, in tell radii
const PLAYER_REACH_MIN := 0.12  ## D-1202: lateral reach limits, in body heights (adapts to wide and narrow bodies)
const PLAYER_REACH_MAX := 0.32
const PLAYER_RAD_MAX := 1.0  ## D-1202: very big bodies do not get a bigger tell than this (m)
const JAVELIN_MOVE := "javelin_throw"
const RING_COL := Color(1.0, 0.86, 0.3)
const CORE_COL := Color(1.0, 1.0, 0.9)
const RAY_COL := Color(1.0, 0.95, 0.65)

var fx: BattleFx
var _live: Dictionary = {}  ## Incoming -> {node, t, out}
static var _mat: StandardMaterial3D


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


func update(delta: float) -> void:
	if fx.battle == null:
		return
	var seen := {}
	var leader: Combatant = fx.battle.party[0] if not fx.battle.party.is_empty() else null
	# D-1203: no Dread unless the leader has the ATB the Evade costs; live ones go out at once.
	if not leader_can_afford_dodge(fx.battle, leader):
		for inc0 in _live.keys():
			var node0 := (_live[inc0] as Dictionary)["node"] as MeshInstance3D
			if is_instance_valid(node0):
				node0.queue_free()
		_live.clear()
		return
	for inc in fx.battle.active_attacks():
		if inc.attacker == null or inc.attacker.is_player:
			continue
		# D-1168: the Dread is the player's prompt; an attack aimed only at an ally is not dodgeable by the leader.
		if not targets_leader(inc, leader):
			continue
		if inc.skill != null and DrainSpearMove.reach(inc.skill) > 0.0:
			continue  # D-1016 (Drain Spear): that mid-range move has no Dread tell (melee only). D-1029: Fire Bullet is the exception.
		var on: bool = inc.can_evade_now()
		if on and not _live.has(inc):
			# D-1029: an instant Fire Bullet may not know its launch point on the first flight frame;
			# wait one frame for the real tip instead of showing the tell on the body.
			if inc.move_id in FireMoveVfx.IDS and _fire_tip(inc) == null:
				continue
			if _is_javelin(inc) and _javelin_tip(inc) == null:
				continue
			_live[inc] = {"node": _make(), "t": 0.0, "out": -1.0, "eta0": inc.eta()}
		if _live.has(inc):
			seen[inc] = true
			var st: Dictionary = _live[inc]
			if not on and float(st["out"]) < 0.0:
				st["out"] = 0.0
	for inc in _live.keys():
		var st: Dictionary = _live[inc]
		if not seen.has(inc) and float(st["out"]) < 0.0:
			st["out"] = 0.0
		st["t"] = float(st["t"]) + delta
		var node := st["node"] as MeshInstance3D
		# D-1039: the Fire Bullet's tell is gone FIRE_END_GAP seconds before the hit; the logic clock
		# (`Incoming.eta()`) drives it, never a separate visual timer.
		if inc.move_id in FireMoveVfx.IDS:
			var eta := maxf(inc.eta(), 0.0)
			if not seen.has(inc) or eta <= FIRE_END_GAP or not is_instance_valid(node):
				if is_instance_valid(node):
					node.queue_free()
				_live.erase(inc)
				continue
			_draw(node, inc, float(st["t"]), clampf((eta - FIRE_END_GAP) / FIRE_FADE, 0.0, 1.0))
			continue
		if float(st["out"]) >= 0.0:
			st["out"] = float(st["out"]) + delta
		if float(st["out"]) > FADE or not is_instance_valid(node):
			if is_instance_valid(node):
				node.queue_free()
			_live.erase(inc)
			continue
		var a := 1.0 - clampf(float(st["out"]) / FADE, 0.0, 1.0) if float(st["out"]) >= 0.0 else 1.0
		_draw(node, inc, float(st["t"]), a)


## D-1202: a projectile Move whose tell sits on the player (not Fire Bullet / Javelin, which ride their own tip).
static func on_player(inc) -> bool:
	if inc == null or inc.kind != Skill.Kind.PROJECTILE:
		return false
	return not (inc.move_id in FireMoveVfx.IDS) and not _is_javelin(inc)


## D-1203: the tell only shows while the leader can pay the Evade (real cost from the Battle, never a fixed 3).
## No leader or no battle: keep the old behavior (shown).
static func leader_can_afford_dodge(battle, leader) -> bool:
	if battle == null or leader == null:
		return true
	return leader.blocks() >= battle.evade_cost(leader)


## D-1168: the Dread belongs to the player's leader; an attack aimed only at an ally
## must not light it. An area attack that also reaches the leader still counts.
static func targets_leader(inc, leader) -> bool:
	if inc == null:
		return false
	if leader == null:
		return true
	return inc.target == leader or inc.is_aoe


func _make() -> MeshInstance3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.vertex_color_use_as_albedo = true
		_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat.no_depth_test = true
	var mi := MeshInstance3D.new()
	mi.name = "EvadeFlash"
	mi.mesh = ImmediateMesh.new()
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.top_level = true
	fx.add_child(mi)
	return mi


## Where the tell sits and how big: the upper front of the attacker's real body, toward its target.
## D-1029: Fire Bullet is the only exception: its tell rides the tip of its own projectile, at the
## projectile's speed, instead of the caster's hand or body.
func _anchor(inc) -> Array:
	if on_player(inc):
		return _player_anchor(inc)
	var an := _body_anchor(inc)
	var jt: Variant = _javelin_tip(inc)
	if jt != null:
		var stj: Dictionary = _live.get(inc, {})
		stj["pos"] = jt as Vector3
		stj["has_pos"] = true
		return [jt as Vector3, float(an[1])]
	if _is_javelin(inc):
		var stj2: Dictionary = _live.get(inc, {})
		if bool(stj2.get("has_pos", false)):
			return [stj2["pos"] as Vector3, float(an[1])]
	var tip: Variant = _fire_tip(inc)
	if tip != null:
		var st: Dictionary = _live.get(inc, {})
		st["pos"] = tip as Vector3
		st["has_pos"] = true
		return [tip as Vector3, float(an[1]) * FIRE_SIZE]
	# D-1029: the projectile ends on the impact; the fade stays where its tip was, never on the body.
	if inc.move_id in FireMoveVfx.IDS:
		var st2: Dictionary = _live.get(inc, {})
		if bool(st2.get("has_pos", false)):
			return [st2["pos"] as Vector3, float(an[1]) * FIRE_SIZE]
	return an


## D-1029: the Fire Bullet's own flight layer, at the tip of the flying bullet. Null for any other Move.
func _fire_tip(inc) -> Variant:
	if inc == null or not (inc.move_id in FireMoveVfx.IDS):
		return null
	var proj: Dictionary = inc.data.get("proj", {})
	var fire: Variant = proj.get("fire")
	if not is_instance_valid(fire):
		return null
	return (fire as FireMoveVfx).bullet_tip()


## D-1176: the Javelin Throw tell rides the real javelin tip, like the Fire Bullet (D-1029).
static func _is_javelin(inc) -> bool:
	if inc == null:
		return false
	return BattleSpace.move_id(String(inc.move_id)) == JAVELIN_MOVE


func _javelin_tip(inc) -> Variant:
	if not _is_javelin(inc):
		return null
	var j: Variant = inc.data.get("javelin")
	if not is_instance_valid(j):
		return null
	var n := j as Node
	if n == null or not n.has_method("javelin_tip"):
		return null
	return n.call("javelin_tip")


## D-1202: above the leader's head, shifted to the side of the screen where the attack comes from.
## Everything is read from the real bodies and the camera, never from a name, species or side (D-235).
func _player_anchor(inc) -> Array:
	var leader: Combatant = fx.battle.party[0] if not fx.battle.party.is_empty() else inc.target
	var m: Node3D = fx._models.get(leader)
	if m == null or not is_instance_valid(m):
		return [Vector3.ZERO, 0.8]
	var box := _body_box(m)
	if box.size == Vector3.ZERO:
		return [m.global_position + Vector3.UP * 2.0, 0.8]
	var rad := minf(clampf(box.size.y * 0.45, 0.45, 1.3) * PLAYER_SCALE, PLAYER_RAD_MAX)
	var cb := Basis.IDENTITY
	if fx.cam != null and fx.cam.camera != null:
		cb = fx.cam.camera.global_transform.basis.orthonormalized()
	var right := cb.x
	var am: Node3D = fx._models.get(inc.attacker)
	var toward := Vector3.ZERO
	if am != null and is_instance_valid(am):
		toward = am.global_position - m.global_position
	var side := 1.0 if toward.dot(right) >= 0.0 else -1.0
	var side_dir := right * side
	# How far the body really reaches toward that side of the screen (from its origin), within limits.
	var reach := 0.0
	for i in 8:
		var corner := box.get_endpoint(i)
		reach = maxf(reach, (corner - m.global_position).dot(side_dir))
	reach = clampf(reach, box.size.y * PLAYER_REACH_MIN, box.size.y * PLAYER_REACH_MAX)
	var p := Vector3(m.global_position.x, box.end.y + rad * PLAYER_ABOVE, m.global_position.z) + side_dir * (reach + rad * PLAYER_GAP)
	return [p, rad]


func _body_box(m: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for n in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or String(mi.name) in ["BurstRing", "ReadyRing"] or String(mi.name).begins_with("Stun"):
			continue
		var b := mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _body_anchor(inc) -> Array:
	var m: Node3D = fx._models.get(inc.attacker)
	if m == null or not is_instance_valid(m):
		return [Vector3.ZERO, 0.8]
	var box := AABB()
	var first := true
	for n in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or String(mi.name) in ["BurstRing", "ReadyRing"] or String(mi.name).begins_with("Stun"):
			continue
		var b := mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first:
		return [m.global_position + Vector3.UP, 0.8]
	# D-991: a held weapon marks the tell on the weapon itself (its middle), not beside the body.
	var w := SwingTrail.weapon_of(m)
	if not w.is_empty():
		var seg := SwingTrail.weapon_segment(w)
		if not seg.is_empty():
			return [((seg[0] as Vector3) + (seg[1] as Vector3)) * 0.5, clampf(box.size.y * 0.3, 0.45, 1.0)]
	# D-992: a body without hands or weapon (it hits with the whole body): the tell sits ABOVE it, not to the side.
	var has_hand := false
	for sk in m.find_children("*", "Skeleton3D", true, false):
		for bi in (sk as Skeleton3D).get_bone_count():
			var bn := (sk as Skeleton3D).get_bone_name(bi).to_lower()
			if "hand" in bn or "_te_" in bn or "hte" in bn or "weapon" in bn:
				has_hand = true
	if not has_hand:
		var cc := box.get_center()
		return [Vector3(cc.x, box.end.y + 0.25, cc.z), clampf(box.size.y * 0.45, 0.45, 1.3)]
	var tm: Node3D = fx._models.get(inc.target)
	var dir := Vector3.ZERO
	if tm != null and is_instance_valid(tm):
		dir = Vector3(tm.global_position.x - m.global_position.x, 0.0, tm.global_position.z - m.global_position.z)
		dir = dir.normalized() if dir.length() > 0.01 else Vector3.ZERO
	var c := box.get_center()
	var r := maxf(box.size.x, box.size.z) * 0.5
	# D-989: a little to the TARGET's left (target facing its attacker: left = UP x (attacker - target)).
	var left := Vector3.UP.cross(-dir) if dir != Vector3.ZERO else Vector3.ZERO
	var p := Vector3(c.x, box.position.y + box.size.y * 0.68, c.z) + dir * r * 0.6 + left * r * 0.45
	return [p, clampf(box.size.y * 0.45, 0.45, 1.3)]


## D-1039: the Fire Bullet's ring animation completes FIRE_END_GAP + FIRE_FADE seconds before the hit;
## the fade then consumes the last FIRE_FADE seconds and the tell is gone FIRE_END_GAP before the hit.
## Other Moves keep D-986.
func _window_k(inc, t: float) -> float:
	if not (inc.move_id in FireMoveVfx.IDS):
		return clampf(t / Battle.PERFECT_WINDOW, 0.0, 1.0)
	var st: Dictionary = _live.get(inc, {})
	var eta0: float = float(st.get("eta0", Battle.PERFECT_WINDOW))
	var anim_end := FIRE_END_GAP + FIRE_FADE
	var anim := maxf(eta0 - anim_end, 0.01)
	return clampf(1.0 - (maxf(inc.eta(), 0.0) - anim_end) / anim, 0.0, 1.0)


func _draw(node: MeshInstance3D, inc, t: float, a: float) -> void:
	var an := _anchor(inc)
	var pos: Vector3 = an[0]
	var rad: float = an[1]
	var cb := Basis.IDENTITY
	if fx.cam != null and fx.cam.camera != null:
		cb = fx.cam.camera.global_transform.basis.orthonormalized()
	node.global_transform = Transform3D(cb, pos)
	var pop := 1.0 - pow(1.0 - clampf(t / POP, 0.0, 1.0), 3.0)
	var r := rad * lerpf(0.55, 1.0, pop)
	var im := node.mesh as ImmediateMesh
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	# D-987: over the window the ring splits into arcs that drift apart and the whole ring opens a little.
	var wk := _window_k(inc, t)
	var rr := r * (1.0 + 0.25 * wk)
	var gap := 0.5 * wk
	# D-989: thicker, doubled (additive) ring and a wider glow so it reads at a glance.
	_annulus(im, rr * 0.94, rr, Color(RING_COL, 1.0 * a), gap, rr * 0.12 * wk)
	_annulus(im, rr * 0.955, rr * 0.985, Color(1, 1, 0.85, 1.0 * a), gap, rr * 0.12 * wk)
	_annulus(im, rr, rr * 1.12, Color(RING_COL, 0.45 * a), gap, rr * 0.12 * wk)
	# Long thin rays from the core (the star burst), turning slowly and pulsing.
	for i in RAYS:
		var ang := float(i) / float(RAYS) * TAU + t * 3.2  # D-987: the inner layer turns a little over the window
		var long := (1.0 if i % 2 == 0 else 0.55) * r * (0.9 + 0.15 * sin(t * 40.0 + float(i)))
		var w := r * (0.07 if i % 2 == 0 else 0.045)  # D-989: wider rays
		var d := Vector3(cos(ang), sin(ang), 0.0)
		var s := Vector3(-d.y, d.x, 0.0)
		_tri(im, s * w, -s * w, d * long * 1.15, Color(RAY_COL, 1.0 * a), Color(RAY_COL, 0.0))
		_tri(im, s * w * 0.5, -s * w * 0.5, d * long * 1.15, Color(1, 1, 1, 1.0 * a), Color(1, 1, 1, 0.0))  # hot white spine
	# Bright core: a hot centre and a wide soft glow.
	# D-989: a soft fill inside the ring (as in Dread) and a bigger, doubled hot core.
	_disc(im, rr * 0.95, Color(RING_COL, 0.28 * a), Color(RING_COL, 0.06 * a))
	_disc(im, r * 0.6, Color(RING_COL, 0.6 * a), Color(RING_COL, 0.0))
	_disc(im, r * 0.3, Color(CORE_COL, 1.0 * a), Color(CORE_COL, 0.0))
	_disc(im, r * 0.16, Color(1, 1, 1, 1.0 * a), Color(1, 1, 1, 0.2 * a))
	im.surface_end()


## A ring; with `gap` > 0 it is cut into ARCS arcs (gap = fraction of each arc left empty) pushed `push` outward.
const ARCS := 4


func _annulus(im: ImmediateMesh, r0: float, r1: float, col: Color, gap := 0.0, push := 0.0) -> void:
	var n := 48
	for i in n:
		var a0 := float(i) / float(n) * TAU
		var a1 := float(i + 1) / float(n) * TAU
		var seg := fmod(a0 / TAU * float(ARCS), 1.0)
		if gap > 0.0 and seg > 1.0 - gap:
			continue
		var mid: float = (floorf(a0 / TAU * float(ARCS)) + 0.5) / float(ARCS) * TAU
		var off := Vector3(cos(mid), sin(mid), 0.0) * push
		var p0 := Vector3(cos(a0), sin(a0), 0.0)
		var p1 := Vector3(cos(a1), sin(a1), 0.0)
		for v in [p0 * r0 + off, p0 * r1 + off, p1 * r1 + off, p0 * r0 + off, p1 * r1 + off, p1 * r0 + off]:
			im.surface_set_color(col)
			im.surface_add_vertex(v)


func _disc(im: ImmediateMesh, r: float, inner: Color, outer: Color) -> void:
	var n := 24
	for i in n:
		var a0 := float(i) / float(n) * TAU
		var a1 := float(i + 1) / float(n) * TAU
		im.surface_set_color(inner)
		im.surface_add_vertex(Vector3.ZERO)
		im.surface_set_color(outer)
		im.surface_add_vertex(Vector3(cos(a0), sin(a0), 0.0) * r)
		im.surface_set_color(outer)
		im.surface_add_vertex(Vector3(cos(a1), sin(a1), 0.0) * r)


func _tri(im: ImmediateMesh, a: Vector3, b: Vector3, tip: Vector3, base_col: Color, tip_col: Color) -> void:
	im.surface_set_color(base_col)
	im.surface_add_vertex(a)
	im.surface_set_color(base_col)
	im.surface_add_vertex(b)
	im.surface_set_color(tip_col)
	im.surface_add_vertex(tip)
