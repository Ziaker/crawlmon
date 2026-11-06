class_name BiomeVisuals
extends RefCounted
## Per-biome fog and ambient palette (D-358).
##
## The sheet art is 24 px grayscale; these tints are the only colour the map
## receives. The fog is the unexplored overlay; the ambient is the visible map
## tint (CanvasModulate). Keep the fog dark enough to hide the layout and the
## ambient light enough to read the floor and wall faces.

const DEFAULT_BIOME := "temporal_tower"

const AMBIENT := {
	"temporal_tower": Color("a3b9c5"),
	"temporal_spire": Color("aab3c2"),
	"4th_station_pass": Color("b8d6a6"),
	"7th_station_pass": Color("a8d4df"),
	"barren_valley": Color("d6c2a4"),
	"dark_ice_mountain": Color("b4c8db"),
	"dark_ice_mountain_peak": Color("bcd0e2"),
	"dark_wasteland": Color("c4b6a4"),
	"deep_boulder_quarry": Color("d6a9b8"),
	"deep_limestone_cavern": Color("d8c99a"),
	"icicle_forest": Color("b8dce3"),
	"limestone_cavern": Color("d8c99a"),
	"murky_forest": Color("c3a8d6"),
	"spacial_cliffs": Color("c6c9d1"),
	"vast_ice_mountain": Color("aecbe3"),
	"vast_ice_mountain_peak": Color("b6d2e8"),
}

## color, density, warp, drift. Ice/cavern fog is denser and slower; forest
## fog drifts more; desert fog is thinner and dustier.
const FOG := {
	"temporal_tower": {"color": Color(0.030, 0.043, 0.060), "density": 0.88, "warp": 0.045, "drift": 0.0035},
	"temporal_spire": {"color": Color(0.045, 0.050, 0.065), "density": 0.88, "warp": 0.045, "drift": 0.0030},
	"4th_station_pass": {"color": Color(0.025, 0.060, 0.025), "density": 0.82, "warp": 0.055, "drift": 0.0045},
	"7th_station_pass": {"color": Color(0.030, 0.065, 0.075), "density": 0.86, "warp": 0.050, "drift": 0.0040},
	"barren_valley": {"color": Color(0.080, 0.060, 0.035), "density": 0.84, "warp": 0.060, "drift": 0.0050},
	"dark_ice_mountain": {"color": Color(0.030, 0.050, 0.080), "density": 0.90, "warp": 0.040, "drift": 0.0030},
	"dark_ice_mountain_peak": {"color": Color(0.035, 0.055, 0.090), "density": 0.90, "warp": 0.040, "drift": 0.0030},
	"dark_wasteland": {"color": Color(0.060, 0.045, 0.035), "density": 0.88, "warp": 0.050, "drift": 0.0040},
	"deep_boulder_quarry": {"color": Color(0.080, 0.035, 0.050), "density": 0.88, "warp": 0.050, "drift": 0.0035},
	"deep_limestone_cavern": {"color": Color(0.080, 0.065, 0.030), "density": 0.88, "warp": 0.050, "drift": 0.0035},
	"icicle_forest": {"color": Color(0.030, 0.065, 0.075), "density": 0.88, "warp": 0.050, "drift": 0.0040},
	"limestone_cavern": {"color": Color(0.085, 0.075, 0.035), "density": 0.88, "warp": 0.050, "drift": 0.0035},
	"murky_forest": {"color": Color(0.050, 0.030, 0.070), "density": 0.90, "warp": 0.055, "drift": 0.0045},
	"spacial_cliffs": {"color": Color(0.050, 0.055, 0.065), "density": 0.88, "warp": 0.045, "drift": 0.0030},
	"vast_ice_mountain": {"color": Color(0.030, 0.050, 0.085), "density": 0.90, "warp": 0.040, "drift": 0.0030},
	"vast_ice_mountain_peak": {"color": Color(0.035, 0.060, 0.095), "density": 0.90, "warp": 0.040, "drift": 0.0030},
}


static func ambient(biome: String) -> Color:
	return AMBIENT.get(biome, AMBIENT[DEFAULT_BIOME])


static func fog(biome: String) -> Dictionary:
	return FOG.get(biome, FOG[DEFAULT_BIOME])
