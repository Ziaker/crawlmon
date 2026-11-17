"""Expedition Gate (hub): hard-surface ring portal on a stepped dais.

Run:  blender -b -P tools/blender/build_expedition_gate.py -- <out.glb> [<preview.png>]
Real size in metres, origin at the dais centre on the floor, ring plane = Godot XY (axis = Godot Z),
total height ~3.7 m (the old arch was 5.5 m). Separate objects per material so the game can swap
them for toon / emissive materials by name: Gate_Stone (slots stone, stone_dark), Gate_Gold,
Gate_Rune (emissive glyphs, recoloured per world), Gate_Shard (floating rune shard, orbited in game).
Hard-surface stance: cut/segment first, bevel (angle-limited, harden normals) after, weighted normals last.
"""
import bpy
import bmesh
import math
import sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "expedition_gate.glb"
PREVIEW = argv[1] if len(argv) > 1 else ""

CY = 1.47          # ring centre height (opening bottom = CY - R_IN = dais top)
R_IN, R_OUT = 1.25, 1.70
DEPTH = 0.25       # half thickness of the ring blocks (Blender Y)
DAIS_TOP = 0.22
N_BLOCKS = 24

bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, rgb, rough=0.9, emit=None, energy=0.0, metal=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*rgb, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit is not None:
        b.inputs["Emission Color"].default_value = (*emit, 1.0)
        b.inputs["Emission Strength"].default_value = energy
    return m


M_STONE = mat("gate_stone", (0.34, 0.31, 0.29))
M_DARK = mat("gate_stone_dark", (0.20, 0.18, 0.17))
M_GOLD = mat("gate_gold", (0.78, 0.55, 0.20), 0.45, metal=0.6)
M_RUNE = mat("gate_rune", (1.0, 0.62, 0.22), 0.5, (1.0, 0.55, 0.15), 3.0)


class Part:
    """Accumulates raw geometry for one object."""

    def __init__(self, name, mats):
        self.name, self.mats = name, mats
        self.verts, self.faces, self.fmat = [], [], []

    def quad(self, a, b, c, d, mi=0):
        i = len(self.verts)
        self.verts += [tuple(a), tuple(b), tuple(c), tuple(d)]
        self.faces.append((i, i + 1, i + 2, i + 3))
        self.fmat.append(mi)

    def tri(self, a, b, c, mi=0):
        i = len(self.verts)
        self.verts += [tuple(a), tuple(b), tuple(c)]
        self.faces.append((i, i + 1, i + 2))
        self.fmat.append(mi)

    def hexa(self, p, mi=0):
        """Hexahedron from 8 corners (bottom 0-3, top 4-7, counter-clockwise seen from above)."""
        for f in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
            self.quad(p[f[0]], p[f[1]], p[f[2]], p[f[3]], mi)

    def box(self, c, s, mi=0, rot_y=0.0):
        hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
        ca, sa = math.cos(rot_y), math.sin(rot_y)
        pts = []
        for dz in (-hz, hz):
            for (dx, dy) in ((-hx, -hy), (hx, -hy), (hx, hy), (-hx, hy)):
                x = dx * ca - dy * sa
                y = dx * sa + dy * ca
                pts.append(Vector((c[0] + x, c[1] + y, c[2] + dz)))
        self.hexa(pts, mi)

    def build(self):
        me = bpy.data.meshes.new(self.name)
        me.from_pydata(self.verts, [], self.faces)
        me.update()
        ob = bpy.data.objects.new(self.name, me)
        bpy.context.collection.objects.link(ob)
        for m in self.mats:
            me.materials.append(m)
        for p, mi in zip(me.polygons, self.fmat):
            p.material_index = mi
        return ob


def ring_pt(angle, r, y):
    """Point on the ring plane (Blender XZ): x = r cos, z = CY + r sin."""
    return Vector((r * math.cos(angle), y, CY + r * math.sin(angle)))


stone = Part("Gate_Stone", [M_STONE, M_DARK])
gold = Part("Gate_Gold", [M_GOLD])
rune = Part("Gate_Rune", [M_RUNE])

