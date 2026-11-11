extends SceneTree
## D-1134: captura as 4 direções da badge [Z] ATTACK no lab 3D real.
## Rodar SEM --headless (precisa desenhar):
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --script res://tests/ui/capture_attack_badges.gd

const LAB := "res://scenes/debug/attack_badge_lab.tscn"
const OUT_DIR := "res://docs/referencias/ui/attack_badge_lab"
const STYLE_FILES := ["A_attack_card", "B_command_strip", "C_smt_uplink", "D_z_pow"]

var _lab: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(LAB) as PackedScene
	_lab = packed.instantiate()
	root.add_child(_lab)
	current_scene = _lab
	await _frames(45)
	for i in 4:
		_lab.call("set_preview_style", i)
		_lab.call("set_preview_state", 0)
		await _frames(36)
		_save("%s.png" % STYLE_FILES[i])
		_lab.call("press_preview")
		await _frames(3)
		_save("%s_press.png" % STYLE_FILES[i])
		await _frames(40)
	# Estados da direção escolhida como exemplo (SMT): recarga e sem alvo.
	_lab.call("set_preview_style", 2)
	_lab.call("set_preview_state", 1)
	await _frames(10)
	_save("C_smt_uplink_recharging.png")
	_lab.call("set_preview_state", 2)
	await _frames(10)
	_save("C_smt_uplink_no_target.png")
	# O mesmo estado na ATTACK CARD para comparar legibilidade.
	_lab.call("set_preview_style", 0)
	await _frames(10)
	_save("A_attack_card_no_target.png")
	_lab.call("set_preview_state", 1)
	await _frames(10)
	_save("A_attack_card_recharging.png")
	# D-235: outro alvo (Gible) e o lado espelhado, com retículo e tail.
	_lab.call("set_preview_state", 0)
	_lab.call("set_preview_style", 2)
	_lab.call("set_preview_target", 1)
	await _frames(36)
	_save("C_smt_uplink_gible.png")
	_lab.call("set_preview_mirror", true)
	await _frames(36)
	_save("C_smt_uplink_mirror_gible.png")
	_lab.call("set_preview_style", 3)
	await _frames(36)
	_save("D_z_pow_mirror_gible.png")
	quit(0)


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var path := abs_dir.path_join(file_name)
	img.save_png(path)
	print("saved %s" % path)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
