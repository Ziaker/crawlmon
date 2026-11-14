extends RefCounted
## Fonte única do ícone de personagem nas HUDs (D-1093: ícone estabelecido).
## Abra, Pancham, Gible e Bulbasaur: recorte do rosto na arte Sugimori (mesmos recortes da D-1093).
## Demais: personagens/portraits/<nome>.png (DQT etc.).

const SUGIMORI_DIR := "res://sugimori/por_nome/"
const FALLBACK_DIR := "res://personagens/portraits/"
## Recortes em pixels da arte Sugimori (iguais aos de post_combat_screen.gd / D-1093).
const FACE_CROP := {
	"abra": Rect2(300, 120, 320, 360),
	"pancham": Rect2(300, 40, 680, 760),
	"gible": Rect2(30, 100, 490, 560),
	"bulbasaur": Rect2(23, 31, 604, 604),
}

static var _cache := {}

const ICON_PX := 256
## Fundo ciano-verde claro dos ícones DQT (mesmo degradê vertical da matriz: .avatar.poke-bg).
const BG_STOPS := [
	[0.00, Color("77c7d7")], [0.28, Color("8fcfc7")], [0.48, Color("afd7b7")],
	[0.72, Color("dfe7bf")], [1.00, Color("e7f7b7")],
]


static func _bg_color(t: float) -> Color:
	for i in range(1, BG_STOPS.size()):
		if t <= BG_STOPS[i][0]:
			var a: Array = BG_STOPS[i - 1]
			var b: Array = BG_STOPS[i]
			return (a[1] as Color).lerp(b[1], (t - a[0]) / (b[0] - a[0]))
	return BG_STOPS[BG_STOPS.size() - 1][1]


## Recorta `region` da arte transparente, preenche um quadrado (cobrindo, centrado) e põe o fundo atrás.
static func _with_bg(art: Texture2D, region: Rect2) -> Texture2D:
	var src := art.get_image()
	if src == null:
		return art
	src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var crop := src.get_region(Rect2i(region))
	var side := mini(crop.get_width(), crop.get_height())
	var sq := crop.get_region(Rect2i((crop.get_width() - side) / 2, (crop.get_height() - side) / 2, side, side))
	sq.resize(ICON_PX, ICON_PX, Image.INTERPOLATE_LANCZOS)
	var out := Image.create(ICON_PX, ICON_PX, false, Image.FORMAT_RGBA8)
	for y in ICON_PX:
		var bg := _bg_color(float(y) / float(ICON_PX - 1))
		for x in ICON_PX:
			var fg := sq.get_pixel(x, y)
			out.set_pixel(x, y, bg.lerp(Color(fg.r, fg.g, fg.b, 1.0), fg.a))
	return ImageTexture.create_from_image(out)


static func get_icon(character_name: String) -> Texture2D:
	var key := character_name.to_lower()
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = null
	if FACE_CROP.has(key):
		var full_path := SUGIMORI_DIR + key + ".png"
		if ResourceLoader.exists(full_path):
			tex = _with_bg(load(full_path) as Texture2D, FACE_CROP[key])
	if tex == null:
		var path := FALLBACK_DIR + key + ".png"
		if ResourceLoader.exists(path):
			tex = load(path)
	_cache[key] = tex
	return tex
