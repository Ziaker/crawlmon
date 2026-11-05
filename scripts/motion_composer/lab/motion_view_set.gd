class_name MotionViewSet
extends Node3D
## Conjunto das quatro representações (D-044) como um só nó: o laboratório tem um conjunto para a composição
## viva (B) e outro para a comparação A/B. Só desenha MotionSample; a troca de representação não toca nos dados.
## Representações: 0 pontos, 1 fitas, 2 pontos + fitas, 3 fragmentos, 4 fumaça/billboards.

var points: MotionPointsView
var ribbons: MotionRibbonsView
var fragments: MotionFragmentsView
var smoke: MotionSmokeView
var representation: int = 0


func _init() -> void:
	points = MotionPointsView.new()
	add_child(points)
	ribbons = MotionRibbonsView.new()
	add_child(ribbons)
	fragments = MotionFragmentsView.new()
	add_child(fragments)
	smoke = MotionSmokeView.new()
	add_child(smoke)
	set_representation(0)


func set_representation(i: int) -> void:
	representation = clampi(i, 0, 4)
	points.visible = representation == 0 or representation == 2
	ribbons.visible = representation == 1 or representation == 2
	fragments.visible = representation == 3
	smoke.visible = representation == 4


## Copia os ajustes de desenho (tamanhos, larguras e controles da poeira) de outro conjunto.
func apply_settings(o: MotionViewSet) -> void:
	points.point_size = o.points.point_size
	ribbons.ribbon_width = o.ribbons.ribbon_width
	fragments.fragment_size = o.fragments.fragment_size
	for prop in ["puff_size", "puff_life", "puff_growth", "puff_speed_min", "puff_speed_max", "puff_damping",
			"puff_rise", "puff_radius", "puff_density_var", "puff_flicker", "puff_fade_pow"]:
		smoke.set(prop, o.smoke.get(prop))


## Desenha só a representação escolhida. `cam_world` = posição da câmera no mundo (para ordenar a fumaça).
func draw_samples(samples: Array[MotionSample], cam_world: Vector3 = Vector3.INF) -> void:
	if representation == 0 or representation == 2:
		points.show_samples(samples)
	if representation == 1 or representation == 2:
		ribbons.show_samples(samples)
	if representation == 3:
		fragments.show_samples(samples)
	if representation == 4:
		smoke.show_samples(samples, (cam_world - global_position) if cam_world.is_finite() else Vector3.INF)