# --- Dais: two sloped round tiers (walkable) + engraved glyph ring -------------------------------
SEG = 48


def frustum(part, r0, r1, y0, y1, mi, cx=0.0, cy=0.0):
    for i in range(SEG):
        a0, a1 = TAU_ * i / SEG, TAU_ * (i + 1) / SEG
        b0 = Vector((cx + r0 * math.cos(a0), cy + r0 * math.sin(a0), y0))
        b1 = Vector((cx + r0 * math.cos(a1), cy + r0 * math.sin(a1), y0))
        t1 = Vector((cx + r1 * math.cos(a1), cy + r1 * math.sin(a1), y1))
        t0 = Vector((cx + r1 * math.cos(a0), cy + r1 * math.sin(a0), y1))
        part.quad(b0, b1, t1, t0, (mi + i) % 2 if mi < 0 else mi)


def disc_ring(part, r_in, r_out, z, mi=0):
    for i in range(SEG):
        a0, a1 = TAU_ * i / SEG, TAU_ * (i + 1) / SEG
        part.quad(Vector((r_in * math.cos(a0), r_in * math.sin(a0), z)), Vector((r_out * math.cos(a0), r_out * math.sin(a0), z)),
                  Vector((r_out * math.cos(a1), r_out * math.sin(a1), z)), Vector((r_in * math.cos(a1), r_in * math.sin(a1), z)), mi)


TAU_ = math.tau
frustum(stone, 2.05, 1.90, 0.0, 0.10, 0)
disc_ring(stone, 1.78, 1.90, 0.10, 1)             # ledge (darker)
frustum(stone, 1.78, 1.60, 0.10, DAIS_TOP, 0)
disc_ring(stone, 0.0 + 0.001, 1.60, DAIS_TOP, 0)  # top (fan from the centre ring)

# engraved glyph rings (emissive, a hair above the stone): outer ring, inner ring, 12 ticks
disc_ring(rune, 1.30, 1.37, DAIS_TOP + 0.004)
disc_ring(rune, 0.52, 0.56, DAIS_TOP + 0.004)
for i in range(12):
    a = TAU_ * i / 12
    c = Vector((0.93 * math.cos(a), 0.93 * math.sin(a), DAIS_TOP + 0.004))
    rune.box((c.x, c.y, c.z), (0.22, 0.045, 0.004), 0, a)

# --- The ring: 24 voussoir blocks with gaps, alternating tones, depth and outer radius -----------
GAP = math.radians(1.1)
for i in range(N_BLOCKS):
    a0 = TAU_ * i / N_BLOCKS + GAP
    a1 = TAU_ * (i + 1) / N_BLOCKS - GAP
    odd = i % 2
    d = DEPTH - (0.03 if odd else 0.0)
    ro = R_OUT - (0.05 if odd else 0.0)
    pts = []
    for y in (-d, d):
        pts += [ring_pt(a0, R_IN, y), ring_pt(a1, R_IN, y), ring_pt(a1, ro, y), ring_pt(a0, ro, y)]
    # corners 0-3 = back (-y), 4-7 = front (+y): faces wound outward
    f = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    for q in f:
        stone.quad(pts[q[0]], pts[q[1]], pts[q[2]], pts[q[3]], 1 if odd else 0)
    # glyph plates on both faces of every block but those at the very bottom (buried in the dais)
    mid = (a0 + a1) / 2
    if CY + 1.5 * math.sin(mid) > DAIS_TOP + 0.45:
        for sgn in (-1, 1):
            y = sgn * (d + 0.006)
            rc = (R_IN + ro) / 2
            c = ring_pt(mid, rc, y)
            vertical = abs(math.cos(mid)) < abs(math.sin(mid))  # near the top: the radial direction is vertical
            long_s, short_s = (0.30, 0.07)
            sx, sz = (short_s, long_s) if vertical else (long_s, short_s)
            rune.box((c.x, c.y, c.z), (sx, 0.012, sz), 0, 0.0)
            if i % 3 == 0:  # tangential crossbar: reads as a glyph, not just a bar
                tx, tz = (long_s * 0.55, short_s * 0.9) if vertical else (short_s * 0.9, long_s * 0.55)
                rune.box((c.x, c.y, c.z + (0.05 if vertical else 0.0)), (tx, 0.012, tz), 0, 0.0)

