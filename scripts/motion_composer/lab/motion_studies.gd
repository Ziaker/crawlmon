class_name MotionStudies
extends RefCounted
## Estudos individuais (§10.3, §19.7): uma demonstração isolada de cada comportamento M01–M20 e a receita da §6.
## Cada estudo é uma composição feita só com camadas da biblioteca, com ciclo de 3 s:
## nascimento (0–0,5 s), desenvolvimento, transformação (≈0,5–2 s) e dissipação (2,4–3 s).
## As camadas "aux_*" são o acabamento do estudo (nascer e dissolver, M17 e M18): apresentação, não o
## comportamento estudado; podem ser desligadas para inspecionar só o comportamento (M17 e M18 não têm aux).
## Os parâmetros são propostas do agente para mostrar o comportamento; não são valores aprovados.

const Op := MotionTypes.Op
const DURATION := 3.0
const RECIPE := &"RECEITA"

const IDS: Array[StringName] = [
	&"M01", &"M02", &"M03", &"M04", &"M05", &"M06", &"M07", &"M08", &"M09", &"M10",
	&"M11", &"M12", &"M13", &"M14", &"M15", &"M16", &"M17", &"M18", &"M19", &"M20",
]

const NOTES := {
	&"M01": "A linha vira uma hélice: raio, passo, voltas e giro no tempo. Gerador: ignora a trajetória anterior.",
	&"M02": "Zigue-zague de vértices vivos que anda ao longo do eixo.",
	&"M03": "Serpentina: onda senoidal contínua que se propaga, com uma curvatura parabólica leve.",
	&"M04": "Curva de Bézier cujos pontos de controle internos derivam no tempo; as pontas ficam fixas.",
	&"M05": "Vórtice sobre uma hélice: gira mais perto do centro e menos nas bordas, e acelera com o tempo.",
	&"M06": "Convergência: a hélice é puxada para o ponto-alvo no centro, mais forte nos elementos mais próximos.",
	&"M07": "Turbulência: tremor contínuo no espaço e no tempo, reprodutível pela semente.",
	&"M08": "Torção progressiva sobre um zigue-zague: a rotação aumenta ao longo do comprimento e se propaga.",
	&"M09": "Curvatura: a trajetória reta dobra em arco, mais na ponta que na base.",
	&"M10": "Alongamento: o trecho central da hélice ganha comprimento e empurra o resto do eixo.",
	&"M11": "Compressão: o núcleo se concentra e estreita, e as extremidades são preservadas.",
	&"M12": "Pulso viajante: uma concentração de espessura, intensidade e deslocamento percorre a linha, frente curta e cauda longa.",
	&"M13": "Onda radial: uma frente se expande a partir do eixo da hélice e se dissipa com a distância.",
	&"M14": "Bifurcação: um fluxo se abre em três caminhos identificados por cor.",
	&"M15": "Recombinação: os três ramos voltam a se reunir, mantendo suas identidades, e a intensidade se divide entre eles.",
	&"M16": "Explosão direcional: os elementos saem em cone para fora, em alcances diferentes, e se dissipam.",
	&"M17": "Crescimento progressivo: o trecho visível avança do início ao fim, com borda suave.",
	&"M18": "Dissolução progressiva: o efeito some do início para o fim, complementar do crescimento.",
	&"M19": "Rastro temporal: cada elemento deixa um fluxo contínuo de estados anteriores que afina e some.",
	&"M20": "Pós-imagem: cópias discretas de estados anteriores, cada uma um ramo, esmaecendo em degraus.",
	&"RECEITA": "Receita de teste da §6 (sem rastro): compressão, crescimento, zigue-zague e torção, bifurcação em 3, recombinação, onda e explosão, dissolução. Não é um Move.",
}

static var _cache: Dictionary = {}


static func ids() -> Array[StringName]:
	var out: Array[StringName] = IDS.duplicate()
	out.append(RECIPE)
	return out


static func note(id: StringName) -> String:
	return NOTES.get(id, "")


static func title(id: StringName) -> String:
	if id == RECIPE:
		return "Receita da §6 (sem rastro)"
	for b in MotionBehaviors.all():
		if b.id == id:
			return "%s — %s" % [id, b.display_name]
	return String(id)


## [id da camada, comportamento, operação, parâmetros, defasagem, papel] (papel: base | main | aux).
static func _l(lid: String, bid: StringName, op: int, params: Dictionary, offset: float = 0.0, role: String = "main") -> Array:
	return [StringName(lid), bid, op, params, offset, role]


