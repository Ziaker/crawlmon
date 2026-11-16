class_name PreGameStage3D
extends Control
## 1:1 live 3D Pre-Game stage (D-1207 / D-1208).
##
## Renders the selected protagonist GLB inside a transparent full-rect SubViewport and
## reproduces renderStage()'s WebGL placement from prototypes/pre_game_hud_s18_validacao.html:
## FOV 0.60 rad, camera at (0, 0, 5.2), feet on the turntable pedestal ring, idle bob and
## manual turntable yaw. Also mirrors the AABB Calibration Rig overlay (dashed lime box plus
## #080e18 badge). English only (D-413 / D-1085); static typing throughout (D-1079).

const PreGameCatalog = preload("res://scripts/ui/pre_game/pre_game_catalog.gd")
const PreGameDraw = preload("res://scripts/ui/pre_game/pre_game_draw.gd")
const PreGameBackdrop = preload("res://scripts/ui/pre_game/pre_game_backdrop.gd")
const CharacterModelLoader = preload("res://scripts/combat/character_model_loader.gd")

# --- HTML WebGL parity ---------------------------------------------------------

const FOV_RAD: float = 0.60
const CAM_DIST: float = 5.2
const CAM_NEAR: float = 0.1
const CAM_FAR: float = 40.0
const HEIGHT_FILL: float = 0.95
const WIDTH_FILL: float = 1.45
const RING_FOOT_LIFT: float = 0.12
const MIN_BOX: float = 0.01

const AMBIENT_COLOR := Color(0.92, 0.95, 0.98)
const AMBIENT_ENERGY: float = 0.72
const KEY_COLOR := Color(1.0, 0.98, 0.93)
const KEY_ENERGY: float = 1.42
const FILL_COLOR := Color(0.55, 0.90, 0.98)
const FILL_ENERGY: float = 0.38

const STYLE_SHADER := preload("res://shaders/overworld_model_style.gdshader")
const IDLE_CLIPS: Array[String] = ["battle_idle", "idle"]


## Dashed lime AABB box and #080e18 label drawn above the SubViewport, matching the HTML
## AABB Calibration Rig. The stage injects the projected rect, the label and the font, so
## this Control stays a pure renderer.
class RigOverlay extends Control:
	const DASH: float = 5.0
	const GAP: float = 4.0
	const LINE_WIDTH: float = 1.5
	const BADGE_SIZE := Vector2(128.0, 14.0)
	const BADGE_LIFT: float = 15.0
	const FONT_SIZE: int = 10

	var show_box: bool = false
	var show_label: bool = false
	var projected: Rect2 = Rect2()
	var label_text: String = ""
	var font: Font = null
	var line_color: Color = Color("d6fa66")
	var badge_color: Color = Color("080e18")

	func _draw() -> void:
		if projected.size.x <= 0.5 or projected.size.y <= 0.5:
			return
		if show_box:
			_draw_dashed_box()
		if show_label:
			_draw_badge()

	func _draw_dashed_box() -> void:
		var x0: float = projected.position.x
		var y0: float = projected.position.y
		var x1: float = projected.end.x
		var y1: float = projected.end.y
		var period: float = DASH + GAP
		var x: float = x0
		while x < x1:
			var xe: float = minf(x + DASH, x1)
			draw_line(Vector2(x, y0), Vector2(xe, y0), line_color, LINE_WIDTH, true)
			draw_line(Vector2(x, y1), Vector2(xe, y1), line_color, LINE_WIDTH, true)
			x += period
		var y: float = y0
		while y < y1:
			var ye: float = minf(y + DASH, y1)
			draw_line(Vector2(x0, y), Vector2(x0, ye), line_color, LINE_WIDTH, true)
			draw_line(Vector2(x1, y), Vector2(x1, ye), line_color, LINE_WIDTH, true)
			y += period

	func _draw_badge() -> void:
		if font == null or label_text.is_empty():
			return
		var top: float = projected.position.y - BADGE_LIFT
		var badge := Rect2(projected.position.x, top, BADGE_SIZE.x, BADGE_SIZE.y)
		draw_rect(badge, badge_color)
		draw_string(font, Vector2(badge.position.x + 4.0, top + BADGE_SIZE.y - 4.0), label_text,
			HORIZONTAL_ALIGNMENT_LEFT, BADGE_SIZE.x - 8.0, FONT_SIZE, line_color)


