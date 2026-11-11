extends SceneTree
## D-1077: bakes the procedural, seamless water textures of the projectile library (Tidal Surge).
## godot --headless --path . --script res://tools/bake_water_textures.gd
##
## Output: res://assets/vfx/water/water_flow.png (256x256, tiles in both axes)
##   R = caustic web: bright lines on the borders of big cells (the light net on moving water)
##   G = soft billowy noise (flow distortion, erosion/dissolve mask, mist body)
##   B = foam breakup: small, hard cells (the broken lip of a crest)

const SIZE := 256
const OUT_DIR := "res://assets/vfx/water"


func _noise(type: int, freq: float, seed: int, octaves: int = 1) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = type
	n.seed = seed
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_FBM if octaves > 1 else FastNoiseLite.FRACTAL_NONE
	n.fractal_octaves = octaves
	return n


func _stretch(img: Image) -> Image:
	# Normalise to the full 0..1 range so the shader thresholds mean the same thing after every bake.
	var lo := 1.0
	var hi := 0.0
	for y in SIZE:
		for x in SIZE:
			var v := img.get_pixel(x, y).r
			lo = minf(lo, v)
			hi = maxf(hi, v)
	var span := maxf(hi - lo, 0.001)
	for y in SIZE:
		for x in SIZE:
			var v := (img.get_pixel(x, y).r - lo) / span
			img.set_pixel(x, y, Color(v, v, v))
	return img


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var web := _noise(FastNoiseLite.TYPE_CELLULAR, 0.022, 1021)
	web.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	web.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	web.cellular_jitter = 1.0
	var soft := _noise(FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.012, 77, 4)
	var foam := _noise(FastNoiseLite.TYPE_CELLULAR, 0.055, 404)
	foam.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	foam.cellular_jitter = 1.0
	var chans: Array = []
	for n in [web, soft, foam]:
		var img := (n as FastNoiseLite).get_seamless_image(SIZE, SIZE, false, false, 0.25)
		img.convert(Image.FORMAT_RGBA8)
		chans.append(_stretch(img))
	var out := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			# The web is dark on the cell borders: invert it so the borders are the bright caustic lines.
			var r := 1.0 - (chans[0] as Image).get_pixel(x, y).r
			var g := (chans[1] as Image).get_pixel(x, y).r
			var b := (chans[2] as Image).get_pixel(x, y).r
			out.set_pixel(x, y, Color(r, g, b))
	var path := OUT_DIR + "/water_flow.png"
	var err := out.save_png(ProjectSettings.globalize_path(path))
	print("[bake_water_textures] %s err=%d" % [path, err])
	quit(0 if err == OK else 1)
