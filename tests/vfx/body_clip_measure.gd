extends SceneTree
## D-1020 tool 4: measure the REAL battle bodies and clips, without guessing the nearest model (D-235).
##
## For every Combatant in the battle scene:
##   - body mesh AABB (world), posed skeleton height, centre and horizontal radius;
##   - generic hand/head bone candidates and the held weapon (SwingTrail.weapon_of);
##   - per clip: length, loop, hand/head/weapon-tip max and average speed, travel,
##     and the DQT run stride when the profile provides it.
##
## Output: measurements.json + clips.csv + summary.txt. It only reads the battle;
## it changes no damage, range, timing, accuracy or animation.
##
## Windowed run (headless can load models, but the GLB/skeleton path is the one the game uses):
##   Godot --path . --fixed-fps 30 --script res://tests/vfx/body_clip_measure.gd -- --dqt
##   Godot --path . --fixed-fps 30 --script res://tests/vfx/body_clip_measure.gd -- --out=test_captures/vfx_tools/body_clip_measure

const DEFAULT_OUT := "res://test_captures/vfx_tools/body_clip_measure"
const SAMPLES := 24
const HAND_PARTS := ["hand", "_te_", "hte", "wrist"]
const HEAD_PARTS := ["head", "neck", "skull", "kao", "face"]

var _out := DEFAULT_OUT


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/battle.tscn") as PackedScene
	if packed == null:
		push_error("body_clip_measure: battle.tscn not found")
		quit(1)
		return
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)
	var battle: Battle = bs.get_node_or_null("Battle")
	if battle == null:
		push_error("body_clip_measure: Battle node not found")
		quit(1)
		return
	var guard := 0
	while not battle.running and guard < 900:
		await process_frame
		guard += 1
	if not battle.running:
		push_error("body_clip_measure: battle did not start")
		quit(1)
		return
	for i in 12:
		await process_frame
	var units: Array = []
	units.append_array(battle.party)
	units.append_array(battle.enemies)
	# Only observe: no unit acts while the measurements run.
	for c in units:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE

	var rows: Array = []
	var csv_rows: Array = []
	for c in units:
		var model: Node3D = bs.models.get(c)
		if model == null or not is_instance_valid(model):
			continue
		var row := _measure(c, model)
		if row.is_empty():
			continue
		rows.append(row)
		for clip in row["clips"]:
			csv_rows.append([
				row["name"], row["species"], clip["name"], "%.4f" % clip["length"],
				"%.3f" % clip["hand"]["max_speed"], "%.3f" % clip["hand"]["avg_speed"],
				"%.3f" % clip["head"]["max_speed"], "%.3f" % clip["head"]["avg_speed"],
				"%.3f" % clip["weapon_tip"]["max_speed"], "%.3f" % clip["weapon_tip"]["avg_speed"],
				"%.4f" % clip["run_stride"],
			])

	var out_dir := _out if _out.begins_with("res://") else "res://" + _out
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var payload := {
		"tool": "body_clip_measure.gd",
		"date": Time.get_date_string_from_system(),
		"scene": "res://scenes/battle.tscn",
		"renderer": RenderingServer.get_current_rendering_method(),
		"samples_per_clip": SAMPLES,
		"units": rows,
	}
	var json := JSON.stringify(payload, "  ")
	_write(out_dir.path_join("measurements.json"), json + "\n")
	_write(out_dir.path_join("clips.csv"),
		"unit,species,clip,length,hand_max,hand_avg,head_max,head_avg,weapon_max,weapon_avg,run_stride\n" +
		"\n".join(csv_rows.map(func(r): return ",".join(r))) + "\n")

	var summary := PackedStringArray()
	for row in rows:
		var b: Dictionary = row["body"]
		var hand: String = row["hand_bone"] if row["hand_bone"] != "" else "-"
		var head: String = row["head_bone"] if row["head_bone"] != "" else "-"
		if row["head_source"] == "fallback_highest":
			head += "(fallback)"
		var weapon: String = row["weapon"]["bone"] if not row["weapon"].is_empty() else "-"
		summary.append("%-9s species=%-12s mesh_h=%.3f pose_h=%.3f radius=%.3f hand=%-18s head=%-16s weapon=%-16s clips=%d" % [
			row["name"], row["species"], b["mesh_height"], b["pose_height"], b["radius"], hand, head, weapon, row["clips"].size()])
	_write(out_dir.path_join("summary.txt"), "\n".join(summary) + "\n")
	print("\n".join(summary))
	print("[body_clip_measure] wrote ", ProjectSettings.globalize_path(out_dir))
	# Quit immediately: freeing the battle scene here makes its pending timers/lambdas
	# complain after the measurements, without adding any data.
	quit(0)


