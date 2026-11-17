extends SceneTree
## D-1269 / D-1204: nenhum modelo entra em outro. Cenário de debug (< 10 s por laboratório) que FORÇA
## sobreposição e imprime a profundidade de interpenetração medida entre os cascos reais (casco convexo
## dos vértices skinados no plano do chão, pose atual) de cada par. Janela real (NUNCA headless):
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 960x540 --fixed-fps 60 \
##       --script res://tests/overworld/body_overlap_scenario.gd -- --lab=forest|hub --out=<pasta> [--off]
##
## `--off` desliga o separador (mede a linha de base: quanto os modelos se atravessam hoje).
const Footprint := preload("res://scripts/overworld/body_footprint.gd")
const LABS := {
	"forest": "res://scenes/debug/murky_forest_3d_lab.tscn",
	"hub": "res://scenes/debug/hub_3d_prototype.tscn",
}
const SPECIES := {
	"abra": 1.0, "pancham": 0.7, "gible": 0.85, "dqt_slime": 0.9, "dqt_orc": 2.1, "dqt_cyclops": 2.2,
	"bulbasaur": 0.78, "pikachu": 0.72, "squirtle": 0.72, "charmander": 0.78, "eevee": 0.62,
	"dqt_healslime": 1.15, "dqt_dracky": 0.95, "dqt_sabrecub": 0.85,
}

var lab: Node
var sep: Node
var out := ""
var _cam: Camera3D
var _worst_all := 0.0
var _rows: Array = []


func _init() -> void:
	call_deferred("_run")


func _arg(n: String, d: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a == "--%s" % n:
			return "true"
		if a.begins_with("--%s=" % n):
			return a.substr(n.length() + 3)
	return d


func _run() -> void:
	var which := _arg("lab", "forest")
	out = _arg("out", "")
	var packed := load(LABS[which]) as PackedScene
	lab = packed.instantiate()
	lab.set("start_party", true)
	root.add_child(lab)
	await create_timer(1.2).timeout
	sep = lab.get_node_or_null("BodySeparation")
	if _arg("off", "") == "true" and sep != null:
		sep.set("enabled", false)
	print("BODY_LAB: ", which, " separator=", sep != null and bool(sep.get("enabled")))
	_make_cam()
	var player: CharacterBody3D = lab.get("player")
	_hold_player_free(player)

	await _phase_footprints()
	await _phase_leader_into_npc(player)
	await _phase_npc_onto_leader(player)
	await _phase_follower_leader(player)
	await _phase_npc_npc()
	await _phase_heap(player)
	await _phase_enemy(player)
	await _phase_attack(player)
	print("BODY_RESULT: ", JSON.stringify({"lab": which, "separator": sep != null and bool(sep.get("enabled")),
		"worst_penetration_m": snappedf(_worst_all, 0.001), "rows": _rows}))
	quit(0)


func _make_cam() -> void:
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.near = 0.05
	root.add_child(_cam)


func _hold_player_free(player: CharacterBody3D) -> void:
	# Fecha qualquer diálogo/UI do lab para o teste poder mover o jogador.
	player.velocity = Vector3.ZERO


func _key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)


# --- medição independente: casco convexo dos vértices (100% dos vértices, 10%-90% da altura) --------

func _hull(node: Node3D) -> PackedVector2Array:
	var info: Dictionary = Footprint.info(node)
	var pts: PackedVector3Array = Footprint.body_points(node)
	var base := float(info["base"])
	var h := float(info["height"])
	var flat: Array[Vector2] = []
	var xf := node.global_transform
	for p in pts:
		if p.y >= base + 0.10 * h and p.y <= base + 0.90 * h:
			var w := xf * p
			flat.append(Vector2(w.x, w.z))
	return _convex_hull(flat)


func _convex_hull(points: Array[Vector2]) -> PackedVector2Array:
	var pts := points.duplicate()
	pts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	if pts.size() < 3:
		return PackedVector2Array(pts)
	var lower: Array[Vector2] = []
	for p in pts:
		while lower.size() >= 2 and (lower[-1] - lower[-2]).cross(p - lower[-2]) <= 0.0:
			lower.pop_back()
		lower.append(p)
	var upper: Array[Vector2] = []
	for i in range(pts.size() - 1, -1, -1):
		var p: Vector2 = pts[i]
		while upper.size() >= 2 and (upper[-1] - upper[-2]).cross(p - upper[-2]) <= 0.0:
			upper.pop_back()
		upper.append(p)
	lower.pop_back()
	upper.pop_back()
	lower.append_array(upper)
	return PackedVector2Array(lower)


