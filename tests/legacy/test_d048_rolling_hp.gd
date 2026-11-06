extends SceneTree
## D-048 archived by D-347: the rolling-HP odometer is not in the active battle anymore. This test
## keeps the old rules and math alive for when the creator asks for it again.

const Odometer := preload("res://scripts/legacy/rolling_hp_odometer.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		print("  [FAIL] %s" % msg)
	else:
		print("  [PASS] %s" % msg)


func _run() -> void:
	print("=================================================================")
	print("   CRAWLMON — ODÔMETRO DE HP ARQUIVADO (D-048 / D-347)")
	print("=================================================================")

	# 1. Drain speed: max_hp / 3.0 per second, minimum 5.
	_expect(is_equal_approx(Odometer.drain_speed(60), 20.0), "Vida 60 drena a 20 HP/s")
	_expect(is_equal_approx(Odometer.drain_speed(6), 5.0), "O mínimo de drenagem é 5 HP/s")

	# 2. Non-fatal and fatal damage targets.
	_expect(Odometer.target_after_damage(60, 30) == 30, "Dano não-fatal deixa o alvo em 30")
	_expect(Odometer.target_after_damage(30, 35) == 0, "Dano fatal vai direto a 0, sem rolamento")

	# 3. Healing updates the target and caps at max.
	_expect(Odometer.target_after_heal(60, 30, 100) == 90, "Cura durante o rolamento atualiza o alvo para 90")
	_expect(Odometer.target_after_heal(95, 30, 100) == 100, "Cura não passa do máximo")

	# 4. One tick moves toward the target; a 0.2x delta keeps 20% of the normal distance.
	var normal := Odometer.tick(100.0, 60, 100, 0.5)
	var slow := Odometer.tick(100.0, 60, 100, 0.1)
	_expect(is_equal_approx(normal, 83.333333), "0,5 s drenam ~16,67 HP em vida 100")
	_expect(is_equal_approx(100.0 - slow, (100.0 - normal) * 0.2), "Delta 0,2x drena 20% da distância")

	print("=================================================================")
	if failures == 0:
		print("D048_ROLLING_HP_LEGACY_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)
