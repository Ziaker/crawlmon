class_name MotionHash
extends RefCounted
## Hash inteiro determinístico de 32 bits (§2.4). Substitui qualquer chamada aleatória dependente
## da ordem de execução: o mesmo (semente, a, b, c) sempre produz o mesmo valor.


static func mix(p_seed: int, a: int, b: int = 0, c: int = 0) -> int:
	var h: int = (p_seed & 0xFFFFFFFF) ^ 0x9E3779B9
	h = _step(h, a)
	h = _step(h, b)
	h = _step(h, c)
	return h


static func float01(p_seed: int, a: int, b: int = 0, c: int = 0) -> float:
	return float(mix(p_seed, a, b, c)) / 4294967296.0


static func _step(h: int, v: int) -> int:
	h = (h ^ (v & 0xFFFFFFFF)) & 0xFFFFFFFF
	h = (h * 0x85EBCA6B) & 0xFFFFFFFF
	h ^= h >> 13
	h = (h * 0xC2B2AE35) & 0xFFFFFFFF
	h ^= h >> 16
	return h & 0xFFFFFFFF
