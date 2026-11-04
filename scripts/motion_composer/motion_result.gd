class_name MotionResult
extends RefCounted
## Saída de uma avaliação: dados puros (§4.3). Sem comandos de dano, colisão, câmera ou combate.

var samples: Array[MotionSample] = []
var diagnostics: Array[MotionDiagnostic] = []
## Revisão da composição que produziu este resultado.
var revision: int = 0
var time: float = 0.0
## Métricas de inspeção (§12.1): samples, history_samples, layers_active, eval_usec.
var stats: Dictionary = {}


func has_errors() -> bool:
	for d in diagnostics:
		if d.is_error():
			return true
	return false
