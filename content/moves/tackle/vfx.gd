extends MoveVfx
## Fase 4 (D-1079): composição do impacto do Tackle no pacote do Move.
## O corpo abaixo é o mesmo de FxImpacts._tackle_impact; os helpers e o
## relógio continuam no Battle/BattleFx (D-019/D-1040).

func impact(_inc: Incoming, pos: Vector3, big: bool, strike_dir: Vector3) -> Array[Node3D]:
	var k := 1.45 if big else 1.0
	var dir := strike_dir.normalized() if strike_dir.length_squared() > 0.001 else Vector3.FORWARD
	var ground := Vector3(pos.x, 0.04, pos.z)
	var nodes: Array[Node3D] = []

	# 1. Flash star no ponto exato de contato
	VfxLib.flash_star(fx, pos, Color.WHITE, 3.4 * k, 0.16)

	# 2. Cone de Pressão Sônica / Choque de Ar (3D mesh shock_cone.glb + mesh_slash.gdshader)
	var cone := VfxLib.mesh_slash(fx, pos - dir * 0.25, dir, Color(1.0, 0.94, 0.78), 0.0, 1.45 * k, 0.28, "shock_cone", 3.2)
	cone.name = "TackleShockCone"
	nodes.append(cone)

	# 3. Arcos Cinéticos Duplos de Deslocamento de Ar (slash_arc.glb cruzados)
	var arc_a := VfxLib.mesh_slash(fx, pos, dir, Color(1.0, 0.98, 0.88), 35.0, 1.35 * k, 0.24, "slash_arc", 3.0)
	arc_a.name = "TackleSlashArcA"
	nodes.append(arc_a)
	var arc_b := VfxLib.mesh_slash(fx, pos, dir, Color(1.0, 0.82, 0.45), -45.0, 1.20 * k, 0.22, "slash_arc", 2.6)
	arc_b.name = "TackleSlashArcB"
	nodes.append(arc_b)

	# 4. Flipbook Anime de Impacto (16 frames) com núcleo quente
	var fb_main := VfxLib.flipbook(fx, pos, "impact", Color(1.0, 0.95, 0.82), 4.6 * k, 0.32, randf_range(-15.0, 15.0), 3.4)
	fb_main.name = "TackleFlipbookMain"
	nodes.append(fb_main)

	var fb_core := VfxLib.flipbook(fx, pos, "impact", Color.WHITE, 2.8 * k, 0.22, 45.0, 3.8)
	fb_core.name = "TackleFlipbookCore"
	nodes.append(fb_core)

	# 5. Anel de Choque & Poeira Radial no Solo
	fx._shock(ground, Color(1.0, 0.88, 0.65), 4.5 * k, 0.35)
	var fb_dust := VfxLib.flipbook(fx, ground + Vector3(0, 0.45, 0), "smoke", Color(0.82, 0.78, 0.72), 3.8 * k, 0.48, 0.0, 1.5, false)
	fb_dust.name = "TackleGroundSmoke"
	nodes.append(fb_dust)

	# 6. Faíscas Direcionais Esticadas e Estilhaços Cinéticos
	VfxLib.burst(fx, pos, {
		"tex": VfxLib.spark_tex(), "amount": int(28 * k), "life": 0.35,
		"speed": Vector2(6.0, 14.0), "dir": dir + Vector3.UP * 0.35, "spread": 45.0,
		"size": Vector2(0.12, 0.32), "end_scale": 0.0, "align_y": true,
		"ramp": VfxLib.ramp([Color.WHITE, Color("ffbe0b"), Color("fb5607", 0.0)], [0.0, 0.35, 1.0])
	})

	VfxLib.burst(fx, pos, {
		"tex": VfxLib.smoke_tex(), "amount": int(12 * k), "life": 0.42,
		"speed": Vector2(3.0, 7.5), "dir": dir + Vector3.UP * 0.5, "spread": 60.0,
		"gravity": Vector3(0, -9.8, 0), "size": Vector2(0.25, 0.5), "end_scale": 1.4,
		"ramp": VfxLib.ramp([Color(0.72, 0.68, 0.62), Color(0.72, 0.68, 0.62, 0.0)], [0.0, 1.0])
	})

	return nodes


## Retained as an authored option for another move; Tackle routes to B1 above.
## Impacto B2: counter-pop, atmospheric dome and crossed concentric toroidal waves.
## Every principal node is returned so hit-stop can vibrate the whole contact shape.
