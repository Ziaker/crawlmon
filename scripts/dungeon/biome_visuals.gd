class_name BiomeVisuals
extends RefCounted
## Per-biome fog and ambient palette (D-358, strengthened in D-359).
##
## The sheet art is 24 px grayscale; the ambient is a multiply tint and the fog
## is a dark coloured veil. The colours are deliberately strong: the 16 biomes
## must read as different places at a glance, not as the same grey map.

const DEFAULT_BIOME := "temporal_tower"

const AMBIENT := {
	"temporal_tower": Color("c8dce8"),        # steel blue, raised for no player light
	"temporal_spire": Color("a0b0c8"),        # slate blue, raised for no player light
	"4th_station_pass": Color("90e090"),      # green
	"7th_station_pass": Color("90e8ff"),      # cyan ice
	"barren_valley": Color("e0c080"),         # sand
	"dark_ice_mountain": Color("80a8e0"),     # deep blue
	"dark_ice_mountain_peak": Color("9090f0"),# indigo
	"dark_wasteland": Color("b09070"),        # smoky brown
	"deep_boulder_quarry": Color("f080a0"),   # rose
	"deep_limestone_cavern": Color("f0a040"), # orange amber
	"icicle_forest": Color("80e0d0"),         # teal
	"limestone_cavern": Color("f0e080"),      # pale yellow
	"murky_forest": Color("c080e0"),          # violet
	"spacial_cliffs": Color("c0c0c8"),        # neutral grey
	"vast_ice_mountain": Color("90b8e8"),     # steel ice
	"vast_ice_mountain_peak": Color("b8b8f0"),# lavender ice
}

## color, density, warp, drift. The fog is darker than the ambient but strongly
## tinted; ice is dense/slow, forest drifts, desert is thinner.
const FOG := {
	"temporal_tower": {"color": Color(0.050, 0.080, 0.130), "density": 0.88, "warp": 0.045, "drift": 0.0035},
	"temporal_spire": {"color": Color(0.060, 0.090, 0.160), "density": 0.88, "warp": 0.045, "drift": 0.0030},
	"4th_station_pass": {"color": Color(0.040, 0.180, 0.060), "density": 0.82, "warp": 0.055, "drift": 0.0045},
	"7th_station_pass": {"color": Color(0.040, 0.160, 0.220), "density": 0.86, "warp": 0.050, "drift": 0.0040},
	"barren_valley": {"color": Color(0.220, 0.140, 0.050), "density": 0.84, "warp": 0.060, "drift": 0.0050},
	"dark_ice_mountain": {"color": Color(0.040, 0.080, 0.220), "density": 0.90, "warp": 0.040, "drift": 0.0030},
	"dark_ice_mountain_peak": {"color": Color(0.070, 0.060, 0.240), "density": 0.90, "warp": 0.040, "drift": 0.0030},
	"dark_wasteland": {"color": Color(0.160, 0.100, 0.060), "density": 0.88, "warp": 0.050, "drift": 0.0040},
	"deep_boulder_quarry": {"color": Color(0.220, 0.050, 0.120), "density": 0.88, "warp": 0.050, "drift": 0.0035},
	"deep_limestone_cavern": {"color": Color(0.240, 0.120, 0.030), "density": 0.88, "warp": 0.050, "drift": 0.0035},
	"icicle_forest": {"color": Color(0.030, 0.160, 0.140), "density": 0.88, "warp": 0.050, "drift": 0.0040},
	"limestone_cavern": {"color": Color(0.240, 0.200, 0.050), "density": 0.88, "warp": 0.050, "drift": 0.0035},
	"murky_forest": {"color": Color(0.140, 0.040, 0.220), "density": 0.90, "warp": 0.055, "drift": 0.0045},
	"spacial_cliffs": {"color": Color(0.120, 0.130, 0.170), "density": 0.88, "warp": 0.045, "drift": 0.0030},
	"vast_ice_mountain": {"color": Color(0.050, 0.100, 0.260), "density": 0.90, "warp": 0.040, "drift": 0.0030},
	"vast_ice_mountain_peak": {"color": Color(0.090, 0.090, 0.280), "density": 0.90, "warp": 0.040, "drift": 0.0030},
}


static func ambient(biome: String) -> Color:
	return AMBIENT.get(biome, AMBIENT[DEFAULT_BIOME])


static func fog(biome: String) -> Dictionary:
	return FOG.get(biome, FOG[DEFAULT_BIOME])
