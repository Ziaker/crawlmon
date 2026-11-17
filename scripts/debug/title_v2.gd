extends Control
## Title v2 debug scene (D-1265): the same world + 2D layer the pre-game uses.
##   Godot --path . scenes/debug/title_v2.tscn -- --shot=out.png --at=3.0 [--leader=N] [--mirror]
## For the real flow use the pre-game itself (v2 is the default; --title=v1 restores the old one).

const PreGameTitleWorld = preload("res://scripts/ui/pre_game/pre_game_title_world.gd")
const TitleV2Ui = preload("res://scripts/debug/title_v2_ui.gd")

var _shot := ""
var _at := 3.0
var _t := 0.0
var _frames := 0


func _arg(prefix: String) -> String:
	var all := OS.get_cmdline_args()
	all.append_array(OS.get_cmdline_user_args())
	for a in all:
		if str(a).begins_with(prefix):
			return str(a).substr(prefix.length())
	return ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_shot = _arg("--shot=")
	if not _arg("--at=").is_empty():
		_at = float(_arg("--at="))
	var world := PreGameTitleWorld.new()
	world.set_anchors_preset(Control.PRESET_FULL_RECT)
	world.mirror = OS.get_cmdline_user_args().has("--mirror")
	add_child(world)
	world.set_leader(int(_arg("--leader=")) if not _arg("--leader=").is_empty() else 0)
	var ui := TitleV2Ui.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui)


func _process(delta: float) -> void:
	_t += delta
	if _shot != "" and _t >= _at:
		_frames += 1
		if _frames == 4:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(_shot)
			print("[title_v2] shot=", _shot, " size=", get_viewport().get_visible_rect().size)
			get_tree().quit()
