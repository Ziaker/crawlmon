class_name MotionResult
extends RefCounted
## Saída de uma avaliação: dados puros (§4.3). Sem comandos de dano, colisão, câmera ou combate.

var samples: Array[MotionSample] = []
var diagnostics: Array[MotionDiagnostic] = []
## Revisão da composição que produziu este resultado.
var revision: int = 0
var time: float = 0.0


func has_errors() -> bool:
	for d in diagnostics:
		if d.is_error():
			return true
	return false
