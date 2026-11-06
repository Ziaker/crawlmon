extends Node
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


func _ready() -> void:
	# Run after AnimationPlayer (priority 0) so the attachment wins this frame.
	process_priority = 100


func _process(_delta: float) -> void:
	if animation_player == null or not (animation_player.current_animation in active_anims):
		return
	var sk := get_parent() as Skeleton3D
	if sk == null:
		return
	var hand := sk.find_bone(hand_bone)
	var weapon := sk.find_bone(weapon_bone)
	if hand < 0 or weapon < 0:
		return
	sk.set_bone_global_pose(weapon, sk.get_bone_global_pose(hand) * offset)
