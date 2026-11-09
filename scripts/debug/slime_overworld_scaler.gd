extends Node
## D-1071: deixa o Slime do overworld 0,35x menor.
##
## Fica como nó filho da cena 3D e aplica a escala depois que o lab terminou
## de construir o Slime. Não mexe no script do lab (que outra sessão também
## edita) nem na batalha 3D; o lab de pedra de D-1023 continua em 1,4 m.

const SLIME_SCALE := 0.35
const BASE_HEIGHT := 1.4


func _ready() -> void:
	await get_tree().physics_frame
	var lab := get_parent()
	if lab == null:
		return
	var body: Node3D = lab.get("_enemy_body")
	if body == null:
		return
	_scale_slime(body)


func _scale_slime(body: Node3D) -> void:
	var h := BASE_HEIGHT * SLIME_SCALE
	for child in body.get_children():
		if child is CollisionShape3D:
			var shape := child as CollisionShape3D
			var cap := CapsuleShape3D.new()
			cap.radius = 0.4 * SLIME_SCALE
			cap.height = h
			shape.shape = cap
			shape.position.y = h * 0.5
		elif child is NavigationAgent3D:
			var agent := child as NavigationAgent3D
			agent.radius = 0.4 * SLIME_SCALE
			agent.height = h
		elif child is Label3D:
			var tag := child as Label3D
			tag.font_size = int(42.0 * maxf(0.55, SLIME_SCALE))
			tag.position.y = h * 1.4
		elif child is CPUParticles3D:
			(child as CPUParticles3D).scale = Vector3.ONE * maxf(0.4, SLIME_SCALE)
		elif child is MeshInstance3D:
			# Sombra blob (MeshInstance3D direto do corpo).
			(child as MeshInstance3D).scale = Vector3.ONE * SLIME_SCALE
		elif child is Node3D:
			# Raiz do modelo; o corpo já foi normalizado para a altura base.
			(child as Node3D).scale = Vector3.ONE * SLIME_SCALE
