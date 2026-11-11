extends SceneTree
## D-1104: the interrupted AttackTag becomes 9 texture shards + the centered "interrupted" echo.
## Roda com: godot --headless --path . --script res://tests/ui/test_d1104_attack_tag_shatter.gd

const Shatter = preload("res://scripts/ui/attack_tag_shatter.gd")


func _init() -> void:
	print("\n=================================================================")
	print("   CRAWLMON — TESTES DO CARTÃO DESTRUÍDO (D-1104)")
	print("=================================================================")

	var host := Control.new()
	host.size = Vector2(1280, 720)
	root.add_child(host)

	var img := Image.create(150, 38, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	var shatter = Shatter.spawn(host, Vector2(100, 200), Vector2(150, 38), tex)
	assert(shatter != null, "O shatter foi criado")
	assert(host.get_child_count() == 1, "O shatter foi adicionado ao HUD")

	var shards := 0
	var echo: Control = null
	for child in shatter.get_children():
		if child is Polygon2D:
			shards += 1
		elif child is Control and child.name == "InterruptedEcho":
			echo = child
	assert(shards == 9, "9 estilhaços (encontrado %d)" % shards)
	assert(echo != null, "O eco existe")
	assert(String(echo.get("text")) == "INTERRUPTED", "O eco é exatamente 'INTERRUPTED'")
	assert(is_equal_approx(float(echo.get("letter_spacing")), 4.0), "O eco tem espaçamento de 4 px")
	assert(is_equal_approx(float(echo.get("flash")), 1.0), "O eco começa com o flash branco")
	var expected := Vector2(100 + 150 * 0.5, 200 + 38 * 0.5)
	# The echo starts at scale 1.2; the visual center is the pivot transformed to the card center.
	var echo_center: Vector2 = echo.get_global_transform() * echo.pivot_offset
	assert(echo_center.is_equal_approx(expected), "O eco está centralizado no cartão (%.1f, %.1f)" % [echo_center.x, echo_center.y])
	print("  [PASS] 9 estilhaços e eco 'INTERRUPTED' centralizado no cartão.")

	# 0,55 s: os estilhaços e o eco terminam juntos e o nó é liberado.
	shatter._process(0.56)
	assert(shatter.is_queued_for_deletion(), "O shatter termina em 0,55 s")
	print("  [PASS] Duração de 0,55 s e liberação do nó.")

	print("\n  TODOS OS TESTES DO CARTÃO DESTRUÍDO PASSARAM.\n")
	quit()