var show_rig_overlay: bool = false
var show_badge: bool = false
## Optional PreGameBackdrop: its get_character_stage_metrics() is the single source of
## truth for char_x / ground_y / draw_h / ring and idle bob. Without one, the stage
## evaluates the same metrics on a detached backdrop instance.
var backdrop: PreGameBackdrop = null
var species_index: int = 0
var model_angle: float = 0.28
var frozen: bool = false

var _stage_visible: bool = true
var _built: bool = false
var _viewport_container: SubViewportContainer = null
var _viewport: SubViewport = null
var _world: Node3D = null
var _camera: Camera3D = null
var _scale_pivot: Node3D = null
var _rot_pivot: Node3D = null
var _overlay: RigOverlay = null

var _rigs: Dictionary = {}
var _active_id: String = ""
var _projected_rect: Rect2 = Rect2()
var _label_height_m: float = 0.0
var _prewarm_pending: Array[Dictionary] = []
var _metrics_source: PreGameBackdrop = null
var _applied_frozen: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_stage()
	_built = true
	set_species(species_index)
	_queue_prewarm()


func _exit_tree() -> void:
	if _metrics_source != null and is_instance_valid(_metrics_source):
		_metrics_source.free()
	_metrics_source = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _built:
		queue_layout()


func _process(_delta: float) -> void:
	if not _built or not _stage_visible:
		return
	if frozen != _applied_frozen:
		_apply_freeze()
	_prewarm_step()
	queue_layout()


# --- Public API ----------------------------------------------------------------

func set_species(species_idx: int) -> void:
	species_index = maxi(species_idx, 0)
	if not _built:
		return
	var spec: Dictionary = PreGameCatalog.get_protagonist_by_index(species_index)
	_activate(_species_id(spec), spec)


func set_model_angle(angle: float) -> void:
	model_angle = angle
	if _rot_pivot != null:
		_rot_pivot.rotation.y = model_angle
	if _overlay != null:
		_overlay.queue_redraw()


func set_stage_visible(v: bool) -> void:
	_stage_visible = v
	if _viewport_container != null:
		_viewport_container.visible = v
	if _overlay != null:
		_overlay.visible = v
	set_process(v)
	if v:
		queue_layout()


func set_frozen(v: bool) -> void:
	frozen = v
	_apply_freeze()


func prewarm_species(index: int) -> void:
	if not _built:
		return
	var spec: Dictionary = PreGameCatalog.get_protagonist_by_index(maxi(index, 0))
	_build_rig(_species_id(spec), spec)


func get_projected_rect() -> Rect2:
	return _projected_rect


func get_rig_label_text() -> String:
	var deg: int = (int(round(rad_to_deg(model_angle))) % 360 + 360) % 360
	return "AABB %.2fm • %d°" % [_label_height_m, deg]


# --- Layout (HTML renderStage parity) ------------------------------------------

func queue_layout() -> void:
	if not _built or not _stage_visible:
		return
	sync_layout(character_metrics(_logical_size()))


func character_metrics(view_size: Vector2) -> Dictionary:
	if backdrop != null and is_instance_valid(backdrop):
		return backdrop.get_character_stage_metrics(view_size)
	if _metrics_source == null:
		_metrics_source = PreGameBackdrop.new()
		_metrics_source.current_view = "charselect"
	_metrics_source.species_index = species_index
	return _metrics_source.get_character_stage_metrics(view_size)


