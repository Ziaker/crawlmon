class_name MotionSample
extends RefCounted
## Uma amostra do fluxo de movimento (§4.3, §19.2). Dado puro: não conhece Node, malha nem material.
## Eixo longitudinal local = +Z; unidades Godot (metros); tempo em segundos.

## Coordenada longitudinal normalizada de repouso (0..1).
var u: float = 0.0
## Coordenadas transversais de repouso (X/Y).
var rest: Vector2 = Vector2.ZERO
## Identidade estável do elemento (não depende do tempo nem de quadros renderizados).
var element_id: int = 0
## Caminho do ramo: "root", "root/<camada>.<índice>", ...
var branch: String = "root"

var position: Vector3 = Vector3.ZERO
## Base local; basis.z é a tangente.
var basis: Basis = Basis.IDENTITY
var width: float = 1.0
var intensity: float = 1.0
var opacity: float = 1.0
var visible: bool = true


static func make_rest(p_u: float, p_element_id: int, length: float, p_rest: Vector2 = Vector2.ZERO) -> MotionSample:
	var s := MotionSample.new()
	s.u = p_u
	s.rest = p_rest
	s.element_id = p_element_id
	s.position = Vector3(p_rest.x, p_rest.y, p_u * length)
	return s


func duplicate_sample() -> MotionSample:
	var c := MotionSample.new()
	c.u = u
	c.rest = rest
	c.element_id = element_id
	c.branch = branch
	c.position = position
	c.basis = basis
	c.width = width
	c.intensity = intensity
	c.opacity = opacity
	c.visible = visible
	return c


func tangent() -> Vector3:
	return basis.z


func is_finite_sample() -> bool:
	return position.is_finite() and basis.x.is_finite() and basis.y.is_finite() and basis.z.is_finite() \
		and is_finite(width) and is_finite(intensity) and is_finite(opacity) and is_finite(u) \
		and rest.is_finite()


## Caminho de ramo derivado do ramo-pai, do id da camada e do índice (§19.3).
static func branch_path(parent: String, layer_id: StringName, index: int) -> String:
	return "%s/%s.%d" % [parent, String(layer_id), index]


## Id de elemento derivado de forma determinística (~62 bits, para não colidir em dezenas de milhares de amostras).
static func derive_id(parent_id: int, layer_id: StringName, index: int, p_seed: int) -> int:
	var lh: int = String(layer_id).hash() & 0xFFFFFFFF
	var hi: int = MotionHash.mix(p_seed, parent_id & 0xFFFFFFFF, lh, index)
	var lo: int = MotionHash.mix(p_seed ^ 0x5BD1E995, parent_id & 0xFFFFFFFF, lh, index) & 0x3FFFFFFF
	return (hi << 30) | lo
