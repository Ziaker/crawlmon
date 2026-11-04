class_name MotionSmokeView
extends Node3D
## Representação "Fumaça/billboards" (D-044, §8.1): quads voltados para a câmera num MultiMeshInstance3D com
## ShaderMaterial (.gdshader). O visual copia as regras da poeira que o próprio jogo faz (D-041, fx_motion
## `_dust_trail` e fx_impacts `_smoke`, medidas renderizando o VfxLib na mesma cena):
## - baforadas de 0,55 a 1,15 m com ruído manchado (mesmo método do VfxLib.smoke_tex), cor bege (0,82; 0,78; 0,72);
## - vida curta (0,38 s): nascem transparentes, chegam a 75 % de opacidade aos 20 % da vida e somem;
## - crescem até 1,8×; abrem em todas as direções com atrito (amortecimento 1,5) e uma leve subida (0,25 m/s²),
##   saindo de uma esfera de 0,4 m; velocidades de 0,5 a 3 m/s.
## Mistura alfa, sem adição luminosa (§19.5). Só consome MotionSample; o movimento das baforadas é decoração da
## vista, derivada só do id e da idade, e não altera nenhuma amostra (com velocidade 0, subida 0 e raio 0 a vista
## é fiel às posições).

const SHADER_PATH := "res://shaders/motion_lab/motion_smoke.gdshader"
const CELL := 64
const DUST_COLOR := Color(0.82, 0.78, 0.72)
## Quanto a cor do ramo tinge o bege (0 = só bege; 1 = só cor do ramo).
const BRANCH_TINT := 0.06
## Opacidade máxima da rampa de vida (o jogo usa 0,75).
const PEAK_ALPHA := 0.75
## Fração da vida em que a opacidade chega ao pico (o jogo usa 0,2).
const PEAK_AT := 0.2

## Diâmetro médio de uma baforada com largura de amostra 1, em metros (o jogo varia de 0,55 a 1,15).
var puff_size: float = 0.85
## Vida em segundos: crescimento e rampa de opacidade acontecem nela; mais velha que isso, a baforada some.
var puff_life: float = 0.55
## Fator de tamanho ao fim da vida (o jogo usa 1,8).
var puff_growth: float = 1.8
## Velocidade inicial mínima e máxima (m/s), atrito (1/s), subida (m/s²) e raio da esfera de origem (m).
var puff_speed_min: float = 0.5
var puff_speed_max: float = 3.0
var puff_damping: float = 1.5
var puff_rise: float = 0.25
var puff_radius: float = 0.4
## Jogo da opacidade (a poeira "mexe" muito com ela): variação de densidade entre baforadas (0 = todas iguais),
## oscilação da opacidade com a idade (0 = sem) e expoente da queda depois do pico (1 = reta, como o jogo).
var puff_density_var: float = 0.65
var puff_flicker: float = 0.35
var puff_fade_pow: float = 1.5
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


## Atlas 2 × 2 de baforadas de ruído manchado: o mesmo cálculo do VfxLib.smoke_tex do jogo (simplex suave,
## frequência 0,07, 3 oitavas, alfa = (1 − r)^1,2 × clamp(ruído × 1,6)), com 4 sementes. Independente do código
## de combate; só gera pixels, sem temporizadores.
static func make_puff_atlas() -> ImageTexture:
	if _atlas != null:
		return _atlas
	var img := Image.create(CELL * 2, CELL * 2, false, Image.FORMAT_RGBA8)
	for variant in 4:
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.frequency = 0.07
		noise.fractal_octaves = 3
		noise.seed = variant * 37
		var ox := (variant % 2) * CELL
		var oy := (variant / 2) * CELL
		for y in CELL:
			for x in CELL:
				var r := Vector2(x - CELL * 0.5 + 0.5, y - CELL * 0.5 + 0.5).length() / (CELL * 0.5)
				var v := noise.get_noise_2d(x, y) * 0.5 + 0.5
				var a := pow(clampf(1.0 - r, 0.0, 1.0), 1.2) * clampf(v * 1.6, 0.0, 1.0)
				img.set_pixel(ox + x, oy + y, Color(1, 1, 1, a))
	_atlas = ImageTexture.create_from_image(img)
	return _atlas


