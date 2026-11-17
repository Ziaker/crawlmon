class_name MfGameFeel
extends Node

# Camada de game feel da exploracao da Murky Forest: so feedback visual.
# Nao muda regra, dano, movimento, colisao nem estado de jogo.
# Nada de personagem, time ou lado (D-235).

const DECAY := 1.6
const MAX_OFFSET := 2.4

# Tiers de intensidade do impacto sentido pelo jogador.
const TIER_SMALL := 0.12
const TIER_MEDIUM := 0.25
const TIER_LARGE := 0.45

var camera: Camera3D
var trauma := 0.0

var _t := 0.0


func add(amount: float) -> void:
	# Soma o trauma, nunca substitui: impulsos curtos se acumulam.
	trauma = clampf(trauma + amount, 0.0, 1.0)


func impulse(tier: String) -> void:
	match tier:
		"medium":
			add(TIER_MEDIUM)
		"large":
			add(TIER_LARGE)
		_:
			# Tier desconhecido cai no small.
			add(TIER_SMALL)


func step(delta: float) -> void:
	if trauma <= 0.0:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		return

	# Decaimento linear do trauma ao longo do tempo.
	trauma = maxf(trauma - DECAY * delta, 0.0)

	# trauma^2 concentra a forca no pico e suaviza o final do shake.
	var shake := trauma * trauma
	_t += delta * 26.0

	# Seno amostrado no tempo (sem rand por quadro): shake continuo e sem corte seco.
	camera.h_offset = MAX_OFFSET * shake * sin(_t * 1.7)
	camera.v_offset = MAX_OFFSET * shake * sin(_t * 2.3)
