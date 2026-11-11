extends SceneTree
## Folha de contato 2x2 dos 4 conceitos de HUD sem bloco.
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . \
##     --script res://tests/ui/make_attack_hud_sheet.gd

const SRC_DIR := "res://docs/referencias/ui/attack_hud_lab"
const OUT := "res://docs/referencias/ui/attack_hud_lab/contact_sheet.png"
const NAMES := [
	"A_mira.png",
	"B_selo.png",
	"C_glifo.png",
	"D_fita.png",
]
const CELL := Vector2i(960, 540)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sheet := Image.create(CELL.x * 2, CELL.y * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.055, 0.063, 0.078))
	for i in NAMES.size():
		var path := ProjectSettings.globalize_path(SRC_DIR.path_join(NAMES[i]))
		var img := Image.load_from_file(path)
		if img == null:
			push_error("missing %s" % path)
			quit(1)
			return
		img.convert(Image.FORMAT_RGBA8)
		img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
		var dst := Vector2i((i % 2) * CELL.x, (i / 2) * CELL.y)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), dst)
	var out_path := ProjectSettings.globalize_path(OUT)
	sheet.save_png(out_path)
	print("saved %s" % out_path)
	quit(0)