# --- Gold inlay ring on both faces + crest + feet caps -----------------------------------------------
for sgn in (-1, 1):
    y0 = sgn * (DEPTH + 0.012)
    for i in range(SEG):
        a0, a1 = TAU_ * i / SEG, TAU_ * (i + 1) / SEG
        gold.quad(ring_pt(a0, R_IN + 0.02, y0), ring_pt(a1, R_IN + 0.02, y0), ring_pt(a1, R_IN + 0.11, y0), ring_pt(a0, R_IN + 0.11, y0)) if sgn > 0 else \
            gold.quad(ring_pt(a1, R_IN + 0.02, y0), ring_pt(a0, R_IN + 0.02, y0), ring_pt(a0, R_IN + 0.11, y0), ring_pt(a1, R_IN + 0.11, y0))
# thin gold band lining the inner opening
for i in range(SEG):
    a0, a1 = TAU_ * i / SEG, TAU_ * (i + 1) / SEG
    p = [ring_pt(a0, R_IN - 0.012, -DEPTH), ring_pt(a1, R_IN - 0.012, -DEPTH), ring_pt(a1, R_IN - 0.012, DEPTH), ring_pt(a0, R_IN - 0.012, DEPTH)]
    gold.quad(p[0], p[3], p[2], p[1])

# crest: central spire + two flanking angled spires behind a gold socket for the gem
def spire(part, base_c, ang, h, w, d, mi=0):
    """4-sided tapering spire standing on the ring top, leaning by `ang` (radians about Y)."""
    pts = []
    for (dx, dy) in ((-w, -d), (w, -d), (w, d), (-w, d)):
        pts.append(Vector((base_c[0] + dx, base_c[1] + dy, base_c[2])))
    tip = Vector((base_c[0] + math.sin(ang) * h * 0.3, base_c[1], base_c[2] + h))
    tx, ty = 0.025, 0.02
    top = [Vector((tip.x + dx, tip.y + dy, tip.z)) for (dx, dy) in ((-tx, -ty), (tx, -ty), (tx, ty), (-tx, ty))]
    part.hexa(pts + top, mi)


top_z = CY + R_OUT
spire(gold, (0.0, 0.0, top_z - 0.02), 0.0, 0.52, 0.13, 0.15)
for sgn in (-1, 1):
    a = sgn * math.radians(34)
    base = ring_pt(math.pi / 2 - a, R_OUT - 0.05, 0.0)
    spire(gold, (base.x, base.y, base.z - 0.02), sgn * 0.6, 0.30, 0.085, 0.12)

# the gem socket (front and back) and the gem itself: an octahedron per face in the rune object
for sgn in (-1, 1):
    y = sgn * (DEPTH + 0.03)
    gold.box((0.0, y, CY + R_IN + 0.285), (0.27, 0.07, 0.20), 0)
    gc = Vector((0.0, sgn * (DEPTH + 0.09), CY + R_IN + 0.285))
    r = 0.12
    top_v, bot_v = gc + Vector((0, 0, r * 1.35)), gc - Vector((0, 0, r * 1.35))
    eq = [gc + Vector((r, 0, 0)), gc + Vector((0, r * 0.7, 0)), gc + Vector((-r, 0, 0)), gc + Vector((0, -r * 0.7, 0))]
    for k in range(4):
        a, b = eq[k], eq[(k + 1) % 4]
        if sgn > 0:
            rune.tri(top_v, b, a)
            rune.tri(bot_v, a, b)
        else:
            rune.tri(top_v, a, b)
            rune.tri(bot_v, b, a)