func _measure(c: Combatant, model: Node3D) -> Dictionary:
	var species := String(c.species_id) if String(c.species_id) != "" else String(c.name).to_lower()
	var profile := DqtModelProfiles.get_profile(species.to_lower())
	var weapon := SwingTrail.weapon_of(model)
	var weapon_mesh: MeshInstance3D = weapon.get("mesh") as MeshInstance3D if not weapon.is_empty() else null
	var mesh_box := _mesh_aabb(model, weapon_mesh)
	var mesh_rows := _mesh_rows(model, weapon_mesh)
	var skels := model.find_children("*", "Skeleton3D", true, false)
	var sk: Skeleton3D = null
	if not skels.is_empty():
		sk = skels[0] as Skeleton3D
	var weapon_bone := int(weapon["bone"]) if not weapon.is_empty() else -1
	var pose_box := _pose_box(sk, weapon_bone)
	var hand_bone := -1
	var head_bone := -1
	var head_source := "none"
	var hand_candidates: Array[String] = []
	var head_candidates: Array[String] = []
	if sk != null:
		for i in sk.get_bone_count():
			var n := sk.get_bone_name(i).to_lower()
			for part in HAND_PARTS:
				if String(part) in n and not (String(n) in hand_candidates):
					hand_candidates.append(sk.get_bone_name(i))
			for part in HEAD_PARTS:
				if String(part) in n and not (String(n) in head_candidates):
					head_candidates.append(sk.get_bone_name(i))
		if not hand_candidates.is_empty():
			hand_bone = sk.find_bone(hand_candidates[0])
		if not head_candidates.is_empty():
			head_bone = sk.find_bone(head_candidates[0])
			head_source = "name"
		else:
			# Generic fallback: highest non-weapon bone. It is reported as a fallback,
			# never silently treated as an authored head bone.
			var best_y := -INF
			for i in sk.get_bone_count():
				if i == weapon_bone:
					continue
				var y := sk.get_bone_global_pose(i).origin.y
				if y > best_y:
					best_y = y
					head_bone = i
			if head_bone >= 0:
				head_source = "fallback_highest"
	var weapon_info := {}
	if not weapon.is_empty():
		weapon_info = {
			"mesh": String((weapon["mesh"] as Node).name),
			"bone": (weapon["skel"] as Skeleton3D).get_bone_name(int(weapon["bone"])),
			"length": float(weapon["half"]) * 2.0,
			"thick": float(weapon["thick"]),
			"thin": bool(weapon["thin"]),
		}
	var ap: AnimationPlayer = CharacterModelLoader.get_anim_player(model)
	var clips: Array = []
	if ap != null:
		for clip_name in ap.get_animation_list():
			var anim := ap.get_animation(clip_name)
			if anim == null:
				continue
			var hand_stats := _motion_stats(sk, anim, hand_bone)
			var head_stats := _motion_stats(sk, anim, head_bone)
			var weapon_stats := _weapon_stats(sk, anim, weapon)
			clips.append({
				"name": String(clip_name),
				"length": anim.length,
				"loop": anim.loop_mode != Animation.LOOP_NONE,
				"hand": hand_stats,
				"head": head_stats,
				"weapon_tip": weapon_stats,
				"run_stride": float(model.get_meta("run_stride_speed", 0.0)),
			})
	var center := mesh_box.get_center() if mesh_box.size != Vector3.ZERO else Vector3.ZERO
	var radius := 0.0
	if mesh_box.size != Vector3.ZERO:
		radius = maxf(mesh_box.size.x, mesh_box.size.z) * 0.5
	return {
		"name": String(c.name),
		"species": species,
		"is_player": bool(c.is_player),
		"model_scale": _v3(model.scale),
		"profile": profile,
		"body": {
			"mesh_aabb": _aabb(mesh_box),
			"mesh_height": mesh_box.size.y,
			"pose_height": pose_box.size.y,
			"center": _v3(center),
			"radius": radius,
			"pose_aabb": _aabb(pose_box),
		},
		"mesh_rows": mesh_rows,
		"bone_count": sk.get_bone_count() if sk != null else 0,
		"hand_candidates": hand_candidates,
		"head_candidates": head_candidates,
		"hand_bone": hand_candidates[0] if not hand_candidates.is_empty() else "",
		"head_bone": head_candidates[0] if not head_candidates.is_empty() else (sk.get_bone_name(head_bone) if head_bone >= 0 else ""),
		"head_source": head_source,
		"weapon": weapon_info,
		"clips": clips,
	}


