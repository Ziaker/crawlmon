import bpy, sys, json
from mathutils import Vector

# Dumps the 3D path of every hand bone (tail) in the "attack" clip, relative to the hips, per frame.
argv = sys.argv[sys.argv.index("--") + 1:]
path, out = argv[0], argv[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=path)
arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
scene = bpy.context.scene
fps = scene.render.fps
names = [b.name for b in arm.data.bones]
hands = [n for n in names if n.lower().endswith("hand") or "hand" in n.lower()]
hips = "hips" if "hips" in names else ("waist" if "waist" in names else names[0])
act = bpy.data.actions.get("attack") or next(a for a in bpy.data.actions if "attack" in a.name.lower())
arm.animation_data_create()
arm.animation_data.action = act
f0, f1 = int(act.frame_range[0]), int(act.frame_range[1])
res = {"fps": fps, "hands": hands, "hips": hips, "frames": []}
for f in range(f0, f1 + 1):
    scene.frame_set(f)
    bpy.context.view_layer.update()
    h = arm.matrix_world @ arm.pose.bones[hips].head
    row = {"f": f, "t": (f - f0) / fps, "hips": [h.x, h.y, h.z]}
    for n in hands:
        p = arm.matrix_world @ arm.pose.bones[n].tail
        row[n] = [p.x - h.x, p.y - h.y, p.z - h.z]
    res["frames"].append(row)
json.dump(res, open(out, "w"))
print("HAND_PATH_DONE", len(res["frames"]), hands)