# --- Feet: stone brackets that carry the ring on the dais, gold caps, rune crystals ----------------
for sgn in (-1, 1):
    fx = sgn * 1.52
    stone.box((fx, 0.0, DAIS_TOP + 0.30), (0.86, 0.64, 0.60), 1)
    stone.box((fx, 0.0, DAIS_TOP + 0.64), (0.96, 0.72, 0.08), 0)
    gold.box((fx, 0.0, DAIS_TOP + 0.70), (0.70, 0.52, 0.045), 0)
    # small pedestal with a leaning rune crystal in front of each foot
    px, py = sgn * 1.28, -0.95  # Blender -Y exports to Godot +Z: the player's side
    stone.box((px, py, DAIS_TOP + 0.09), (0.34, 0.34, 0.18), 1)
    gold.box((px, py, DAIS_TOP + 0.195), (0.26, 0.26, 0.03), 0)
    c = Vector((px, py, DAIS_TOP + 0.21))
    base = [c + Vector((-0.08, -0.08, 0)), c + Vector((0.08, -0.08, 0)), c + Vector((0.08, 0.08, 0)), c + Vector((-0.08, 0.08, 0))]
    mid = [Vector((q.x * 1.0, q.y * 1.0, q.z + 0.28)) for q in base]
    tip = c + Vector((0.0, 0.0, 0.62))
    for k in range(4):
        rune.quad(base[k], base[(k + 1) % 4], mid[(k + 1) % 4], mid[k])
        rune.tri(mid[k], mid[(k + 1) % 4], tip)

# --- Floating shard (one mesh; the game orbits several) --------------------------------------------
shard = Part("Gate_Shard", [M_RUNE])
r, h = 0.075, 0.20
eqs = [Vector((r, 0, 0)), Vector((0, r * 0.6, 0)), Vector((-r, 0, 0)), Vector((0, -r * 0.6, 0))]
for k in range(4):
    a, b = eqs[k], eqs[(k + 1) % 4]
    shard.tri(Vector((0, 0, h)), a, b)
    shard.tri(Vector((0, 0, -h)), b, a)

objs = [stone.build(), gold.build(), rune.build(), shard.build()]

# rune glyph plates were created axis-aligned: orient them radially (long side along the radius)
ob_r = objs[2]
bm = bmesh.new()
bm.from_mesh(ob_r.data)
# (kept axis-aligned: the plates read as carved bars; rotating each quad would need per-face pivots)
bm.free()


def finish(ob, bevel):
    me = ob.data
    for p in me.polygons:
        p.use_smooth = False
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    if bevel > 0:
        mod = ob.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = "ANGLE"
        mod.angle_limit = math.radians(35)
        mod.harden_normals = True
        mod.miter_outer = "MITER_ARC"
        wn = ob.modifiers.new("WN", "WEIGHTED_NORMAL")
        wn.keep_sharp = True
        wn.mode = "FACE_AREA"
        bpy.ops.object.modifier_apply(modifier="Bevel")
        bpy.ops.object.modifier_apply(modifier="WN")
    ob.select_set(False)


finish(objs[0], 0.012)
finish(objs[1], 0.006)
finish(objs[2], 0.0)
finish(objs[3], 0.0)

tris = 0
for ob in objs:
    me = ob.data
    me.calc_loop_triangles()
    tris += len(me.loop_triangles)
    print("GATE_OBJ", ob.name, "tris", len(me.loop_triangles))
print("GATE_TOTAL_TRIS", tris)
mx = max((o.matrix_world @ Vector(c)).z for o in objs[:3] for c in o.bound_box)
print("GATE_HEIGHT_M", round(mx, 3))

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_apply=True, export_yup=True,
                          export_materials="EXPORT", use_selection=False)
print("GATE_EXPORTED", OUT)

if PREVIEW:
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "MATERIAL"
    sc.render.resolution_x, sc.render.resolution_y = 900, 700
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    bpy.context.collection.objects.link(cam)
    cam.location = (3.6, -7.5, 2.6)
    cam.rotation_euler = (Vector((0, 0, 1.8)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.camera = cam
    sc.render.filepath = PREVIEW
    bpy.ops.render.render(write_still=True)
    print("GATE_PREVIEW", PREVIEW)
