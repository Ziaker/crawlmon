class_name DqtModelProfiles
extends RefCounted
## Crossover pilot: Dragon Quest Tact models.
##
## DQT GLBs are Y-up and exported in metres, unlike the Z-up Pokemon GLBs.
## `native_height` is the rest-pose bounding box height of the GLB (measured from
## the POSITION accessors). `target_height` is the height the model should read at
## in the battle, after which BattleScene applies its normal enemy multiplier.
##
## DQT clip suffixes come from the game's AnimatorOverrideController:
##   00 Idle | 01 Walk | 02 Joy | 03 Bad | 04 Sleep | 05 Paralysis
##   10 Damage | 11 SkillA/C/D/E/F | 12 SkillB | 30 Die | 32 Ready/Defeat | 50 Emotion
## BattleFx expects: idle, battle_idle, walk, run, attack, attack_special,
## charge, damage, down, victory.

const WeaponFollow := preload("res://scripts/combat/dqt_weapon_follow.gd")

const PROFILES := {
	"dqt_dracky": {
		"native_height": 1.236,
		"target_height": 1.1,
		"clip_prefix": "cm_00_0003_",
		"rotation_y": 180.0,
		"idle_source": "00",
	},
	"dqt_healslime": {
		"native_height": 1.234,
		"target_height": 1.25,
		"clip_prefix": "cm_00_0004_",
		"rotation_y": 180.0,
		"idle_source": "00",
	},
	"dqt_sabrecub": {
		"native_height": 1.036,
		"target_height": 1.0,
		"clip_prefix": "cm_00_0002_",
		"rotation_y": 180.0,
		"idle_source": "00",
	},
	"dqt_platypunk": {
		"native_height": 1.354,
		"target_height": 1.15,
		"clip_prefix": "cm_00_0001_",
		"rotation_y": 180.0,
		"idle_source": "00",
	},
	"dqt_fungi": {
		"native_height": 1.315,
		"target_height": 1.15,
		"clip_prefix": "cm_00_0038_",
		"rotation_y": 180.0,
		"idle_source": "00",
	},
	"dqt_slime": {
		"native_height": 0.83,
		"target_height": 1.4,
		"clip_prefix": "cm_00_0000_",
		"rotation_y": 180.0,
		# Ready (32) is the battle stance; play it once and hold the final pose.
		"idle_source": "32",
		"idle_pose_time": 0.95,
		"idle_full": true,
	},
	"dqt_orc": {
		"native_height": 1.772,
		"target_height": 2.1,
		"clip_prefix": "cm_00_0020_",
		"rotation_y": 180.0,
		# Ready (32) is the battle stance. Idle (00) is an appear/idle/end clip.
		"idle_source": "32",
		"idle_pose_time": 1.90,
		"idle_full": true,
		# D-341: the creator wants the Orc's run at its normal 1x speed (no stride matching).
		"ally_scale": 1.2,  # D-342: 1.2x bigger on the player's side only
		# qa_export flags the spear detached on Die/Joy/SkillB; keep it in the hand.
		"weapon_follow": {
			"hand": "j_te_r",
			"bone": "n_buki_r_n_hara",
			"ref_clip": "32",
			"anims": ["down", "victory", "attack_special"],
		},
	},
	"dqt_cyclops": {
		"native_height": 3.091,
		"target_height": 3.22,
		"clip_prefix": "cm_00_0065_",
		"rotation_y": 180.0,
		# Ready (32) ends upright with the club in the hand. Idle (00) and walk
		# (01) leave the club bone behind; the weapon follow re-attaches it.
		"idle_source": "32",
		"idle_pose_time": 1.95,
		"idle_full": true,
		# D-341: on the run to the target the walk clip plays at the speed that
		# makes the feet follow the real ground speed (no sliding).
		"match_run_stride": true,
		"ally_scale": 1.2,  # D-342: 1.2x bigger on the player's side only
		# Run reuses walk (01); re-attach the club to the hand during it.
		"weapon_follow": {
			"hand": "j_te_l",
			"bone": "n_buki_l_n_hara",
			"ref_clip": "32",
			"anims": ["walk", "run"],
		},
	},
}

## BattleFx animation -> DQT clip suffix. The battle has no dedicated run, charge
## or battle-idle clip, so the closest DQT state is reused.
const ANIM_SUFFIXES := {
	"idle": "00",
	"battle_idle": "00",
	"walk": "01",
	"run": "01",
	"attack": "11",
	"attack_special": "12",
	"charge": "00",
	"damage": "10",
	"down": "30",
	"victory": "02",
}


static func get_profile(model_id: String) -> Dictionary:
	return PROFILES.get(model_id, {})


