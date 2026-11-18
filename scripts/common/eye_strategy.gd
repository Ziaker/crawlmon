class_name EyeStrategy
extends RefCounted
## D-1295: picks the closed-eye strategy of a model from its data only (no species names).
##
## shader_lid        a surface whose material is named `*_eye` (EyeShine + EyeBlink: eyelid by shader)
## decal             mesh `Eye_Model_*` + node/bone `<X>_scale` whose Sleep scale is > 0.5 (DqtEyes: shows the closed decal)
## open_close_bones bones `OpenEye` / `CloseEye` whose position the clips toggle (DqtEyes: holds the Sleep pose)
## bone_lids         bones `*mabuta*` with tracks in the Sleep clip (DqtEyes: holds the Sleep pose)
## none              nothing usable in the data
##
## `paint_candidate` is reported separately: the model has a pupil sticker (`Eye_Model_*`) and a head surface with an
## albedo texture, so the closed eye can be painted in that texture (DqtEyes.paint_closed_eye, profile flag). Whether
## the lids already cover the eye white cannot be told from the data alone, so the flag stays in the profile and
## tests/overworld/diag_eye_strategy.gd reports the candidates.

const SCALE_SUFFIX := "_scale"
const CUTOFF := 0.5


static func detect(glb_root: Node, ap: AnimationPlayer = null, sleep_clip := "") -> Dictionary:
	var info := {
		"strategy": "none",
		"eye_surfaces": 0,
		"eye_meshes": [],
		"scale_pairs": 0,
		"closed_decal": "",
		"open_close": [],
		"lid_bones": [],
		"sleep_clip": ap != null and ap.has_animation(sleep_clip),
		"paint_candidate": false,
	}
	var skeletons := glb_root.find_children("*", "Skeleton3D", true, false)
	var anim: Animation = null
	if ap != null and ap.has_animation(sleep_clip):
		anim = ap.get_animation(sleep_clip)
	for n in glb_root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s)
			if mat != null and str(mat.resource_name).ends_with("_eye"):
				info["eye_surfaces"] += 1
		if String(mi.name).begins_with("Eye_Model"):
			(info["eye_meshes"] as Array).append(String(mi.name))
			var scale_name := String(mi.name) + SCALE_SUFFIX
			var has_pair := glb_root.find_child(scale_name, true, false) != null
			for sk in skeletons:
				if (sk as Skeleton3D).find_bone(scale_name) >= 0:
					has_pair = true
			if has_pair:
				info["scale_pairs"] += 1
				if anim != null and info["closed_decal"] == "" and _scale_at(anim, scale_name, 0.0) > CUTOFF:
					info["closed_decal"] = String(mi.name)
	for nm in ["OpenEye", "CloseEye"]:
		var found := glb_root.find_child(nm, true, false)
		if found == null:
			for sk in skeletons:
				if (sk as Skeleton3D).find_bone(nm) >= 0:
					found = sk
		if found != null:
			(info["open_close"] as Array).append(nm)
	for sk in skeletons:
		var skel := sk as Skeleton3D
		for b in skel.get_bone_count():
			if skel.get_bone_name(b).to_lower().contains("mabuta"):
				(info["lid_bones"] as Array).append(skel.get_bone_name(b))
	info["paint_candidate"] = not (info["eye_meshes"] as Array).is_empty() and _has_head_texture(glb_root)
	if int(info["eye_surfaces"]) > 0:
		info["strategy"] = "shader_lid"
	elif info["closed_decal"] != "":
		info["strategy"] = "decal"
	elif (info["open_close"] as Array).size() == 2 and anim != null:
		info["strategy"] = "open_close_bones"
	elif not (info["lid_bones"] as Array).is_empty() and anim != null:  # `*mabuta*`
		info["strategy"] = "bone_lids"
	return info


static func _has_head_texture(glb_root: Node) -> bool:
	for n in glb_root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.name.begins_with("Eye_Model") or mi.name.begins_with("WModel"):
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s) as BaseMaterial3D
			if mat != null and mat.albedo_texture != null:
				return true
	return false


static func _scale_at(anim: Animation, scale_name: String, t: float) -> float:
	for i in anim.get_track_count():
		if anim.track_get_type(i) != Animation.TYPE_SCALE_3D:
			continue
		var path := anim.track_get_path(i)
		if String(path.get_concatenated_subnames()) == scale_name or String(path).ends_with(scale_name):
			return anim.scale_track_interpolate(i, t).x
	return 1.0
