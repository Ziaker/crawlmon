extends SkeletonModifier3D
## Keeps a DQT weapon bone glued to the hand while selected animations play.
##
## Some DQT clips (idle 00, walk 01, emotion 50) do not animate the weapon bone
## along with the hand: the original game hides the weapon in those states, so the
## weapon stays where the clip left it. BattleScene reuses those clips for
## idle/run, so the weapon is re-attached here with the hand-relative offset that
## the clips that do carry the weapon (e.g. Ready 32) use.

var animation_player: AnimationPlayer
var hand_bone := ""
var weapon_bone := ""
## Weapon pose in hand space, measured from a clip that carries the weapon.
var offset := Transform3D.IDENTITY
## Alias names (BattleFx names) during which the weapon is re-attached.
var active_anims: Array[String] = []
## Optional two-hand alignment: aims the weapon +Y shaft from hand through second_hand.
var second_hand_bone := ""
var hand_fingers_bone := ""
var second_fingers_bone := ""
var two_hand_anims: Array[String] = []


func _process_modification() -> void:
	if animation_player == null or not (animation_player.current_animation in active_anims):
		return
	var sk := get_skeleton()
	if sk == null:
		return
	var hand := sk.find_bone(hand_bone)
	var weapon := sk.find_bone(weapon_bone)
	if hand < 0 or weapon < 0:
		return
	var wf := sk.get_bone_global_pose(hand) * offset
	if second_hand_bone != "" and animation_player.current_animation in two_hand_anims:
		var h2 := sk.find_bone(second_hand_bone)
		if h2 >= 0:
			var grip_r := _grip_center(sk, hand, hand_fingers_bone)
			var grip_l := _grip_center(sk, h2, second_fingers_bone)
			var cur_dir := wf.basis.y.normalized()
			var target_dir := (grip_l - grip_r).normalized()
			if cur_dir.length_squared() > 0.5 and target_dir.length_squared() > 0.5:
				var q := Quaternion(cur_dir, target_dir)
				wf.origin = grip_r + q * (wf.origin - grip_r)
				wf.basis = Basis(q) * wf.basis
	sk.set_bone_global_pose(weapon, wf)


func _grip_center(sk: Skeleton3D, wrist_idx: int, fingers_name: String) -> Vector3:
	var p := sk.get_bone_global_pose(wrist_idx).origin
	if fingers_name != "":
		var f := sk.find_bone(fingers_name)
		if f >= 0:
			return p.lerp(sk.get_bone_global_pose(f).origin, 0.5)
	return p
