extends SceneTree

const LAB := "res://scenes/debug/attack_hud_lab.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab = (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	for i in 20:
		await process_frame
	var target = lab.get("_target")
	for node in target.find_children("*", "AnimationPlayer", true, false):
		var ap := node as AnimationPlayer
		print("AP ", ap.name, " current=", ap.current_animation, " speed=", ap.speed_scale, " list=", ap.get_animation_list())
		for anim in ap.get_animation_list():
			var a: Animation = ap.get_animation(anim)
			print("   anim ", anim, " len=", a.length, " loop=", a.loop_mode)
	for node in target.find_children("*", "Skeleton3D", true, false):
		var sk := node as Skeleton3D
		print("SKEL ", sk.name, " bones=", sk.get_bone_count())
		for i in mini(sk.get_bone_count(), 8):
			print("   bone ", i, " ", sk.get_bone_name(i), " pose=", sk.get_bone_global_pose(i).origin)
	quit(0)
