class_name BiomeVisuals
extends RefCounted
## Per-biome fog and ambient palette (D-358, strengthened in D-359/D-360).
##
## The sheet art is 24 px grayscale; the ambient is a multiply tint and the fog
## is a dark coloured veil. The fog has two side colours and its own noise
## type/scale per biome, so the left and right edges do not share the same
## pattern or colour.

const DEFAULT_BIOME := "temporal_tower"

const AMBIENT := {
	"temporal_tower": Color("c8dce8"),
	"temporal_spire": Color("a0b0c8"),
	"4th_station_pass": Color("90e090"),
	"7th_station_pass": Color("90e8ff"),
	"barren_valley": Color("e0c080"),
	"dark_ice_mountain": Color("80a8e0"),
	"dark_ice_mountain_peak": Color("9090f0"),
	"dark_wasteland": Color("b09070"),
	"deep_boulder_quarry": Color("f080a0"),
	"deep_limestone_cavern": Color("f0a040"),
	"icicle_forest": Color("80e0d0"),
	"limestone_cavern": Color("f0e080"),
	"murky_forest": Color("c080e0"),
	"spacial_cliffs": Color("c0c0c8"),
	"vast_ice_mountain": Color("90b8e8"),
	"vast_ice_mountain_peak": Color("b8b8f0"),
}

