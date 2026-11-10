extends SceneTree
## Contrato da Fase 3 (D-1079): ícone opcional por Move, com fallback para o
## ícone de tipo/alcance atual. Nenhum visual é alterado quando não há icon.svg.

const MoveIconsScript = preload("res://scripts/ui/move_icons.gd")

var failures := 0


func _init() -> void:
	var media := MoveCatalog.get_move(&"media")
	ok(media != null, "Media existe no catálogo")
	if media != null:
		ok(media.icon_color.a > 0.0, "Media define cor de fundo própria")
		ok(media.icon_color.g > media.icon_color.r and media.icon_color.g > media.icon_color.b, "cor de fundo do Media é verde")
	var tackle := MoveCatalog.get_move(&"tackle")
	ok(tackle == null or tackle.icon_color.a == 0.0, "Move sem cor própria usa o fallback")
	var icon: Texture2D = MoveIconsScript.for_move(&"media")
	ok(icon != null, "Media tem icon.svg")
	if icon != null:
		ok(icon.get_width() > 0 and icon.get_height() > 0, "ícone do Media tem dimensões válidas")
	ok(MoveIconsScript.for_move(&"media") == icon, "resolvedor cacheia o mesmo ícone")
	ok(MoveIconsScript.for_move(&"tackle") == null, "Move sem icon.svg cai no fallback")
	ok(MoveIconsScript.for_move(&"nao_existe") == null, "id desconhecido cai no fallback")
	MoveIconsScript.clear_cache()
	ok(MoveIconsScript.for_move(&"media") != null, "cache limpo recarrega o ícone")

	if failures == 0:
		print("MOVE_ICONS_TEST_PASS")
		quit(0)
	else:
		print("MOVE_ICONS_TEST_FAIL (%d)" % failures)
		quit(1)


func ok(condition: bool, message: String) -> void:
	if condition:
		print("  [PASS] ", message)
	else:
		failures += 1
		print("  [FAIL] ", message)
