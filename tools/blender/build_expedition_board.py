"""Expedition Board (hub): the waystone kiosk where the Expedition Gate panel is opened.

Run:  blender -b -P tools/blender/build_expedition_board.py -- <out.glb> [<preview.png>]
Low (top of the compass 1.85 m; the old pole + panel reached 2.7 m), front = Godot +Z (Blender -Y).
Objects per material so the game can recolour/animate them: Board_Stone (stone, stone_dark),
Board_Wood, Board_Gold, Board_Paper (paper, wax), Board_Glow (lantern glass + plinth runes),
Board_Compass (gold ring + glowing spokes/gems; origin at its centre so the game can spin it).
"""
import bpy
import bmesh
import math
import sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "expedition_board.glb"
PREVIEW = argv[1] if len(argv) > 1 else ""
bpy.ops.wm.read_factory_settings(use_empty=True)
TAU = math.tau


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


M_STONE = mat("board_stone", (0.40, 0.36, 0.33))
M_DARK = mat("board_stone_dark", (0.22, 0.19, 0.18))
M_WOOD = mat("board_wood", (0.30, 0.20, 0.12))
M_GOLD = mat("board_gold", (0.80, 0.56, 0.20), 0.45, metal=0.6)
M_PAPER = mat("board_paper", (0.88, 0.80, 0.60))
M_WAX = mat("board_wax", (0.62, 0.10, 0.08))
M_GLOW = mat("board_glow", (1.0, 0.62, 0.22), 0.5, (1.0, 0.55, 0.15), 3.0)


class Part:
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
        for f in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
            self.quad(p[f[0]], p[f[1]], p[f[2]], p[f[3]], mi)

    def box(self, c, s, mi=0, rot_z=0.0, rot_y=0.0, taper=1.0):
        """Box centred at c (size s). rot_z turns it in the XY plane (plan), rot_y in the XZ plane (the
        front view, used for papers). `taper` scales the top face (1 = straight)."""
        hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
        pts = []
        for k, dz in enumerate((-hz, hz)):
            t = 1.0 if k == 0 else taper
            for (dx, dy) in ((-hx, -hy), (hx, -hy), (hx, hy), (-hx, hy)):
                x, y, z = dx * t, dy * t, dz
                x, y = x * math.cos(rot_z) - y * math.sin(rot_z), x * math.sin(rot_z) + y * math.cos(rot_z)
                x, z = x * math.cos(rot_y) + z * math.sin(rot_y), -x * math.sin(rot_y) + z * math.cos(rot_y)
                pts.append(Vector((c[0] + x, c[1] + y, c[2] + z)))
        self.hexa(pts, mi)

    def build(self, loc=(0, 0, 0)):
        me = bpy.data.meshes.new(self.name)
        me.from_pydata(self.verts, [], self.faces)
        me.update()
        ob = bpy.data.objects.new(self.name, me)
        ob.location = loc
        bpy.context.collection.objects.link(ob)
        for m in self.mats:
            me.materials.append(m)
        for p, mi in zip(me.polygons, self.fmat):
            p.material_index = mi
        return ob


def frustum(part, r0, r1, z0, z1, mi, n=8):
    for i in range(n):
        a0, a1 = TAU * i / n, TAU * (i + 1) / n
        part.quad(Vector((r0 * math.cos(a0), r0 * math.sin(a0), z0)), Vector((r0 * math.cos(a1), r0 * math.sin(a1), z0)),
                  Vector((r1 * math.cos(a1), r1 * math.sin(a1), z1)), Vector((r1 * math.cos(a0), r1 * math.sin(a0), z1)), mi)
        part.tri(Vector((0, 0, z1)), Vector((r1 * math.cos(a0), r1 * math.sin(a0), z1)), Vector((r1 * math.cos(a1), r1 * math.sin(a1), z1)), mi)


def ring(part, r_in, r_out, z, n=32, mi=0):
    for i in range(n):
        a0, a1 = TAU * i / n, TAU * (i + 1) / n
        part.quad(Vector((r_in * math.cos(a0), r_in * math.sin(a0), z)), Vector((r_out * math.cos(a0), r_out * math.sin(a0), z)),
                  Vector((r_out * math.cos(a1), r_out * math.sin(a1), z)), Vector((r_in * math.cos(a1), r_in * math.sin(a1), z)), mi)


stone = Part("Board_Stone", [M_STONE, M_DARK])
wood = Part("Board_Wood", [M_WOOD])
gold = Part("Board_Gold", [M_GOLD])
paper = Part("Board_Paper", [M_PAPER, M_WAX])
glow = Part("Board_Glow", [M_GLOW])
comp = Part("Board_Compass", [M_GOLD, M_GLOW])

FY = -0.19  # front face of the stele (front = -Y)

# --- Plinth: two octagonal tiers, glowing rune ring on the top ---------------------------------------
frustum(stone, 0.98, 0.90, 0.0, 0.12, 1)
frustum(stone, 0.80, 0.72, 0.12, 0.24, 0)
ring(glow, 0.52, 0.57, 0.246, 32)
for i in range(8):
    a = TAU * i / 8
    glow.box((0.67 * math.cos(a), 0.67 * math.sin(a), 0.246), (0.10, 0.03, 0.004), 0, rot_z=a)

# --- Stele: tapered body, dark cap with gold trim --------------------------------------------------------
stone.box((0, 0.0, 0.68), (1.12, 0.38, 0.88), 0, taper=0.94)          # z 0.24..1.12
stone.box((0, 0.0, 1.17), (1.30, 0.52, 0.10), 1)                      # cap
gold.box((0, 0.0, 1.115), (1.18, 0.44, 0.025), 0)                     # gold band under the cap
for sx in (-1, 1):                                                    # corner buttresses
    stone.box((sx * 0.60, -0.05, 0.50), (0.14, 0.30, 0.52), 1, taper=0.7)