## Left colour, right colour, side_mix, density, warp, drift, noise_type,
## noise_frequency, noise_octaves, noise_seed, noise_scale, noise_scale_b.
## side_mix 0 = flat, 1 = full left/right gradient.
const FOG := {
	"temporal_tower": {
		"color": Color(0.035, 0.060, 0.110), "color_b": Color(0.100, 0.160, 0.260),
		"side_mix": 0.85, "density": 0.88, "warp": 0.045, "drift": 0.0035,
		"noise_type": FastNoiseLite.TYPE_VALUE_CUBIC, "noise_frequency": 0.040,
		"noise_octaves": 3, "noise_seed": 155, "noise_scale": 2.0, "noise_scale_b": 4.0,
	},
	"temporal_spire": {
		"color": Color(0.030, 0.050, 0.100), "color_b": Color(0.090, 0.140, 0.250),
		"side_mix": 0.85, "density": 0.88, "warp": 0.045, "drift": 0.0030,
		"noise_type": FastNoiseLite.TYPE_VALUE_CUBIC, "noise_frequency": 0.045,
		"noise_octaves": 3, "noise_seed": 144, "noise_scale": 2.2, "noise_scale_b": 4.4,
	},
	"4th_station_pass": {
		"color": Color(0.025, 0.140, 0.040), "color_b": Color(0.100, 0.300, 0.070),
		"side_mix": 0.90, "density": 0.82, "warp": 0.055, "drift": 0.0045,
		"noise_type": FastNoiseLite.TYPE_SIMPLEX_SMOOTH, "noise_frequency": 0.045,
		"noise_octaves": 3, "noise_seed": 11, "noise_scale": 2.2, "noise_scale_b": 4.7,
	},
	"7th_station_pass": {
		"color": Color(0.020, 0.100, 0.170), "color_b": Color(0.090, 0.260, 0.340),
		"side_mix": 0.90, "density": 0.86, "warp": 0.050, "drift": 0.0040,
		"noise_type": FastNoiseLite.TYPE_CELLULAR, "noise_frequency": 0.060,
		"noise_octaves": 2, "noise_seed": 22, "noise_scale": 3.0, "noise_scale_b": 6.0,
	},
	"barren_valley": {
		"color": Color(0.160, 0.090, 0.030), "color_b": Color(0.320, 0.210, 0.070),
		"side_mix": 0.90, "density": 0.84, "warp": 0.060, "drift": 0.0050,
		"noise_type": FastNoiseLite.TYPE_PERLIN, "noise_frequency": 0.035,
		"noise_octaves": 4, "noise_seed": 33, "noise_scale": 1.8, "noise_scale_b": 3.6,
	},
	"dark_ice_mountain": {
		"color": Color(0.020, 0.040, 0.150), "color_b": Color(0.070, 0.150, 0.320),
		"side_mix": 0.90, "density": 0.90, "warp": 0.040, "drift": 0.0030,
		"noise_type": FastNoiseLite.TYPE_CELLULAR, "noise_frequency": 0.070,
		"noise_octaves": 2, "noise_seed": 44, "noise_scale": 3.2, "noise_scale_b": 6.4,
	},
	"dark_ice_mountain_peak": {
		"color": Color(0.040, 0.030, 0.170), "color_b": Color(0.110, 0.090, 0.340),
		"side_mix": 0.90, "density": 0.90, "warp": 0.040, "drift": 0.0030,
		"noise_type": FastNoiseLite.TYPE_CELLULAR, "noise_frequency": 0.080,
		"noise_octaves": 2, "noise_seed": 55, "noise_scale": 3.4, "noise_scale_b": 6.8,
	},
	"dark_wasteland": {
		"color": Color(0.100, 0.055, 0.030), "color_b": Color(0.220, 0.140, 0.070),
		"side_mix": 0.85, "density": 0.88, "warp": 0.050, "drift": 0.0040,
		"noise_type": FastNoiseLite.TYPE_PERLIN, "noise_frequency": 0.050,
		"noise_octaves": 4, "noise_seed": 66, "noise_scale": 2.0, "noise_scale_b": 4.0,
	},
	"deep_boulder_quarry": {
		"color": Color(0.150, 0.025, 0.070), "color_b": Color(0.320, 0.090, 0.170),
		"side_mix": 0.90, "density": 0.88, "warp": 0.050, "drift": 0.0035,
		"noise_type": FastNoiseLite.TYPE_SIMPLEX, "noise_frequency": 0.060,
		"noise_octaves": 3, "noise_seed": 77, "noise_scale": 2.4, "noise_scale_b": 4.8,
	},
	"deep_limestone_cavern": {
		"color": Color(0.180, 0.080, 0.020), "color_b": Color(0.340, 0.200, 0.050),
		"side_mix": 0.90, "density": 0.88, "warp": 0.050, "drift": 0.0035,
		"noise_type": FastNoiseLite.TYPE_VALUE_CUBIC, "noise_frequency": 0.050,
		"noise_octaves": 3, "noise_seed": 88, "noise_scale": 2.6, "noise_scale_b": 5.2,
	},
	"icicle_forest": {
		"color": Color(0.010, 0.100, 0.100), "color_b": Color(0.070, 0.250, 0.230),
		"side_mix": 0.90, "density": 0.88, "warp": 0.050, "drift": 0.0040,
		"noise_type": FastNoiseLite.TYPE_CELLULAR, "noise_frequency": 0.065,
		"noise_octaves": 2, "noise_seed": 99, "noise_scale": 3.0, "noise_scale_b": 6.0,
	},
	"limestone_cavern": {
		"color": Color(0.180, 0.150, 0.030), "color_b": Color(0.340, 0.300, 0.070),
		"side_mix": 0.90, "density": 0.88, "warp": 0.050, "drift": 0.0035,
		"noise_type": FastNoiseLite.TYPE_VALUE_CUBIC, "noise_frequency": 0.045,
		"noise_octaves": 3, "noise_seed": 111, "noise_scale": 2.4, "noise_scale_b": 4.8,
	},
	"murky_forest": {
		"color": Color(0.100, 0.020, 0.160), "color_b": Color(0.240, 0.080, 0.340),
		"side_mix": 0.90, "density": 0.90, "warp": 0.055, "drift": 0.0045,
		"noise_type": FastNoiseLite.TYPE_SIMPLEX_SMOOTH, "noise_frequency": 0.055,
		"noise_octaves": 3, "noise_seed": 122, "noise_scale": 2.8, "noise_scale_b": 5.6,
	},
	"spacial_cliffs": {
		"color": Color(0.080, 0.090, 0.120), "color_b": Color(0.200, 0.220, 0.280),
		"side_mix": 0.85, "density": 0.88, "warp": 0.045, "drift": 0.0030,
		"noise_type": FastNoiseLite.TYPE_PERLIN, "noise_frequency": 0.040,
		"noise_octaves": 3, "noise_seed": 133, "noise_scale": 2.2, "noise_scale_b": 4.4,
	},
	"vast_ice_mountain": {
		"color": Color(0.020, 0.050, 0.170), "color_b": Color(0.090, 0.190, 0.360),
		"side_mix": 0.90, "density": 0.90, "warp": 0.040, "drift": 0.0030,
		"noise_type": FastNoiseLite.TYPE_CELLULAR, "noise_frequency": 0.060,
		"noise_octaves": 2, "noise_seed": 166, "noise_scale": 3.0, "noise_scale_b": 6.0,
	},
	"vast_ice_mountain_peak": {
		"color": Color(0.050, 0.040, 0.190), "color_b": Color(0.150, 0.150, 0.380),
		"side_mix": 0.90, "density": 0.90, "warp": 0.040, "drift": 0.0030,
		"noise_type": FastNoiseLite.TYPE_CELLULAR, "noise_frequency": 0.070,
		"noise_octaves": 2, "noise_seed": 177, "noise_scale": 3.2, "noise_scale_b": 6.4,
	},
}


static func ambient(biome: String) -> Color:
	return AMBIENT.get(biome, AMBIENT[DEFAULT_BIOME])


static func fog(biome: String) -> Dictionary:
	return FOG.get(biome, FOG[DEFAULT_BIOME])
