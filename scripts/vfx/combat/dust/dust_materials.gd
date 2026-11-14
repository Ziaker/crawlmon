class_name DustMaterials
extends RefCounted
## Materials for the option-A Dig / Sand Attack dust (D-1196). Each factory loads its shader from
## res://shaders/dust_*.gdshader and applies the two values the creator fixed in D-1196:
## u_base_opacity = 0.85 and u_edge_feather = 0.22.
## Palettes are the HTML's (PALETTE_EARTH_DIG / PALETTE_SILICA_SAND); nothing is invented here.
## No GPUParticles, no decals and no sub-emitters.

const SHADER_CROWN: Shader = preload("res://shaders/dust_crown_shell.gdshader")
const SHADER_CRATER: Shader = preload("res://shaders/dust_crater.gdshader")
const SHADER_CLOUD: Shader = preload("res://shaders/dust_cloud.gdshader")
const SHADER_VEIL: Shader = preload("res://shaders/dust_veil.gdshader")

const BASE_OPACITY := 0.85
const EDGE_FEATHER := 0.22

const PALETTE_EARTH_DIG := {
	"lit": Color("#e6d2b5"),
	"mid": Color("#b39268"),
	"shadow": Color("#634b30"),
	"veil_light": Color("#e3cfa8"),
	"veil_dark": Color("#7d613e"),
}

const PALETTE_SILICA_SAND := {
	"lit": Color("#fef08a"),
	"mid": Color("#dfb14b"),
	"shadow": Color("#784c1e"),
	"veil_light": Color("#fde68a"),
	"veil_dark": Color("#926224"),
}


static func crown_shell(core: Color, primary: Color, secondary: Color, lobes: float = 7.0, gap_openness: float = 0.44) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_CROWN
	mat.set_shader_parameter("u_core", core)
	mat.set_shader_parameter("u_primary", primary)
	mat.set_shader_parameter("u_secondary", secondary)
	mat.set_shader_parameter("u_lobes", lobes)
	mat.set_shader_parameter("u_gap_openness", gap_openness)
	mat.set_shader_parameter("u_base_opacity", BASE_OPACITY)
	mat.set_shader_parameter("u_edge_feather", EDGE_FEATHER)
	return mat


static func crater() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_CRATER
	mat.set_shader_parameter("u_base_opacity", BASE_OPACITY)
	mat.set_shader_parameter("u_edge_feather", EDGE_FEATHER)
	return mat


static func cloud(seed_value: float, palette: Dictionary) -> ShaderMaterial:
	var lit: Color = palette["lit"]
	var mid: Color = palette["mid"]
	var shadow: Color = palette["shadow"]
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_CLOUD
	mat.set_shader_parameter("u_seed", seed_value)
	mat.set_shader_parameter("u_color_lit", lit)
	mat.set_shader_parameter("u_color_mid", mid)
	mat.set_shader_parameter("u_color_shadow", shadow)
	mat.set_shader_parameter("u_base_opacity", BASE_OPACITY)
	mat.set_shader_parameter("u_edge_feather", EDGE_FEATHER)
	return mat


static func veil(palette: Dictionary) -> ShaderMaterial:
	var light: Color = palette["veil_light"]
	var dark: Color = palette["veil_dark"]
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_VEIL
	mat.set_shader_parameter("u_color_light", light)
	mat.set_shader_parameter("u_color_dark", dark)
	mat.set_shader_parameter("u_base_opacity", BASE_OPACITY)
	mat.set_shader_parameter("u_edge_feather", EDGE_FEATHER)
	return mat