## Profundidade de interpenetração (SAT) de dois polígonos convexos; 0 se separados.
func _sat_depth(a: PackedVector2Array, b: PackedVector2Array) -> float:
	if a.size() < 3 or b.size() < 3:
		return 0.0
	var best := INF
	for poly in [a, b]:
		for i in poly.size():
			var e: Vector2 = poly[(i + 1) % poly.size()] - poly[i]
			var axis := Vector2(-e.y, e.x).normalized()
			var amin := INF
			var amax := -INF
			for p in a:
				var d := axis.dot(p)
				amin = minf(amin, d)
				amax = maxf(amax, d)
			var bmin := INF
			var bmax := -INF
			for p in b:
				var d := axis.dot(p)
				bmin = minf(bmin, d)
				bmax = maxf(bmax, d)
			var ov := minf(amax, bmax) - maxf(amin, bmin)
			if ov <= 0.0:
				return 0.0
			best = minf(best, ov)
	return best


func _actors() -> Array:
	return sep.call("gather") if sep != null else []


## Pior interpenetração entre todos os pares agora (casco real) e o par.
func _measure() -> Dictionary:
	var actors: Array = _actors()
	var hulls: Array = []
	Footprint.max_samples = 1000  # só a medição por quadro do teste; o separador mede com 4500
	for a in actors:
		hulls.append(_hull(a["node"]))
	Footprint.max_samples = 4500
	var worst := 0.0
	var pair := ""
	for i in actors.size():
		for j in range(i + 1, actors.size()):
			var pa: Vector3 = (actors[i]["node"] as Node3D).global_position
			var pb: Vector3 = (actors[j]["node"] as Node3D).global_position
			if absf(pa.y - pb.y) > minf(float(actors[i]["h"]), float(actors[j]["h"])):
				continue
			var d := _sat_depth(hulls[i], hulls[j])
			if d > worst:
				worst = d
				pair = "%s|%s" % [(actors[i]["node"] as Node).name, (actors[j]["node"] as Node).name]
	if _arg("verbose", "") == "true" and actors.size() > 1:
		var dmin := INF
		var dpair := ""
		for i in actors.size():
			for j in range(i + 1, actors.size()):
				var q: Vector3 = (actors[i]["node"] as Node3D).global_position - (actors[j]["node"] as Node3D).global_position
				q.y = 0.0
				if q.length() < dmin:
					dmin = q.length()
					dpair = "%s|%s r=%.2f+%.2f" % [(actors[i]["node"] as Node).name, (actors[j]["node"] as Node).name, float(actors[i]["r"]), float(actors[j]["r"])]
		print("   near ", snappedf(dmin, 0.01), " ", dpair, " hull_sizes=", hulls.map(func(h): return h.size()))
	var rep: Dictionary = sep.call("last_report") if sep != null else {}
	return {"hull_pen": worst, "pair": pair, "circle_pen": float(rep.get("max_penetration", 0.0)), "n": actors.size()}


func _settle_and_report(tag: String, frames: int, shot_focus: Vector3 = Vector3.INF) -> void:
	var worst_run := 0.0
	var worst_pair := ""
	for i in frames:
		await physics_frame
		await process_frame
		if i % 3 != 0:
			continue
		var m := _measure()
		if float(m["hull_pen"]) > worst_run:
			worst_run = float(m["hull_pen"])
			worst_pair = str(m["pair"])
	var final := _measure()
	_worst_all = maxf(_worst_all, float(final["hull_pen"]))
	var row := {"phase": tag, "final_hull_pen": snappedf(float(final["hull_pen"]), 0.001), "final_pair": final["pair"],
		"worst_during": snappedf(worst_run, 0.001), "actors": final["n"], "circle_pen": snappedf(float(final["circle_pen"]), 0.001)}
	_rows.append(row)
	print("BODY_PEN ", JSON.stringify(row))
	if out != "" and shot_focus != Vector3.INF:
		await _shot(tag, shot_focus)


func _shot(tag: String, focus: Vector3) -> void:
	_cam.current = true
	_cam.global_position = focus + Vector3(0.0, 4.6, 2.6)
	_cam.look_at(focus + Vector3(0.0, 0.6, 0.0), Vector3.UP)
	# esconde copas/folhagem que cobririam a câmera de teste (só no enquadramento)
	for n in lab.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi != null and mi.global_position.y > 3.0 and mi.get_parent() == lab:
			mi.visible = false
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(out)
	root.get_texture().get_image().save_png("%s/%s.png" % [out, tag])


func _settle(frames: int) -> void:
	for i in frames:
		await physics_frame
		await process_frame


# --- fases -----------------------------------------------------------------------------------------