func sync_layout(metrics: Dictionary) -> void:
	if not _built or _scale_pivot == null or _rot_pivot == null:
		return
	var view: Vector2 = _logical_size()
	var char_x: float = float(metrics.get("char_x", 0.0))
	var ground_y: float = float(metrics.get("ground_y", 0.0))
	var draw_h: float = float(metrics.get("draw_h", 0.0))
	var ring_ry: float = float(metrics.get("ring_ry", 0.0))
	var idle_bob: float = float(metrics.get("idle_bob", 0.0))

	var half_h: float = CAM_DIST * tan(FOV_RAD * 0.5)
	var half_w: float = half_h * (view.x / maxf(1.0, view.y))
	var target_world_h: float = (draw_h / maxf(1.0, view.y)) * 2.0 * half_h * HEIGHT_FILL

	var rig: Dictionary = _rigs.get(_active_id, {})
	var h: float = maxf(MIN_BOX, float(rig.get("h", 1.0)))
	var w_box: float = maxf(MIN_BOX, float(rig.get("w", 1.0)))
	var d_box: float = maxf(MIN_BOX, float(rig.get("d", 1.0)))

	var norm_scale: float = minf(target_world_h / h,
		(target_world_h * WIDTH_FILL) / maxf(w_box, d_box))
	var world_x: float = ((char_x / maxf(1.0, view.x)) - 0.5) * 2.0 * half_w
	# The HTML canvas Y axis grows down; Camera3D +Y grows up. This flip is what lands the
	# feet exactly on the pedestal ring drawn by PreGameBackdrop.
	var world_base_y: float = (0.5 - ((ground_y - ring_ry * RING_FOOT_LIFT + idle_bob)
		/ maxf(1.0, view.y))) * 2.0 * half_h

	_scale_pivot.position = Vector3(world_x, world_base_y, 0.0)
	_scale_pivot.scale = Vector3.ONE * norm_scale
	_rot_pivot.rotation.y = model_angle

	_update_projected_rect(view, half_w, half_h, norm_scale, world_x, world_base_y)
	_push_overlay_state()


func _update_projected_rect(view: Vector2, half_w: float, half_h: float, norm_scale: float,
		world_x: float, world_base_y: float) -> void:
	var rig: Dictionary = _rigs.get(_active_id, {})
	if rig.is_empty():
		_projected_rect = Rect2()
		return
	var w_box: float = maxf(MIN_BOX, float(rig.get("w", 1.0)))
	var d_box: float = maxf(MIN_BOX, float(rig.get("d", 1.0)))
	var h_box: float = maxf(MIN_BOX, float(rig.get("h", 1.0)))
	var span_world: float = (w_box * absf(cos(model_angle)) + d_box * absf(sin(model_angle))) * norm_scale
	var height_world: float = h_box * norm_scale
	var full_w: float = maxf(0.0001, 2.0 * half_w)
	var full_h: float = maxf(0.0001, 2.0 * half_h)
	var width_px: float = (span_world / full_w) * view.x
	var height_px: float = (height_world / full_h) * view.y
	var center_px: float = ((world_x / full_w) + 0.5) * view.x
	var bottom_px: float = (0.5 - (world_base_y / full_h)) * view.y
	var next := Rect2(center_px - width_px * 0.5, bottom_px - height_px, width_px, height_px)
	if next.is_equal_approx(_projected_rect):
		return
	_projected_rect = next
	if _overlay != null:
		_overlay.queue_redraw()


func _push_overlay_state() -> void:
	if _overlay == null:
		return
	_overlay.show_box = show_rig_overlay
	_overlay.show_label = show_rig_overlay and show_badge
	_overlay.projected = _projected_rect
	_overlay.label_text = get_rig_label_text()
	_overlay.font = PreGameDraw.mono_font() if _overlay.show_label else null
	_overlay.visible = _stage_visible
	_overlay.queue_redraw()


# --- Stage build ---------------------------------------------------------------

