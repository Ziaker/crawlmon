class_name DungeonFollower3D
extends DungeonFollower
## D-389/D-1016: DQT Orc 3D como terceiro seguidor visual no overworld.
##
## O rastro, o gap, a velocidade e a reposição continuam os de D-314/D-361/D-388.
## O visual é o GLB renderizado pela vista compartilhada de D-991/D-1016; o
## modelo não entra em batalha, party, colisão ou regra.

const VIEW := preload("res://scripts/dungeon/model_3d_view.gd")

## D-389: the DQT GLBs are ignored by Git, so the normal game only spawns the
## 3D follower when the asset exists on disk. A clone without it keeps the
## two 2D allies and no fallback capsule. Labs can set `enabled = false` to
## build their own 3D followers without a duplicate Orc.
static var enabled := true

static func can_spawn(model_id: String = "dqt_orc") -> bool:
	return enabled and VIEW.has_model(model_id)


func _ready() -> void:
	# O Orc não cria o Sprite2D 2D: quem desenha é a vista 3D.
	if leader != null:
		_trail.append(position)
		var dist := position.distance_to(leader.position)
		var steps := maxi(1, int(dist / TRAIL_STEP))
		for i in range(1, steps):
			_trail.append(position.lerp(leader.position, float(i) / steps))
		_trail.append(leader.position)

	var model_id := species_id if species_id != "" else "dqt_orc"
	if VIEW.has_model(model_id):
		set_meta("model_3d", model_id)
		var view = VIEW.new()
		view.setup(model_id, VIEW.pixel_height_for(model_id))
		add_child(view)


## A vista 3D lê o movimento do pai e cuida de idle/walk e do virar; o caminho
## 2D do DungeonFollower não deve tentar trocar textura de um Sprite2D que não
## existe.
func _update_animation(_movement: Vector2, _delta: float) -> void:
	pass