# --- Notice panel: gold frame, wood board, pinned papers with wax seals -------------------------------------
wood.box((0, FY - 0.02, 0.70), (0.84, 0.04, 0.64), 0)
for (cx, cz, w, h) in ((0, 0.70 + 0.34, 0.90, 0.04), (0, 0.70 - 0.34, 0.90, 0.04), (-0.45, 0.70, 0.04, 0.72), (0.45, 0.70, 0.04, 0.72)):
    gold.box((cx, FY - 0.045, cz), (w, 0.05, h), 0)
slips = [(-0.22, 0.84, 0.22, 0.26, 0.06), (0.10, 0.88, 0.24, 0.20, -0.08), (0.28, 0.66, 0.20, 0.28, 0.05),
         (-0.28, 0.58, 0.26, 0.20, -0.04), (0.0, 0.62, 0.18, 0.22, 0.10)]
for (cx, cz, w, h, r) in slips:
    paper.box((cx, FY - 0.048, cz), (w, 0.012, h), 0, rot_y=r)
    paper.box((cx, FY - 0.058, cz + h * 0.38), (0.045, 0.014, 0.045), 1)  # wax seal at the top of each slip

# --- Lamp posts with glowing lanterns ---------------------------------------------------------------------------
for sx in (-1, 1):
    px = sx * 0.78
    stone.box((px, -0.05, 0.30), (0.22, 0.22, 0.12), 1)
    wood.box((px, -0.05, 0.62), (0.07, 0.07, 0.64), 0)
    gold.box((px, -0.05, 0.96), (0.20, 0.20, 0.04), 0)
    glow.box((px, -0.05, 1.07), (0.15, 0.15, 0.18), 0, taper=0.9)
    gold.box((px, -0.05, 1.19), (0.22, 0.22, 0.04), 0, taper=0.6)

# --- Compass: gold ring, glowing inner ring, spokes and cardinal gems (centred at its own origin) ---------
CC = (0.0, 0.0, 1.58)
for i in range(32):
    a0, a1 = TAU * i / 32, TAU * (i + 1) / 32
    for sgn, mi_ in ((-1, 0), (1, 0)):
        pass
    p = lambda r, a, y: Vector((r * math.cos(a), y, r * math.sin(a)))
    comp.quad(p(0.27, a0, -0.03), p(0.27, a1, -0.03), p(0.27, a1, 0.03), p(0.27, a0, 0.03), 0)    # outer wall
    comp.quad(p(0.34, a0, -0.03), p(0.34, a1, -0.03), p(0.34, a1, 0.03), p(0.34, a0, 0.03), 0)
    comp.quad(p(0.27, a0, -0.03), p(0.34, a0, -0.03), p(0.34, a1, -0.03), p(0.27, a1, -0.03), 0)   # front face
    comp.quad(p(0.27, a0, 0.03), p(0.27, a1, 0.03), p(0.34, a1, 0.03), p(0.34, a0, 0.03), 0)      # back face
    comp.quad(p(0.19, a0, -0.012), p(0.22, a0, -0.012), p(0.22, a1, -0.012), p(0.19, a1, -0.012), 1)  # inner glow ring
for k in range(4):                                  # spokes + gems at N/E/S/W
    a = TAU * k / 4
    comp.box((0.20 * math.cos(a), -0.01, 0.20 * math.sin(a)), (0.30, 0.02, 0.025), 0, rot_y=-a)
    g = Vector((0.40 * math.cos(a), -0.02, 0.40 * math.sin(a)))
    r = 0.045
    for (u, v) in ((r, 0), (0, r), (-r, 0), (0, -r)):
        pass
    comp.box((g.x, g.y, g.z), (0.09, 0.04, 0.09), 1, rot_y=math.pi / 4)
comp.box((0, -0.02, 0), (0.13, 0.05, 0.13), 1, rot_y=math.pi / 4)  # centre gem

# --- Mount for the compass on the cap ---------------------------------------------------------------------------------
gold.box((0, 0.0, 1.31), (0.10, 0.10, 0.22), 0)
gold.box((0, 0.0, 1.22), (0.30, 0.22, 0.04), 0)

parts = [stone, wood, gold, paper, glow]
objs = [p.build() for p in parts]
objs.append(comp.build(loc=CC))


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
        bpy.ops.object.modifier_apply(modifier="Bevel")
    ob.select_set(False)


for ob, b in zip(objs, (0.012, 0.008, 0.006, 0.0, 0.0, 0.004)):
    finish(ob, b)

tris = 0
for ob in objs:
    ob.data.calc_loop_triangles()
    tris += len(ob.data.loop_triangles)
top = max((ob.matrix_world @ Vector(c)).z for ob in objs for c in ob.bound_box)
print("BOARD_TOTAL_TRIS", tris, "BOARD_HEIGHT_M", round(top, 3))
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_apply=True, export_yup=True, export_materials="EXPORT")
print("BOARD_EXPORTED", OUT)

if PREVIEW:
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "MATERIAL"
    sc.render.resolution_x, sc.render.resolution_y = 700, 700
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    bpy.context.collection.objects.link(cam)
    cam.location = (2.2, -4.2, 2.0)
    cam.rotation_euler = (Vector((0, 0, 0.95)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.camera = cam
    sc.render.filepath = PREVIEW
    bpy.ops.render.render(write_still=True)