## Giro, tamanho e variação (0–3) de uma baforada. Função pura do elemento e da idade.
## Tamanho: de 65 % a 135 % do médio (com 0,85 m, os 0,55 a 1,15 m do jogo), crescendo até `growth` na vida.
static func puff_params(s: MotionSample, size: float, life: float, growth: float) -> Dictionary:
	var lo := s.element_id & 0xFFFFFFFF
	var hi := s.element_id >> 32
	var age_f := clampf(s.age / maxf(life, 1e-6), 0.0, 1.0)
	return {
		"roll": TAU * MotionHash.float01(0, lo, hi, 31),
		"size": size * maxf(s.width, 0.0) * (0.65 + 0.7 * MotionHash.float01(0, lo, hi, 32)) * lerpf(1.0, growth, age_f),
		"frame": int(MotionHash.float01(0, lo, hi, 33) * 4.0) % 4,
	}


## Rampa de opacidade pela vida (jogo: 0 → 0,75 aos 20 % → 0). Amostras atuais (idade 0) não têm vida: 1.
static func puff_alpha(age: float, life: float, fade_pow: float = 1.0) -> float:
	if age <= 0.0:
		return 1.0
	var f := age / maxf(life, 1e-6)
	if f >= 1.0:
		return 0.0
	if f <= PEAK_AT:
		return PEAK_ALPHA * f / PEAK_AT
	return PEAK_ALPHA * pow(1.0 - (f - PEAK_AT) / (1.0 - PEAK_AT), fade_pow)


## Densidade própria da baforada, em [1 − variação, 1]: umas são véus finos, outras são densas.
static func puff_density(s: MotionSample, variation: float) -> float:
	return 1.0 - variation * MotionHash.float01(0, s.element_id & 0xFFFFFFFF, s.element_id >> 32, 40)


## Oscilação da opacidade com a idade: multiplicador em [1 − quantidade, 1], com fase e frequência (3 a 7 Hz)
## próprias de cada baforada. Amostras atuais (idade 0) não oscilam.
static func puff_flicker_factor(s: MotionSample, amount: float) -> float:
	if s.age <= 0.0 or amount <= 0.0:
		return 1.0
	var lo := s.element_id & 0xFFFFFFFF
	var hi := s.element_id >> 32
	var freq := 3.0 + 4.0 * MotionHash.float01(0, lo, hi, 41)
	var phase := TAU * MotionHash.float01(0, lo, hi, 42)
	return 1.0 - amount * (0.5 - 0.5 * cos(TAU * freq * s.age + phase))


## Opacidade final de uma baforada: opacidade da amostra × rampa de vida × densidade × oscilação.
func puff_final_alpha(s: MotionSample) -> float:
	return clampf(s.opacity, 0.0, 1.0) * puff_alpha(s.age, puff_life, puff_fade_pow) * puff_density(s, puff_density_var) * puff_flicker_factor(s, puff_flicker)


## Deslocamento decorativo: ponto de partida dentro da esfera de origem + velocidade em direção qualquer
## (esfera inteira) com atrito + subida. Função pura do id e da idade.
static func puff_offset(s: MotionSample, speed_min: float, speed_max: float, damping: float, rise: float, radius: float) -> Vector3:
	var lo := s.element_id & 0xFFFFFFFF
	var hi := s.element_id >> 32
	var start := _unit(MotionHash.float01(0, lo, hi, 34), MotionHash.float01(0, lo, hi, 35)) * (radius * pow(MotionHash.float01(0, lo, hi, 36), 1.0 / 3.0))
	if s.age <= 0.0:
		return start
	var v := _unit(MotionHash.float01(0, lo, hi, 37), MotionHash.float01(0, lo, hi, 38)) * lerpf(speed_min, speed_max, MotionHash.float01(0, lo, hi, 39))
	var travel := s.age if damping <= 1e-6 else (1.0 - exp(-damping * s.age)) / damping
	return start + v * travel + Vector3(0.0, 0.5 * rise * s.age * s.age, 0.0)


## Direção uniforme na esfera a partir de dois números em [0, 1).
static func _unit(u1: float, u2: float) -> Vector3:
	var z := 1.0 - 2.0 * u1
	var r := sqrt(maxf(0.0, 1.0 - z * z))
	var a := TAU * u2
	return Vector3(r * cos(a), z, r * sin(a))


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
	var alpha := PackedFloat32Array()
	for s in samples:
		if not s.visible or s.width * puff_size <= 1e-5:
			continue
		var a := puff_final_alpha(s)
		if a <= 0.001:
			continue
		drawn.append(s)
		alpha.append(a)
		pos.append(s.position + puff_offset(s, puff_speed_min, puff_speed_max, puff_damping, puff_rise, puff_radius))
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
		_mm.set_instance_color(n, Color(base.r * glow, base.g * glow, base.b * glow, alpha[k]))
		_mm.set_instance_custom_data(n, Color(p["roll"], float(p["frame"]), 0.0, 0.0))
		n += 1
	_mm.visible_instance_count = n
	shown_count = n