func _phase_footprints() -> void:
	var rows := {}
	for a in _actors():
		var n := a["node"] as Node3D
		var hull := _hull(n)
		var hr := 0.0
		for p in hull:
			hr = maxf(hr, (p - Vector2(n.global_position.x, n.global_position.z)).length())
		var fresh: Dictionary = Footprint._measure(n)
		var lp: PackedVector3Array = Footprint.body_points(n)
		var cx := 0.0
		var cz := 0.0
		var mnx := INF
		var mxx := -INF
		var mnz := INF
		var mxz := -INF
		for p in lp:
			cx += p.x
			cz += p.z
			mnx = minf(mnx, p.x)
			mxx = maxf(mxx, p.x)
			mnz = minf(mnz, p.z)
			mxz = maxf(mxz, p.z)
		cx /= maxf(lp.size(), 1)
		cz /= maxf(lp.size(), 1)
		var fi: Dictionary = Footprint.info(n)
		rows[str(n.name)] = {"cap_w": snappedf(float(fi["w"]), 0.01), "cap_half": snappedf(float(fi["half"]), 0.01), "cen": [snappedf(cx, 0.01), snappedf(cz, 0.01)], "x": [snappedf(mnx, 0.01), snappedf(mxx, 0.01)], "z": [snappedf(mnz, 0.01), snappedf(mxz, 0.01)], "hull_n": hull.size(), "fresh_r": snappedf(float(fresh["radius"]), 0.01), "pos": n.global_position, "scale": n.scale, "r": snappedf(float(a["r"]), 0.01), "h": snappedf(float(a["h"]), 0.01), "hull_max_r": snappedf(hr, 0.01)}
	print("BODY_FOOTPRINTS ", JSON.stringify(rows))
	if _arg("poses", "") == "true":
		for a in _actors():
			var n2 := a["node"] as Node3D
			var ps: Array = Footprint._sampled_poses(n2)
			var line := []
			for band in ps:
				var mnx := INF
				var mxx := -INF
				for q in band:
					mnx = minf(mnx, q.x)
					mxx = maxf(mxx, q.x)
				line.append(snappedf(mxx - mnx, 0.01))
			print("POSES ", n2.name, " widths=", line)


func _first_npc(moving := false) -> Node3D:
	for n in lab.get("_npcs"):
		var b := n["node"] as Node3D
		if b != null and b.visible and ((n.get("waypoints", []) as Array).size() > 1) == moving:
			return b
	return null


func _cam_forward() -> Vector3:
	if lab.has_method("_camera_ground_forward"):
		return lab.call("_camera_ground_forward")
	return Vector3(0, 0, -1)


func _park_others(except: Array) -> void:
	# Afasta todos os outros atores (cada fase mede só o par/grupo que ela forma).
	var far := Vector3(60.0, 0.0, 60.0)
	var i := 0
	for a in _actors():
		var n := a["node"] as Node3D
		if except.has(n):
			continue
		n.global_position = Vector3(far.x + float(i) * 6.0, n.global_position.y, far.z)
		i += 1


func _phase_leader_into_npc(player: CharacterBody3D) -> void:
	await _walk_into(player, false)
	await _walk_into(player, true)


func _walk_into(player: CharacterBody3D, moving: bool) -> void:
	var npc := _first_npc(moving)
	if npc == null:
		print("BODY_NOTE: sem NPC ", "patrulheiro" if moving else "parado")
		return
	_park_others([player, npc])
	var fwd := _cam_forward()
	player.global_position = npc.global_position - fwd * 3.0
	player.velocity = Vector3.ZERO
	await _settle(10)
	var npc0 := npc.global_position
	var pl0 := player.global_position
	_key(KEY_UP, true)
	await _settle_and_report("leader_walks_into_%s_npc" % ("patrol" if moving else "static"), 90, npc.global_position)
	_key(KEY_UP, false)
	print("BODY_PUSH moving=", moving, " npc_moved=", snappedf(npc.global_position.distance_to(npc0), 0.01), " player_moved=", snappedf(player.global_position.distance_to(pl0), 0.01))


func _phase_npc_onto_leader(player: CharacterBody3D) -> void:
	var npc := _first_npc()
	if npc == null:
		return
	npc.global_position = player.global_position + Vector3(0.05, 0.0, 0.02)
	await _settle_and_report("npc_dropped_on_leader", 40, player.global_position)


func _phase_follower_leader(player: CharacterBody3D) -> void:
	var fols: Array = lab.get("_followers")
	if fols.is_empty():
		print("BODY_NOTE: sem seguidores neste cenário")
		return
	var f := fols[0]["node"] as Node3D
	var f2 := fols[fols.size() - 1]["node"] as Node3D
	f.global_position = player.global_position + Vector3(0.04, 0.0, 0.03)
	if f2 != f:
		f2.global_position = player.global_position + Vector3(-0.03, 0.0, 0.05)
	await _settle_and_report("followers_dropped_on_leader", 40, player.global_position)
	# o líder anda para trás sobre os seguidores
	_key(KEY_DOWN, true)
	await _settle_and_report("leader_walks_back_over_followers", 80, player.global_position)
	_key(KEY_DOWN, false)