func _mesh_aabb(model: Node3D, weapon_mesh: MeshInstance3D) -> AABB:
	var box := AABB()
	var first := true
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi == weapon_mesh:
			continue
		var nm := String(mi.name)
		if nm in ["BurstRing", "ReadyRing"] or nm.begins_with("Guard") or nm.begins_with("Shield"):
			continue
		var b: AABB = mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _mesh_rows(model: Node3D, weapon_mesh: MeshInstance3D) -> Array:
	var rows: Array = []
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var nm := String(mi.name)
		var excluded := mi == weapon_mesh or nm in ["BurstRing", "ReadyRing"] or nm.begins_with("Guard") or nm.begins_with("Shield")
		var b: AABB = mi.global_transform * mi.get_aabb()
		rows.append({
			"name": nm,
			"excluded": excluded,
			"why": "weapon" if mi == weapon_mesh else ("helper" if excluded else ""),
			"size": _v3(b.size),
			"min": _v3(b.position),
			"max": _v3(b.position + b.size),
		})
	return rows


func _pose_box(sk: Skeleton3D, weapon_bone: int) -> AABB:
	if sk == null:
		return AABB()
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for i in sk.get_bone_count():
		if i == weapon_bone:
			continue
		var p: Vector3 = sk.global_transform * sk.get_bone_global_pose(i).origin
		mn = Vector3(minf(mn.x, p.x), minf(mn.y, p.y), minf(mn.z, p.z))
		mx = Vector3(maxf(mx.x, p.x), maxf(mx.y, p.y), maxf(mx.z, p.z))
	if mn.x == INF:
		return AABB()
	return AABB(mn, mx - mn)


func _motion_stats(sk: Skeleton3D, anim: Animation, bone: int) -> Dictionary:
	if sk == null or bone < 0 or anim.length <= 0.0001:
		return {"max_speed": 0.0, "avg_speed": 0.0, "travel": 0.0}
	var dt := anim.length / float(SAMPLES)
	var prev := _bone_pos(sk, anim, bone, 0.0)
	var travel := 0.0
	var max_speed := 0.0
	for i in range(1, SAMPLES + 1):
		var p := _bone_pos(sk, anim, bone, anim.length * float(i) / float(SAMPLES))
		var d := prev.distance_to(p)
		travel += d
		max_speed = maxf(max_speed, d / dt)
		prev = p
	return {"max_speed": max_speed, "avg_speed": travel / anim.length, "travel": travel}


func _weapon_stats(sk: Skeleton3D, anim: Animation, weapon: Dictionary) -> Dictionary:
	if sk == null or weapon.is_empty() or anim.length <= 0.0001:
		return {"max_speed": 0.0, "avg_speed": 0.0, "travel": 0.0}
	var center: Vector3 = weapon["center"]
	var axis: Vector3 = weapon["axis"]
	var half: float = float(weapon["half"])
	var bind: Transform3D = weapon["bind"]
	var bone := int(weapon["bone"])
	var dt := anim.length / float(SAMPLES)
	var prev := _weapon_tip(sk, anim, bone, bind, center, axis, half, 0.0)
	var travel := 0.0
	var max_speed := 0.0
	for i in range(1, SAMPLES + 1):
		var p := _weapon_tip(sk, anim, bone, bind, center, axis, half, anim.length * float(i) / float(SAMPLES))
		var d := prev.distance_to(p)
		travel += d
		max_speed = maxf(max_speed, d / dt)
		prev = p
	return {"max_speed": max_speed, "avg_speed": travel / anim.length, "travel": travel}


func _bone_pos(sk: Skeleton3D, anim: Animation, bone: int, t: float) -> Vector3:
	return sk.global_transform * DqtModelProfiles._bone_global_at(sk, anim, bone, t).origin


func _weapon_tip(sk: Skeleton3D, anim: Animation, bone: int, bind: Transform3D, center: Vector3, axis: Vector3, half: float, t: float) -> Vector3:
	var xf := sk.global_transform * DqtModelProfiles._bone_global_at(sk, anim, bone, t) * bind
	return xf * (center + axis * half)


func _aabb(box: AABB) -> Dictionary:
	return {"min": _v3(box.position), "max": _v3(box.position + box.size), "size": _v3(box.size)}


func _v3(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("body_clip_measure: cannot write " + path)
		return
	f.store_string(text)
	f.close()
