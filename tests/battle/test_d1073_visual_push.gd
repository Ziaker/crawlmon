extends SceneTree
## D-1073: a projectile does not shove the target on contact; melee and mid-range (CAST) do. A Move may
## override `visual_push` at creation (-1 default, 0 never, 1 always).
## Roda com: godot --headless --path . --script res://tests/battle/test_d1073_visual_push.gd


func _init() -> void:
	print("\n=================================================================")
	print("   CRAWLMON — PROJÉTEIS NÃO EMPURRAM VISUALMENTE (D-1073)")
	print("=================================================================")
	var melee := Skill.new("Melee Teste", 1.0, 2, Element.Type.FISICO, Skill.Kind.MELEE)
	var proj := Skill.new("Projétil Teste", 1.0, 2, Element.Type.FISICO, Skill.Kind.PROJECTILE)
	var cast := Skill.new("Mid Teste", 1.0, 2, Element.Type.FISICO, Skill.Kind.CAST)
	var status := Skill.new("Status Teste", 0.0, 2, Element.Type.LUZ, Skill.Kind.STATUS)
	assert(melee.pushes_visually(), "melee empurra")
	assert(not proj.pushes_visually(), "projétil não empurra")
	assert(cast.pushes_visually(), "mid-range (CAST) empurra")
	assert(not status.pushes_visually(), "status não empurra")
	print("  [PASS] Melee/CAST empurram; projétil/status não.")

	var proj_yes := Skill.new("Projétil Exceção", 1.0, 2, Element.Type.FISICO, Skill.Kind.PROJECTILE)
	proj_yes.visual_push = 1
	assert(proj_yes.pushes_visually(), "projétil com visual_push=1 empurra")
	var melee_no := Skill.new("Melee Sem Empurrão", 1.0, 2, Element.Type.FISICO, Skill.Kind.MELEE)
	melee_no.visual_push = 0
	assert(not melee_no.pushes_visually(), "melee com visual_push=0 não empurra")
	print("  [PASS] A exceção por Move funciona nos dois sentidos.")

	var tidal := Skill.new("Tidal Surge", 1.0, 2, Element.Type.AGUA_GELO, Skill.Kind.PROJECTILE, false, false, false, 0.8)
	assert(not tidal.pushes_visually(), "Tidal Surge (projétil) não empurra")
	var fire := Skill.fire_skills()[0]
	assert(fire.pushes_visually(), "Fire Bullet mantém a exceção explícita (D-236/D-1051)")
	print("  [PASS] Tidal Surge não empurra; Fire Bullet mantém a exceção explícita.")
	print("  TODOS OS TESTES PASSARAM.")
	quit()