func _build_stage() -> void:
	_viewport_container = SubViewportContainer.new()
	_viewport_container.name = "StageViewportContainer"
	_viewport_container.stretch = true
	_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_viewport_container)
	_apply_game_filter(_viewport_container)

	_viewport = SubViewport.new()
	_viewport.name = "StageViewport"
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport_container.add_child(_viewport)

	_world = Node3D.new()
	_world.name = "StageWorld"
	_viewport.add_child(_world)
	_world.add_child(_build_environment())
	_world.add_child(_build_key_light())
	_world.add_child(_build_fill_light())

	_scale_pivot = Node3D.new()
	_scale_pivot.name = "StageScalePivot"
	_world.add_child(_scale_pivot)

	_rot_pivot = Node3D.new()
	_rot_pivot.name = "StageRotPivot"
	_scale_pivot.add_child(_rot_pivot)

	_camera = Camera3D.new()
	_camera.name = "StageCamera"
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.fov = rad_to_deg(FOV_RAD)
	_camera.near = CAM_NEAR
	_camera.far = CAM_FAR
	_camera.position = Vector3(0.0, 0.0, CAM_DIST)
	_world.add_child(_camera)
	_camera.look_at(Vector3.ZERO, Vector3.UP)
	_camera.current = true

	_overlay = RigOverlay.new()
	_overlay.name = "StageRigOverlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)


## D-1226: the game's TOON style (model_3d_view STYLES["toon"], D-1028/D-1076):
## linear filter, 12 levels, 3 light bands at 0.75, dark silhouette. Creator reversed
## the pixel choice ("é pra ser o toon").
func _apply_game_filter(container: SubViewportContainer) -> void:
	container.stretch_shrink = 1
	container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := ShaderMaterial.new()
	mat.shader = STYLE_SHADER
	mat.set_shader_parameter("color_levels", 12)
	mat.set_shader_parameter("saturation", 1.08)
	mat.set_shader_parameter("contrast", 1.04)
	mat.set_shader_parameter("toon_bands", 3)
	mat.set_shader_parameter("toon_strength", 0.75)
	mat.set_shader_parameter("outline_darkness", 0.55)
	mat.set_shader_parameter("outline_width", 1.0)
	container.material = mat


func _build_environment() -> WorldEnvironment:
	var node := WorldEnvironment.new()
	node.name = "StageEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = AMBIENT_COLOR
	environment.ambient_light_energy = AMBIENT_ENERGY
	node.environment = environment
	return node


func _build_key_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "StageKeyLight"
	light.rotation_degrees = Vector3(-47.0, 35.0, 0.0)
	light.light_energy = KEY_ENERGY
	light.light_color = KEY_COLOR
	light.shadow_enabled = false
	return light


func _build_fill_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "StageFillLight"
	light.rotation_degrees = Vector3(-16.0, -142.0, 0.0)
	light.light_energy = FILL_ENERGY
	light.light_color = FILL_COLOR
	light.shadow_enabled = false
	return light


# --- Model rigs ----------------------------------------------------------------

func _activate(species_id: String, spec: Dictionary) -> void:
	_label_height_m = float(spec.get("height", 0.0))
	_active_id = species_id
	_build_rig(species_id, spec)
	_show_only(species_id)
	_rot_pivot.rotation.y = model_angle
	queue_layout()


func _show_only(species_id: String) -> void:
	for key in _rigs.keys():
		var entry: Dictionary = _rigs[key]
		var node: Node3D = entry.get("node")
		if node != null and is_instance_valid(node):
			node.visible = str(key) == species_id


func _build_rig(species_id: String, spec: Dictionary) -> Dictionary:
	if species_id.is_empty() or spec.is_empty():
		return {}
	if _rigs.has(species_id):
		return _rigs[species_id]
	var glb_path: String = str(spec.get("glb_path", ""))
	if not glb_path.ends_with(".glb") or not ResourceLoader.exists(glb_path):
		push_warning("PreGameStage3D: no .glb for species '%s' (%s)" % [species_id, glb_path])
		return {}
	var combatant := PreGameCatalog.build_combatant_for_3d(spec)
	if combatant == null:
		return {}
	var model := CharacterModelLoader.create_character_model(combatant)
	if model == null:
		return {}

	var bounds: AABB = CharacterModelLoader.calculate_model_bounds(model)
	var box: Vector3 = bounds.size
	if box.y < MIN_BOX or maxf(box.x, box.z) < MIN_BOX:
		push_warning("PreGameStage3D: degenerate bounds for '%s' %s" % [species_id, box])
	var cx: float = bounds.position.x + box.x * 0.5
	var cz: float = bounds.position.z + box.z * 0.5
	# Center the footprint on the pivot and drop the lowest vertex onto y=0, so the
	# turntable yaw spins the character around its own feet.
	model.position = Vector3(-cx, -bounds.position.y, -cz)
	model.visible = false
	_strip_combat_outline(model)
	_rot_pivot.add_child(model)

	var anim: AnimationPlayer = CharacterModelLoader.get_anim_player(model)
	_prepare_idle(anim)

	var entry: Dictionary = {
		"node": model,
		"anim": anim,
		"h": maxf(MIN_BOX, box.y),
		"w": maxf(MIN_BOX, box.x),
		"d": maxf(MIN_BOX, box.z),
	}
	_rigs[species_id] = entry
	_freeze_rig(entry)
	return entry