## Adds the names BattleFx plays as copies of the original DQT clips. Copies keep
## the imported clips untouched and let each spawned instance own its animations.
static func apply_anim_aliases(ap: AnimationPlayer, profile: Dictionary) -> void:
	var prefix: String = str(profile.get("clip_prefix", ""))
	var library_name := &""
	var library: AnimationLibrary
	if ap.has_animation_library(library_name):
		library = ap.get_animation_library(library_name)
	else:
		library = AnimationLibrary.new()
		ap.add_animation_library(library_name, library)
	for alias in ANIM_SUFFIXES:
		var suffix := str(ANIM_SUFFIXES[alias])
		if alias in ["idle", "battle_idle", "charge"]:
			suffix = str(profile.get("idle_source", suffix))
		var source := prefix + suffix
		if not ap.has_animation(source):
			continue
		if library.has_animation(alias):
			library.remove_animation(alias)
		var base := ap.get_animation(source)
		var anim: Animation
		if profile.get("idle_full", false) and alias in ["idle", "battle_idle"]:
			anim = base.duplicate(true) as Animation
			anim.loop_mode = Animation.LOOP_NONE
		elif profile.has("idle_pose_time") and alias in ["idle", "battle_idle", "charge"]:
			anim = _hold_pose(base, float(profile["idle_pose_time"]))
		else:
			anim = base.duplicate(true) as Animation
		library.add_animation(alias, anim)
	ap.clear_caches()


## D-341: how fast the feet of the "run" clip move over the ground, in skeleton
## units per clip second at speed 1. Per foot (lowest "j_asi*" bone of each side)
## the forward sweep is one step; a cycle has one step per foot. Stored on
## `model_root` as meta "run_stride_speed" + "run_skeleton" when the profile asks.
static func setup_run_stride(model_root: Node, glb_root: Node, ap: AnimationPlayer, profile: Dictionary) -> void:
	if not profile.get("match_run_stride", false) or ap == null or not ap.has_animation("run"):
		return
	var skeletons := glb_root.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	var sk := skeletons[0] as Skeleton3D
	var anim := ap.get_animation("run")
	var feet := {}  # side -> bone (lowest j_asi* in rest)
	for b in sk.get_bone_count():
		var bn := sk.get_bone_name(b)
		if not bn.begins_with("j_asi"):
			continue
		var side := "l" if bn.ends_with("_l") else ("r" if bn.ends_with("_r") else "")
		if side == "":
			continue
		var y := sk.get_bone_global_rest(b).origin.y
		if not feet.has(side) or y < float(feet[side][1]):
			feet[side] = [b, y]
	if feet.size() < 2:
		return
	var samples := 24
	var mins := {}
	var maxs := {}
	for k in samples + 1:
		var t := anim.length * float(k) / float(samples)
		for side in feet:
			var z := _bone_global_at(sk, anim, int(feet[side][0]), t).origin.z
			mins[side] = minf(float(mins.get(side, z)), z)
			maxs[side] = maxf(float(maxs.get(side, z)), z)
	var stride := 0.0
	for side in feet:
		stride += float(maxs[side]) - float(mins[side])
	if stride > 1e-4 and anim.length > 0.01:
		model_root.set_meta("run_stride_speed", stride / anim.length)
		model_root.set_meta("run_skeleton", sk)


## Skeleton-space transform of `bone` at time t of `anim`, chained by hand from
## the tracks (the skeleton does not update its poses outside the scene tree).
static func _bone_global_at(sk: Skeleton3D, anim: Animation, bone: int, t: float) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var b := bone
	while b >= 0:
		var rest := sk.get_bone_rest(b)
		var pos := rest.origin
		var rot := rest.basis.get_rotation_quaternion()
		var scl := rest.basis.get_scale()
		var bn := sk.get_bone_name(b)
		for i in anim.get_track_count():
			if _bone_name(anim.track_get_path(i)) != bn:
				continue
			match anim.track_get_type(i):
				Animation.TYPE_POSITION_3D:
					pos = anim.position_track_interpolate(i, t)
				Animation.TYPE_ROTATION_3D:
					rot = anim.rotation_track_interpolate(i, t)
				Animation.TYPE_SCALE_3D:
					scl = anim.scale_track_interpolate(i, t)
		xf = Transform3D(Basis(rot).scaled(scl), pos) * xf
		b = sk.get_bone_parent(b)
	return xf


