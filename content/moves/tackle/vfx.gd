extends MoveVfx
## Fase 4 (D-1079/D-308): piloto do Tackle. O impacto continua exatamente no
## módulo atual `FxImpacts._tackle_impact`; o script só prova o roteamento por
## `MoveData.vfx_script`, sem mudar nós, tempos ou visual. O relógio e as
## decisões continuam no Battle/BattleFx (D-019/D-1040).

func impact(_inc: Incoming, pos: Vector3, big: bool, dir: Vector3) -> Array[Node3D]:
	if fx == null:
		return []
	return fx.fx_impacts._tackle_impact(pos, dir, big)