func _prepare_idle(anim: AnimationPlayer) -> void:
	if anim == null:
		return
	for clip in IDLE_CLIPS:
		if not anim.has_animation(clip):
			continue
		var animation := anim.get_animation(clip)
		# D-1084: idle_full DQT idles come from the loader as LOOP_NONE; play once and
		# hold the last frame instead of forcing a loop that restarts every cycle.
		if animation != null and animation.loop_mode != Animation.LOOP_NONE:
			animation.loop_mode = Animation.LOOP_LINEAR
		anim.play(clip)
		return


func _apply_freeze() -> void:
	_applied_frozen = frozen
	for key in _rigs.keys():
		var entry: Dictionary = _rigs[key]
		_freeze_rig(entry)


func _freeze_rig(entry: Dictionary) -> void:
	var anim: AnimationPlayer = entry.get("anim")
	if anim == null:
		return
	anim.speed_scale = 0.0 if frozen else 1.0
	if frozen:
		anim.seek(0.0, true)


func _queue_prewarm() -> void:
	_prewarm_pending.clear()
	for spec: Dictionary in PreGameCatalog.build_protagonist_list():
		var species_id: String = _species_id(spec)
		if species_id.is_empty() or species_id == _active_id or _rigs.has(species_id):
			continue
		_prewarm_pending.append(spec)


func _prewarm_step() -> void:
	if _prewarm_pending.is_empty():
		return
	var spec: Dictionary = _prewarm_pending.pop_front()
	var entry := _build_rig(_species_id(spec), spec)
	var node: Node3D = entry.get("node")
	if node != null and is_instance_valid(node):
		node.visible = _species_id(spec) == _active_id


# --- Helpers -------------------------------------------------------------------

func _species_id(spec: Dictionary) -> String:
	if spec.is_empty():
		return ""
	var species_id: String = str(spec.get("id", spec.get("species_id", ""))).to_lower()
	if not species_id.is_empty():
		return species_id
	var path: String = str(spec.get("glb_path", ""))
	return path.get_file().get_basename().to_lower()


func _logical_size() -> Vector2:
	var rect: Vector2 = size
	if rect.x <= 1.0 or rect.y <= 1.0:
		var vp: Viewport = get_viewport()
		if vp != null:
			rect = vp.get_visible_rect().size
	return Vector2(maxf(rect.x, 1.0), maxf(rect.y, 1.0))


static func _strip_combat_outline(root: Node) -> void:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not (node is MeshInstance3D):
			continue
		var mi := node as MeshInstance3D
		if mi.material_override != null and mi.material_override.next_pass != null:
			var dup_ovr := mi.material_override.duplicate() as Material
			dup_ovr.next_pass = null
			mi.material_override = dup_ovr
		var surf_cnt := mi.get_surface_override_material_count()
		for s_idx in surf_cnt:
			var sm := mi.get_surface_override_material(s_idx)
			if sm != null:
				if sm.next_pass != null:
					var dup_sm := sm.duplicate() as Material
					dup_sm.next_pass = null
					mi.set_surface_override_material(s_idx, dup_sm)
			elif mi.mesh != null and s_idx < mi.mesh.get_surface_count():
				var base_m := mi.mesh.surface_get_material(s_idx)
				if base_m != null and base_m.next_pass != null:
					var dup_base := base_m.duplicate() as Material
					dup_base.next_pass = null
					mi.set_surface_override_material(s_idx, dup_base)