static func _helix(spin: float = 0.0, radius: float = 0.3, growth: float = 0.0) -> Array:
	return _l("base_helice", &"M01", Op.REPLACE, {"radius": radius, "radius_growth": growth, "pitch": 0.5, "turns": 2.0, "spin_deg_s": spin}, 0.0, "base")


static func _specs(id: StringName) -> Array:
	if _cache.has(id):
		return _cache[id]
	var out: Array = []
	match id:
		&"M01":
			out = [_l("helice", &"M01", Op.REPLACE, {"radius": 0.25, "radius_growth": 0.15, "pitch": 0.5, "turns": 3.0, "spin_deg_s": 90.0})]
		&"M02":
			out = [_l("zigzag", &"M02", Op.OFFSET, {"amplitude": 0.12, "frequency": 5.0, "speed": 0.5})]
		&"M03":
			out = [_l("serpentina", &"M03", Op.OFFSET, {"amplitude": 0.1, "wavelength": 0.5, "curvature": 0.6, "speed": 0.6})]
		&"M04":
			out = [_l("bezier", &"M04", Op.REPLACE, {})]
		&"M05":
			out = [_helix(), _l("vortice", &"M05", Op.OFFSET, {"center": Vector3(0, 0, 0.5), "angular_deg": 150.0, "angular_speed_deg_s": 60.0, "radius": 1.0})]
		&"M06":
			out = [_helix(0.0, 0.4), _l("convergencia", &"M06", Op.OFFSET, {"target": Vector3(0, 0, 0.5), "strength": 1.0, "reach": 2.0, "t_start": 0.6, "t_duration": 1.4})]
		&"M07":
			out = [_l("turbulencia", &"M07", Op.OFFSET, {"scale": 0.35, "intensity": 0.14, "time_hz": 1.5})]
		&"M08":
			out = [_l("base_zigzag", &"M02", Op.OFFSET, {"amplitude": 0.2, "frequency": 3.0}, 0.0, "base"), _l("torcao", &"M08", Op.DEFORM, {"amount_deg": 360.0, "t_start": 0.5, "t_duration": 1.5})]
		&"M09":
			out = [_l("curvatura", &"M09", Op.DEFORM, {"amount_deg": 130.0, "t_start": 0.5, "t_duration": 1.5})]
		&"M10":
			out = [_helix(), _l("alongamento", &"M10", Op.DEFORM, {"factor": 2.5, "center": 0.5, "extent": 0.5, "t_start": 0.5, "t_duration": 1.5})]
		&"M11":
			out = [_helix(), _l("compressao", &"M11", Op.DEFORM, {"strength": 0.85, "extent": 0.5, "softness": 0.2, "radial": 0.6, "t_start": 0.5, "t_duration": 1.5})]
		&"M12":
			var pulse := {"speed": 0.45, "width": 0.12, "tail": 3.0}
			out = [_l("pulso_posicao", &"M12", Op.OFFSET, _merge(pulse, {"amplitude": 0.0, "displace": 0.18})),
				_l("pulso_espessura", &"M12", Op.MULTIPLY_ATTRIBUTE, _merge(pulse, {"amplitude": 2.0, "thickness_gain": 2.0, "displace": 0.0}))]
		&"M13":
			var wave := {"speed": 0.6, "width": 0.08, "range": 2.0, "dissipation": 0.5}
			out = [_helix(0.0, 0.0, 0.8), _l("onda_posicao", &"M13", Op.OFFSET, _merge(wave, {"amplitude": 0.2})),
				_l("onda_intensidade", &"M13", Op.MULTIPLY_ATTRIBUTE, _merge(wave, {"amplitude": 0.0, "intensity_gain": 1.5}))]
		&"M14":
			out = [_l("bifurcacao", &"M14", Op.BRANCH, {"branches": 3, "split_u": 0.25, "angle_deg": 35.0, "distance": 0.45, "t_start": 0.4, "t_duration": 1.2})]
		&"M15":
			out = [_l("base_bifurcacao", &"M14", Op.BRANCH, {"branches": 3, "split_u": 0.25, "angle_deg": 35.0, "distance": 0.45, "t_start": 0.2, "t_duration": 0.6}, 0.0, "base"),
				_l("recombinacao", &"M15", Op.MERGE, {"merge_start": 0.55, "merge_end": 0.9, "t_start": 1.3, "t_duration": 1.0})]
		&"M16":
			var burst := {"radial": 1.0, "origin": Vector3(0, 0, 0.5), "cone_deg": 70.0, "distance": 1.0, "t_start": 1.1, "t_duration": 0.9}
			out = [_helix(), _l("explosao", &"M16", Op.OFFSET, burst), _l("explosao_dissipa", &"M16", Op.MULTIPLY_ATTRIBUTE, _merge(burst, {"dissipate": 1.0, "curve": 0.6}))]
		&"M17":
			out = [_helix(), _l("crescimento", &"M17", Op.MULTIPLY_ATTRIBUTE, {"t_start": 0.2, "t_duration": 1.6, "width": 0.2, "affect_opacity": true})]
		&"M18":
			out = [_helix(), _l("dissolucao", &"M18", Op.MULTIPLY_ATTRIBUTE, {"t_start": 1.2, "t_duration": 1.6, "width": 0.2, "affect_opacity": true})]
		&"M19":
			out = [_helix(120.0), _l("rastro", &"M19", Op.PERSIST, {"duration": 0.8, "sample_interval": 0.05})]
		&"M20":
			out = [_helix(120.0), _l("posimagem", &"M20", Op.PERSIST, {"count": 5, "interval": 0.12})]
		&"RECEITA":
			out = [
				_l("compressao", &"M11", Op.DEFORM, {"strength": 0.8, "center": 0.5, "extent": 0.5, "softness": 0.2}),
				_l("crescimento", &"M17", Op.MULTIPLY_ATTRIBUTE, {"t_duration": 0.45, "width": 0.1}),
				_l("zigzag", &"M02", Op.OFFSET, {"amplitude": 0.06, "frequency": 6.0}, 0.45),
				_l("torcao", &"M08", Op.DEFORM, {"amount_deg": 120.0}, 0.45),
				_l("bifurcacao", &"M14", Op.BRANCH, {"branches": 3, "split_u": 0.3, "angle_deg": 35.0, "distance": 0.4}, 1.05),
				_l("serpentina", &"M03", Op.OFFSET, {"amplitude": 0.03, "wavelength": 0.3}, 1.5),
				_l("turbulencia", &"M07", Op.OFFSET, {"intensity": 0.02}, 1.5),
				_l("recombinacao", &"M15", Op.MERGE, {"merge_start": 0.6, "merge_end": 0.9, "t_duration": 0.3}, 1.95),
				_l("onda", &"M13", Op.OFFSET, {"speed": 1.5, "amplitude": 0.05}, 2.25),
				_l("explosao", &"M16", Op.OFFSET, {"distance": 0.3, "t_duration": 0.3}, 2.25),
				_l("dissolucao", &"M18", Op.MULTIPLY_ATTRIBUTE, {"t_duration": 0.45}, 2.55),
			]
	_cache[id] = out
	return out