func _phase_npc_npc() -> void:
	var npcs: Array = lab.get("_npcs")
	var vis: Array = []
	for n in npcs:
		var b := n["node"] as Node3D
		if b != null and b.visible:
			vis.append(b)
	if vis.size() < 2:
		print("BODY_NOTE: menos de 2 NPCs visíveis")
		return
	var a := vis[0] as Node3D
	var b := vis[1] as Node3D
	var player: CharacterBody3D = lab.get("player")
	_park_others([a, b])
	a.global_position = player.global_position + Vector3(6.0, 0.0, 6.0)
	b.global_position = a.global_position + Vector3(0.06, 0.0, 0.0)
	await _settle_and_report("npc_on_npc", 40, a.global_position)


func _spawn_extra(id: String, h: float, pos: Vector3) -> Node3D:
	var body := Node3D.new()
	body.name = "X_%s" % id
	body.add_to_group("body_actor")
	lab.add_child(body)
	body.global_position = pos
	var model: Node3D = lab.call("_make_model", id, h)
	if model == null:
		body.queue_free()
		return null
	body.add_child(model)
	var ap: AnimationPlayer = lab.call("_anim_player", model)
	lab.call("_play_idle", ap)
	return body


func _phase_heap(player: CharacterBody3D) -> void:
	_park_others([player])
	var spot: Vector3 = player.global_position + Vector3(8.0, 0.0, 8.0)
	var i := 0
	for id in SPECIES:
		_spawn_extra(id, SPECIES[id], spot + Vector3(0.02 * float(i), 0.0, 0.015 * float(i % 3)))
		i += 1
	await _settle(4)
	await _settle_and_report("all_species_heap", 150, spot)


func _phase_enemy(player: CharacterBody3D) -> void:
	var enemy: Node3D = null
	for e in lab.get("_room_enemies") if lab.get("_room_enemies") != null else []:
		enemy = e["node"]
		break
	if enemy == null:
		enemy = lab.get("_enemy_body")
	if enemy == null:
		print("BODY_NOTE: sem inimigo neste cenário")
		return
	enemy.global_position = player.global_position + Vector3(0.05, 0.0, 0.04)
	await _settle_and_report("enemy_dropped_on_leader", 40, player.global_position)


## O avanço do ataque (Z) contra o inimigo real: o separador não pode atrasar o encontro nem permitir
## que o atacante entre no alvo. Mede o casco a cada quadro do avanço e o `edge_gap` do controlador.
func _phase_attack(player: CharacterBody3D) -> void:
	var ctrl: Node = lab.get("_attack_controller")
	var rooms = lab.get("_room_enemies")
	if ctrl == null or rooms == null or (rooms as Array).is_empty():
		print("BODY_NOTE: sem controlador de ataque/inimigo de sala")
		return
	var target: Node3D = null
	for e in rooms:
		if str(e["node"].name).ends_with("cyclops"):
			target = e["node"]
	if target == null:
		target = rooms[0]["node"]
	_park_others([player, target])
	player.global_position = target.global_position + Vector3(0.0, 0.0, 4.3)
	player.velocity = Vector3.ZERO
	var to := target.global_position - player.global_position
	to.y = 0.0
	var yaw := atan2(to.x, to.z)
	lab.set("player_yaw", yaw)
	lab.set("_cam_yaw", yaw)
	player.rotation.y = yaw
	await _settle(15)
	var impact := [false]
	ctrl.impact_requested.connect(func(_p, _d, _a, _c) -> void: impact[0] = true)
	_key(KEY_Z, true)
	await process_frame
	_key(KEY_Z, false)
	var worst := 0.0
	var min_gap := INF
	for i in 60:
		await physics_frame
		await process_frame
		var m := _measure()
		worst = maxf(worst, float(m["hull_pen"]))
		min_gap = minf(min_gap, float(ctrl.call("_edge_gap", player, target)))
		if lab.get_node_or_null("TackleImpact") != null or bool(ctrl.get("_battle_requested")):
			impact[0] = true
	var row := {"phase": "attack_advance", "hit_registered": impact[0], "worst_hull_pen": snappedf(worst, 0.001),
		"min_edge_gap": snappedf(min_gap, 0.001)}
	_rows.append(row)
	_worst_all = maxf(_worst_all, worst)
	print("BODY_PEN ", JSON.stringify(row))
	if out != "":
		await _shot("attack_advance", target.global_position)
