class_name MotionSmokeView
extends Node3D
## Representação "Fumaça/billboards" (D-044, §8.1): quads voltados para a câmera num MultiMeshInstance3D com
## ShaderMaterial (.gdshader), usando a folha de fumaça que o jogo já tem (assets/vfx/flipbook_smoke.png,
## 4 × 4 quadros: a baforada nasce, enche e se dissipa). Mistura alfa, sem adição luminosa (§19.5).
## O quadro acompanha a IDADE da amostra (rastro/pós-imagem); amostras atuais usam um quadro de corpo.
## Giro e variação de tamanho são fixos por elemento (hash do id). Só consome MotionSample; neutra (§8.3).

const SHADER_PATH := "res://shaders/motion_lab/motion_smoke.gdshader"
const SHEET_PATH := "res://assets/vfx/flipbook_smoke.png"
const FRAMES := 16

## Diâmetro de um puff com largura de amostra 1, em metros.
var puff_size: float = 0.12
## Idade, em segundos, em que o puff chega ao último quadro (dissipado).
var puff_life: float = 0.8
var shown_count: int = 0
## Ordem de desenho usada no último quadro (índices dos puffs desenhados); para inspeção e testes.
var last_order: PackedInt32Array = PackedInt32Array()

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
	mat.set_shader_parameter("sheet_tex", load(SHEET_PATH))
	mat.set_shader_parameter("h_frames", 4)
	mat.set_shader_parameter("v_frames", 4)
	quad.material = mat
	_mm.mesh = quad
	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = _mm
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mmi)


## Giro, tamanho e quadro de um puff. Função pura do elemento e da idade.
static func puff_params(s: MotionSample, size: float, life: float) -> Dictionary:
	var lo := s.element_id & 0xFFFFFFFF
	var hi := s.element_id >> 32
	var frame: int
	if s.age > 0.0:
		frame = roundi(clampf(s.age / maxf(life, 1e-6), 0.0, 1.0) * float(FRAMES - 1))
	else:
		frame = 3 + int(MotionHash.float01(0, lo, hi, 33) * 4.0)
	return {
		"roll": TAU * MotionHash.float01(0, lo, hi, 31),
		"size": size * maxf(s.width, 0.0) * (0.8 + 0.4 * MotionHash.float01(0, lo, hi, 32)),
		"frame": frame,
	}


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
		pos.append(s.position)
	var order: PackedInt32Array
	if cam.is_finite():
		order = back_to_front(pos, cam)
	else:
		order = PackedInt32Array(range(drawn.size()))
	last_order = order
	var n := 0
	for k in order:
		var s := drawn[k]
		var p := puff_params(s, puff_size, puff_life)
		var base := MotionPointsView.branch_color(s.branch).lerp(Color(0.82, 0.84, 0.88), 0.6)
		var glow := clampf(s.intensity, 0.0, 1.5)
		_mm.set_instance_transform(n, Transform3D(Basis.from_scale(Vector3.ONE * p["size"]), s.position))
		_mm.set_instance_color(n, Color(base.r * glow, base.g * glow, base.b * glow, clampf(s.opacity, 0.0, 1.0)))
		_mm.set_instance_custom_data(n, Color(p["roll"], float(p["frame"]), 0.0, 0.0))
		n += 1
	_mm.visible_instance_count = n
	shown_count = n