static func _merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	out.merge(b, true)
	return out


## Monta a composição do estudo. `with_aux` liga o acabamento (nascer e dissolver); M17, M18 e a receita não o têm.
static func build(id: StringName, with_aux: bool = true) -> MotionComposition:
	var c := MotionComposition.new()
	c.id = StringName("estudo_%s" % id)
	c.duration = DURATION
	c.sample_count = 96 if id == RECIPE else 64
	c.seed = 2026 if id == RECIPE else 5
	var specs := _specs(id)
	var persist_last := id == &"M19" or id == &"M20"
	var has_aux := id != &"M17" and id != &"M18" and id != RECIPE
	var aux: Array = []
	if has_aux:
		aux = [
			_l("aux_nascimento", &"M17", Op.MULTIPLY_ATTRIBUTE, {"t_duration": 0.5, "width": 0.15, "affect_opacity": true}, 0.0, "aux"),
			_l("aux_dissolucao", &"M18", Op.MULTIPLY_ATTRIBUTE, {"t_start": 2.4, "t_duration": 0.6, "width": 0.15, "affect_opacity": true}, 0.0, "aux"),
		]
	var ordered: Array = []
	if persist_last:
		ordered.append_array(specs.slice(0, specs.size() - 1))
		ordered.append_array(aux)
		ordered.append(specs[specs.size() - 1])
	else:
		ordered.append_array(specs)
		ordered.append_array(aux)
	for sp in ordered:
		var l := MotionLayer.new()
		l.id = sp[0]
		l.behavior_id = sp[1]
		l.op = sp[2]
		l.params = (sp[3] as Dictionary).duplicate(true)
		l.time_offset = sp[4]
		if sp[5] == "aux":
			l.enabled = with_aux
		c.add_layer(l)
	return c


## Camadas do comportamento estudado (sem a base nem o acabamento).
static func main_layer_ids(id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for sp in _specs(id):
		if sp[5] == "main":
			out.append(sp[0])
	return out


static func aux_layer_ids(c: MotionComposition) -> Array[StringName]:
	var out: Array[StringName] = []
	for l in c.layers:
		if String(l.id).begins_with("aux_"):
			out.append(l.id)
	return out
