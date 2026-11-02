"""
Generates 3D VFX meshes (.glb) in Blender 5.2 and multi-frame VFX sprite sheets (.png)
in `assets/vfx/`:
  1. slash_arc.glb    - 3D curved crescent slash mesh with tapered profile & 0..1 UVs
  2. shock_cone.glb   - 3D directional shockwave ring/cone mesh with 0..1 UVs
  3. ribbon_trail.glb - 3D curved ribbon strip for projectile/dash trails
"""
import os
import math
import bpy
import bmesh

OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "vfx"))
os.makedirs(OUT_DIR, exist_ok=True)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def build_slash_arc():
    """Creates a 3D curved anime slash crescent mesh with UV.x along arc (0..1) and UV.y across width (0..1)."""
    clear_scene()
    mesh = bpy.data.meshes.new("SlashArc")
    obj = bpy.data.objects.new("SlashArc", mesh)
    bpy.context.collection.objects.link(obj)

    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")

    segs_u = 40  # segments along the arc
    segs_v = 6   # segments across blade width
    arc_angle = math.radians(210.0)
    base_radius = 1.35

    grid = []
    for i in range(segs_u + 1):
        u = i / float(segs_u)
        ang = (u - 0.5) * arc_angle
        # Taper width at both tips (sin curve) with a thicker leading head
        taper = math.sin(u * math.pi) ** 0.75 * (0.65 + 0.35 * math.sin(u * math.pi * 0.85))
        half_w = 0.42 * taper
        row = []
        for j in range(segs_v + 1):
            v = j / float(segs_v)
            # Dish/curve the cross-section in 3D so it reads from any camera angle
            across = (v - 0.5) * 2.0
            r = base_radius + across * half_w
            z_curve = (1.0 - across * across) * 0.16 * taper
            x = math.cos(ang) * r
            y = math.sin(ang) * r
            z = z_curve
            vert = bm.verts.new((x, z, y))
            row.append((vert, u, v))
        grid.append(row)

    bm.verts.ensure_lookup_table()
    for i in range(segs_u):
        for j in range(segs_v):
            v00, u00, w00 = grid[i][j]
            v10, u10, w10 = grid[i + 1][j]
            v11, u11, w11 = grid[i + 1][j + 1]
            v01, u01, w01 = grid[i][j + 1]
            face = bm.faces.new((v00, v10, v11, v01))
            face.smooth = True
            uvs = [(u00, w00), (u10, w10), (u11, w11), (u01, w01)]
            for loop, uv in zip(face.loops, uvs):
                loop[uv_layer].uv = uv

    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()

    out_path = os.path.join(OUT_DIR, "slash_arc.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format="GLB", use_selection=False)
    print("Exported:", out_path)


def build_shock_cone():
    """Creates a flared 3D impact shockwave cone/ring with UVs for directional удар/burst waves."""
    clear_scene()
    mesh = bpy.data.meshes.new("ShockCone")
    obj = bpy.data.objects.new("ShockCone", mesh)
    bpy.context.collection.objects.link(obj)

    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")

    segs_u = 36
    segs_v = 8
    r_inner = 0.35
    r_outer = 1.65

    grid = []
    for i in range(segs_u + 1):
        u = i / float(segs_u)
        ang = u * math.tau
        row = []
        for j in range(segs_v + 1):
            v = j / float(segs_v)
            r = r_inner + (r_outer - r_inner) * (v ** 0.85)
            # Flared lip profile
            y = math.sin(v * math.pi) * 0.28 + v * 0.35
            x = math.cos(ang) * r
            z = math.sin(ang) * r
            vert = bm.verts.new((x, y, z))
            row.append((vert, u, v))
        grid.append(row)

    bm.verts.ensure_lookup_table()
    for i in range(segs_u):
        for j in range(segs_v):
            v00, u00, w00 = grid[i][j]
            v10, u10, w10 = grid[i + 1][j]
            v11, u11, w11 = grid[i + 1][j + 1]
            v01, u01, w01 = grid[i][j + 1]
            face = bm.faces.new((v00, v10, v11, v01))
            face.smooth = True
            for loop, uv in zip(face.loops, [(u00, w00), (u10, w10), (u11, w11), (u01, w01)]):
                loop[uv_layer].uv = uv

    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()

    out_path = os.path.join(OUT_DIR, "shock_cone.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format="GLB", use_selection=False)
    print("Exported:", out_path)


def build_ribbon_trail():
    """Creates a twisted 3D energy ribbon mesh for projectile & dash trails."""
    clear_scene()
    mesh = bpy.data.meshes.new("RibbonTrail")
    obj = bpy.data.objects.new("RibbonTrail", mesh)
    bpy.context.collection.objects.link(obj)

    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")

    segs_u = 32
    segs_v = 4
    length = 1.0

    grid = []
    for i in range(segs_u + 1):
        u = i / float(segs_u)
        z = (u - 0.5) * length
        taper = math.sin(u * math.pi) ** 0.5
        twist = u * math.pi * 0.65
        half_w = 0.45 * taper
        row = []
        for j in range(segs_v + 1):
            v = j / float(segs_v)
            across = (v - 0.5) * 2.0 * half_w
            x = across * math.cos(twist)
            y = across * math.sin(twist)
            vert = bm.verts.new((x, y, z))
            row.append((vert, u, v))
        grid.append(row)

    bm.verts.ensure_lookup_table()
    for i in range(segs_u):
        for j in range(segs_v):
            v00, u00, w00 = grid[i][j]
            v10, u10, w10 = grid[i + 1][j]
            v11, u11, w11 = grid[i + 1][j + 1]
            v01, u01, w01 = grid[i][j + 1]
            face = bm.faces.new((v00, v10, v11, v01))
            face.smooth = True
            for loop, uv in zip(face.loops, [(u00, w00), (u10, w10), (u11, w11), (u01, w01)]):
                loop[uv_layer].uv = uv

    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()

    out_path = os.path.join(OUT_DIR, "ribbon_trail.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format="GLB", use_selection=False)
    print("Exported:", out_path)


if __name__ == "__main__":
    build_slash_arc()
    build_shock_cone()
    build_ribbon_trail()