static func _pose_from(sk: Skeleton3D, anim: Animation, t: float) -> void:
	for i in anim.get_track_count():
		var bone := sk.find_bone(_bone_name(anim.track_get_path(i)))
		if bone < 0:
			continue
		match anim.track_get_type(i):
			Animation.TYPE_POSITION_3D:
				sk.set_bone_pose_position(bone, anim.position_track_interpolate(i, t))
			Animation.TYPE_ROTATION_3D:
				sk.set_bone_pose_rotation(bone, anim.rotation_track_interpolate(i, t))
			Animation.TYPE_SCALE_3D:
				sk.set_bone_pose_scale(bone, anim.scale_track_interpolate(i, t))
	sk.force_update_all_bone_transforms()


## Adds a DqtWeaponFollow modifier when the profile asks for one. The hand-space
## offset is measured from the reference clip's first frame by posing the skeleton
## by hand, so it works before the model enters the scene tree.
static func setup_weapon_follow(model: Node, ap: AnimationPlayer, profile: Dictionary) -> void:
	var cfg: Dictionary = profile.get("weapon_follow", {})
	if cfg.is_empty() or ap == null:
		return
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	var sk := skeletons[0] as Skeleton3D
	var hand := sk.find_bone(str(cfg["hand"]))
	var weapon := sk.find_bone(str(cfg["bone"]))
	var ref := ap.get_animation(str(profile.get("clip_prefix", "")) + str(cfg["ref_clip"]))
	if hand < 0 or weapon < 0 or ref == null:
		return
	for i in ref.get_track_count():
		var bone := sk.find_bone(_bone_name(ref.track_get_path(i)))
		if bone < 0:
			continue
		match ref.track_get_type(i):
			Animation.TYPE_POSITION_3D:
				sk.set_bone_pose_position(bone, ref.position_track_interpolate(i, 0.0))
			Animation.TYPE_ROTATION_3D:
				sk.set_bone_pose_rotation(bone, ref.rotation_track_interpolate(i, 0.0))
			Animation.TYPE_SCALE_3D:
				sk.set_bone_pose_scale(bone, ref.scale_track_interpolate(i, 0.0))
	sk.force_update_all_bone_transforms()
	var follow := WeaponFollow.new()
	follow.name = "DqtWeaponFollow"
	follow.animation_player = ap
	follow.hand_bone = str(cfg["hand"])
	follow.weapon_bone = str(cfg["bone"])
	follow.offset = sk.get_bone_global_pose(hand).affine_inverse() * sk.get_bone_global_pose(weapon)
	for a in cfg.get("anims", []):
		follow.active_anims.append(str(a))
	sk.reset_bone_poses()
	sk.add_child(follow)


static func _bone_name(path: NodePath) -> String:
	var text := String(path)
	var colon := text.rfind(":")
	return text.substr(colon + 1) if colon >= 0 else text


## Freezes one frame of a clip into a loop. The DQT idle clips are combined
## appear/idle/end: their rest frames are lying or flattened, so the stable
## standing pose is held; a root-level breathing tween adds the idle motion.
static func _hold_pose(source: Animation, at_time: float, length := 2.0) -> Animation:
	var out := Animation.new()
	out.length = length
	out.loop_mode = Animation.LOOP_LINEAR
	for i in source.get_track_count():
		var type := source.track_get_type(i)
		if type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			continue
		var track := out.add_track(type)
		out.track_set_path(track, source.track_get_path(i))
		var value
		match type:
			Animation.TYPE_POSITION_3D:
				value = source.position_track_interpolate(i, at_time)
			Animation.TYPE_ROTATION_3D:
				value = source.rotation_track_interpolate(i, at_time)
			Animation.TYPE_SCALE_3D:
				value = source.scale_track_interpolate(i, at_time)
		out.track_insert_key(track, 0.0, value)
		out.track_insert_key(track, length, value)
	return out


## Gentle breathing on the held pose: scale + vertical bob on a wrapper.
## Called after the model enters the battle tree.
static func start_idle_breath(model: Node3D) -> void:
	var breath := model.get_node_or_null("DqtIdleBreath") as Node3D
	if breath == null or breath.has_meta("breathing"):
		return
	breath.set_meta("breathing", true)
	var height := float(breath.get_meta("height", 2.0))
	var base_scale := breath.scale
	var half := 1.0
	var tween := breath.create_tween().set_loops()
	tween.tween_property(breath, "scale", base_scale * Vector3(1.03, 0.98, 1.03), half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(breath, "position:y", height * 0.035, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(breath, "rotation_degrees:z", 1.5, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(breath, "rotation_degrees:x", 1.0, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(breath, "scale", base_scale, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(breath, "position:y", 0.0, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(breath, "rotation_degrees:z", 0.0, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(breath, "rotation_degrees:x", 0.0, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
