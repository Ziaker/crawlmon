class_name MotionBehavior
extends RefCounted
## Contrato de um comportamento (§4.1). A Etapa 2 criará os M01–M20 estendendo esta classe.
##
## Regras do contrato:
## - `apply` é uma função pura: mesma entrada (amostras, parâmetros, contexto, tempo local) -> mesma saída.
## - Recebe amostras já convertidas para o espaço da camada e devolve NOVAS amostras (não altera a entrada).
## - Para operações sem topologia devolve o mesmo número de amostras, com os mesmos `element_id`, na mesma ordem.
## - Para OFFSET, a posição devolvida é um deslocamento; para MULTIPLY_ATTRIBUTE, largura/intensidade/opacidade
##   são multiplicadores; para MASK, só `visible` conta (ver MotionTypes.Op).
## - Nunca decide dano, colisão, câmera ou estado de combate.

var id: StringName = &""
var version: int = 1
var display_name: String = ""
var description: String = ""
var group: StringName = &""
var kind: int = MotionTypes.Kind.MODIFIER
var accepted_operations: Array[int] = []
var params: Array[MotionParam] = []
## true se o resultado depende de estados de instantes anteriores (M19, M20).
var needs_history: bool = false


## Quantas amostras `apply` devolve para `n_in` amostras selecionadas (verificado antes de alocar).
## TOPOLOGY: tamanho da substituição. HISTORICAL/PERSIST: quantas amostras serão acrescentadas.
func output_count(n_in: int, _p: Dictionary) -> int:
	return n_in


func apply(samples: Array[MotionSample], _p: Dictionary, _ctx: MotionContext, _local_time: float, _layer_id: StringName) -> Array[MotionSample]:
	return samples


func find_param(p_name: String) -> MotionParam:
	for p in params:
		if String(p.name) == p_name:
			return p
	return null


## Preenche os padrões; as chaves resultantes são String.
func resolve_params(given: Dictionary) -> Dictionary:
	var out := {}
	for p in params:
		out[String(p.name)] = p.default_value
	for k in given.keys():
		out[String(k)] = given[k]
	return out


func validate_params(given: Dictionary, layer_id: StringName) -> Array[MotionDiagnostic]:
	var out: Array[MotionDiagnostic] = []
	for k in given.keys():
		var p := find_param(String(k))
		if p == null:
			out.append(MotionDiagnostic.error(&"param_unknown", "parâmetro desconhecido '%s' em %s" % [k, id], layer_id))
			continue
		var msg := p.check(given[k])
		if msg != "":
			out.append(MotionDiagnostic.error(&"param_domain", msg, layer_id))
	return out
