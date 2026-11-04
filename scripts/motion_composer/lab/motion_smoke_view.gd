class_name MotionSmokeView
extends Node3D
## Representação "Fumaça/billboards" (D-044, §8.1): quads voltados para a câmera num MultiMeshInstance3D com
## ShaderMaterial (.gdshader). O visual segue o que o jogo já faz para fumaça e poeira (D-041, fx_motion):
## baforadas GRANDES de ruído suave, cor bege quente, que crescem com a idade, esmaecem e se abrem/sobem.
## Mistura alfa, sem adição luminosa (§19.5). Só consome MotionSample; os efeitos de idade abaixo
## (crescer, subir, abrir) são decoração da representação, derivada só do id e da idade, e não alteram
## nenhuma amostra; com crescimento 1, subida 0 e dispersão 0 a vista é fiel às posições.

const SHADER_PATH := "res://shaders/motion_lab/motion_smoke.gdshader"
const CELL := 64
const DUST_COLOR := Color(0.82, 0.78, 0.72)
## Quanto a cor do ramo tinge o bege (0 = só bege; 1 = só cor do ramo).
const BRANCH_TINT := 0.06

## Diâmetro de uma baforada com largura de amostra 1, em metros.
var puff_size: float = 0.35
## Idade, em segundos, em que a baforada chega ao tamanho final.
var puff_life: float = 0.9
## Fator de tamanho ao fim da vida (o jogo usa 1,4 a 1,6).
var puff_growth: float = 1.6
## Velocidade de subida (m/s) e de abertura (m/s), proporcionais à idade.
var puff_rise: float = 0.5
var puff_spread: float = 0.5
var shown_count: int = 0
## Ordem de desenho usada no último quadro (índices dos puffs desenhados); para inspeção e testes.
var last_order: PackedInt32Array = PackedInt32Array()

static var _atlas: ImageTexture

var _mmi: MultiMeshInstance3D
var _mm: MultiMesh
var _capacity: int = 0


func _init() -> void:
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("puff_tex", make_puff_atlas())
	mat.set_shader_parameter("h_frames", 2)
	mat.set_shader_parameter("v_frames", 2)
	quad.material = mat
	_mm.mesh = quad
	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = _mm
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mmi)


## Atlas 2 × 2 de baforadas de ruído suave (método do VfxLib.smoke_tex do jogo, com variação mais suave para
## não manchar, 4 variações de semente). Independente do código de combate; só gera pixels, sem temporizadores.
static func make_puff_atlas() -> ImageTexture:
	if _atlas != null:
		return _atlas
	var img := Image.create(CELL * 2, CELL * 2, false, Image.FORMAT_RGBA8)
	for variant in 4:
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.frequency = 0.055
		noise.fractal_octaves = 3
		noise.seed = 101 + variant * 37
		var ox := (variant % 2) * CELL
		var oy := (variant / 2) * CELL
		for y in CELL:
			for x in CELL:
				var r := Vector2(x - CELL * 0.5 + 0.5, y - CELL * 0.5 + 0.5).length() / (CELL * 0.5)
				var v := noise.get_noise_2d(x, y) * 0.5 + 0.5
				var a := pow(clampf(1.0 - r, 0.0, 1.0), 1.1) * clampf(0.15 + v * 1.25, 0.0, 1.0)
				img.set_pixel(ox + x, oy + y, Color(1, 1, 1, a))
	_atlas = ImageTexture.create_from_image(img)
	return _atlas


## Giro, tamanho e variação (0–3) de uma baforada. Função pura do elemento e da idade.
static func puff_params(s: MotionSample, size: float, life: float, growth: float) -> Dictionary:
	var lo := s.element_id & 0xFFFFFFFF
	var hi := s.element_id >> 32
	var age_f := clampf(s.age / maxf(life, 1e-6), 0.0, 1.0)
	return {
		"roll": TAU * MotionHash.float01(0, lo, hi, 31),
		"size": size * maxf(s.width, 0.0) * (0.8 + 0.4 * MotionHash.float01(0, lo, hi, 32)) * lerpf(1.0, growth, age_f),
		"frame": int(MotionHash.float01(0, lo, hi, 33) * 4.0) % 4,
	}


## Deslocamento decorativo da baforada: sobe e se abre em direção fixa por elemento (cone de 70° em torno
## da vertical), proporcional à idade. Amostras atuais (idade 0) não se deslocam.
static func puff_offset(s: MotionSample, rise: float, spread: float) -> Vector3:
	if s.age <= 0.0:
		return Vector3.ZERO
	var lo := s.element_id & 0xFFFFFFFF
	var hi := s.element_id >> 32
	var phi := TAU * MotionHash.float01(0, lo, hi, 34)
	var theta := deg_to_rad(70.0) * sqrt(MotionHash.float01(0, lo, hi, 35))
	var dir := Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi))
	return (Vector3.UP * rise + dir * spread) * s.age


## Índices dos puffs do mais distante ao mais próximo da câmera: translúcidos se misturam na ordem certa.
static func back_to_front(positions: PackedVector3Array, cam: Vector3) -> PackedInt32Array:
	var idx: Array = []
	var dist := PackedFloat32Array()
	dist.resize(positions.size())
	for i in positions.size():
		dist[i] = positions[i].distance_squared_to(cam)
		idx.append(i)
	idx.sort_custom(func(a: int, b: int) -> bool: return dist[a] > dist[b] or (dist[a] == dist[b] and a < b))
	return PackedInt32Array(idx)


## `cam` = posição da câmera para ordenar; Vector3.INF = sem ordenar.
func show_samples(samples: Array[MotionSample], cam: Vector3 = Vector3.INF) -> void:
	var need := samples.size()
	if need > _capacity:
		_capacity = maxi(need, _capacity * 2)
		_mm.instance_count = _capacity
	var drawn: Array[MotionSample] = []
	var pos := PackedVector3Array()
	for s in samples:
		if not s.visible or s.opacity <= 0.001 or s.width * puff_size <= 1e-5:
			continue
		drawn.append(s)
		pos.append(s.position + puff_offset(s, puff_rise, puff_spread))
	var order: PackedInt32Array
	if cam.is_finite():
		order = back_to_front(pos, cam)
	else:
		order = PackedInt32Array(range(drawn.size()))
	last_order = order
	var n := 0
	for k in order:
		var s := drawn[k]
		var p := puff_params(s, puff_size, puff_life, puff_growth)
		var base := DUST_COLOR.lerp(MotionPointsView.branch_color(s.branch), BRANCH_TINT)
		var glow := clampf(s.intensity, 0.0, 1.5)
		_mm.set_instance_transform(n, Transform3D(Basis.from_scale(Vector3.ONE * p["size"]), pos[k]))
		_mm.set_instance_color(n, Color(base.r * glow, base.g * glow, base.b * glow, clampf(s.opacity, 0.0, 1.0)))
		_mm.set_instance_custom_data(n, Color(p["roll"], float(p["frame"]), 0.0, 0.0))
		n += 1
	_mm.visible_instance_count = n
	shown_count = n
