import sys
import os

# Add host site-packages for flatbuffers
sys.path.append(r"C:\Python313\Lib\site-packages")

import bpy
import numpy as np
import addon_utils

print("--- EXPORTING POKEMON 3D (LEGENDS Z-A -> GLB) ---")

# Ensure addon is enabled
addon_utils.enable("PokemonSwitchV3", default_set=True)

ZA_ROOT = r"c:\Users\zerke\OneDrive\Área de Trabalho\Arenamon\dumper test\LegendsZAPkmnModelDumpWithDLC"
OUTPUT_BASE = r"C:\Users\zerke\OneDrive\Área de Trabalho\Z\crawlmon\assets\modelos"

TARGETS = [
    {
        "id": "abra",
        "folder": r"pm0063\pm0063_00_00",
        "trmdl": "pm0063_00_00.trmdl",
        "anims": {
            "idle": "pm0063_00_00_20000_defaultwait01_loop.tranm",
            "battle_idle": "pm0063_00_00_20012_battleidle02.tranm",
            "walk": "pm0063_00_00_20030_walk01_loop.tranm",
            "run": "pm0063_00_00_20100_run01_loop.tranm",
            "attack": "pm0063_00_00_20400_attack01.tranm",
            "attack_special": "pm0063_00_00_20450_rangeattack01.tranm",
            "charge": "pm0063_00_00_20490_charge01_loop.tranm",
            "damage": "pm0063_00_00_20500_damage01.tranm",
            "down": "pm0063_00_00_20520_down01_start.tranm",
            "victory": "pm0063_00_00_20310_appeal01.tranm"
        }
    },
    {
        "id": "gible",
        "folder": r"pm0443\pm0443_00_00",
        "trmdl": "pm0443_00_00.trmdl",
        "anims": {
            "idle": "pm0443_00_00_00000_defaultwait01_loop.tranm",
            "battle_idle": "pm0443_00_00_00001_battlewait01_loop.tranm",
            "walk": "pm0443_00_00_00030_walk01_loop.tranm",
            "run": "pm0443_00_00_00100_run01_loop.tranm",
            "attack": "pm0443_00_00_00400_attack01.tranm",
            "attack_special": "pm0443_00_00_00450_rangeattack01.tranm",
            "charge": "pm0443_00_00_00490_charge01_loop.tranm",
            "damage": "pm0443_00_00_00500_damage01.tranm",
            "down": "pm0443_00_00_00520_down01_start.tranm",
            "victory": "pm0443_00_00_00310_appeal01.tranm"
        }
    },
    {
        "id": "pancham",
        "folder": r"pm0752\pm0752_00_00",
        "trmdl": "pm0752_00_00.trmdl",
        "anims": {
            "idle": "pm0752_00_00_00000_defaultwait01_loop.tranm",
            "battle_idle": "pm0752_00_00_00001_battlewait01_loop.tranm",
            "walk": "pm0752_00_00_00030_walk01_loop.tranm",
            "run": "pm0752_00_00_00100_run01_loop.tranm",
            "attack": "pm0752_00_00_00400_attack01.tranm",
            "attack_special": "pm0752_00_00_00450_rangeattack01.tranm",
            "charge": "pm0752_00_00_00490_charge01_loop.tranm",
            "damage": "pm0752_00_00_00500_damage01.tranm",
            "down": "pm0752_00_00_00520_down01_start.tranm",
            "victory": "pm0752_00_00_00310_appeal01.tranm"
        }
    }
]

def _srgb_to_lin(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)

def _lin_to_srgb(c):
    c = np.clip(c, 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)

def _pixels(img):
    w, h = img.size
    a = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(a)
    return a.reshape(h, w, 4)

EDGE_ERODE = 3

# The dumped shader values give Pancham's face-mask layer (layer 3 of body_a_00; the leaf in body_a_01 keeps its green) a
# debug-like green; in game it is the dark mask, so reuse its layer-2 colour.
LAYER_OVERRIDES = {
    "pancham": {"body_a_00": {3: (0.082, 0.093, 0.105)}},
}
CURRENT_ID = None

def _resize_bilinear(a, h, w):
    """Bilinear-resize an (H,W,C) float array to (h,w,C)."""
    H, W = a.shape[:2]
    if (H, W) == (h, w):
        return a
    ys = (np.arange(h) + 0.5) * H / h - 0.5
    xs = (np.arange(w) + 0.5) * W / w - 0.5
    y0 = np.clip(np.floor(ys).astype(int), 0, H - 1); y1 = np.clip(y0 + 1, 0, H - 1)
    x0 = np.clip(np.floor(xs).astype(int), 0, W - 1); x1 = np.clip(x0 + 1, 0, W - 1)
    fy = np.clip(ys - y0, 0, 1)[:, None, None]; fx = np.clip(xs - x0, 0, 1)[None, :, None]
    top = a[y0][:, x0] * (1 - fx) + a[y0][:, x1] * fx
    bot = a[y1][:, x0] * (1 - fx) + a[y1][:, x1] * fx
    return top * (1 - fy) + bot * fy

def _uv_params(mat):
    """The game shader remaps UVs before every texture lookup: scale (sx, sy),
    then modulo 2/1 with a mirror fold of X above 1 (mirrored repeat). glTF
    can't express that, so it is baked into the texture instead."""
    nt = mat.node_tree
    m = next((n for n in nt.nodes if n.type == 'MAPPING' and any(l.to_node.type == 'VECT_MATH' for o in n.outputs for l in o.links)), None)
    if m is None:
        return 1.0, 1.0
    sc = m.inputs['Scale'].default_value
    return float(sc[0]), float(sc[1])

def _sample(a, U, V):
    """Nearest sample (the shader uses Closest) of (H,W,C) array at uv grids."""
    H, W = a.shape[:2]
    x = np.clip(np.floor(U * W).astype(int), 0, W - 1)
    y = np.clip(np.floor(V * H).astype(int), 0, H - 1)
    return a[y, x]

def _bleed(rgb, valid, iters=96):
    """Fill invalid pixels with the nearest valid colour (kills unmasked/white
    gutters that show up on UV islands that spill outside their painted area)."""
    rgb = rgb.copy(); valid = valid.copy()
    for _ in range(iters):
        if valid.all():
            break
        acc = np.zeros_like(rgb); cnt = np.zeros(valid.shape, dtype=np.float32)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                v = np.roll(valid, (dy, dx), (0, 1))
                c = np.roll(rgb, (dy, dx), (0, 1))
                acc += c * v[..., None]; cnt += v
        fill = (~valid) & (cnt > 0)
        rgb[fill] = acc[fill] / cnt[fill][:, None]
        valid |= fill
    return rgb

def bake_base_color(mat, grp, alb_img, lym_img):
    """Reproduce the game's ColorProcess group: albedo tinted per layer by the
    BaseColorLayerN values, selected by the lym mask (R,G,B,A = layers 1-4,
    value x2 as in the shader's HSV node). Rim / spec / AO / shadow maps are
    intentionally left out. Output uses the larger of the two resolutions."""
    sx, sy = _uv_params(mat)
    src = _pixels(alb_img)
    lsrc = _pixels(lym_img) if lym_img is not None else None
    h = max(alb_img.size[1], lym_img.size[1] if lym_img is not None else 0)
    w = max(alb_img.size[0], lym_img.size[0] if lym_img is not None else 0)
    w = int(round(w * max(1.0, sx))); h = int(round(h * max(1.0, sy)))
    u = (np.arange(w) + 0.5) / w
    v = (np.arange(h) + 0.5) / h
    uu = (u * sx) % 2.0
    uu = np.where(uu > 1.0, 2.0 - uu, uu)
    vv = (v * sy) % 1.0
    U, V = np.meshgrid(uu, vv)
    alb = _sample(src, U, V)
    lin = _srgb_to_lin(alb[..., :3]) if alb_img.colorspace_settings.name == 'sRGB' else alb[..., :3]
    out = lin.copy()
    if lym_img is not None:
        lym = _sample(lsrc, U, V)
        lym = np.clip(lym * 2.0, 0.0, 1.0)
        for i in range(4):
            m = lym[..., i:i + 1]
            scale = grp.inputs[f'LayerMaskScale{i + 1}'].default_value
            m = m * scale
            tint = np.array(LAYER_OVERRIDES.get(CURRENT_ID, {}).get(mat.name, {}).get(i + 1)
                            or grp.inputs[f'BaseColorLayer{i + 1}'].default_value[:3], dtype=np.float32)
            out = out * (1 - m) + (lin * tint) * m
        valid = lym.max(axis=-1) > 0.95
        for _ in range(EDGE_ERODE):  # drop anti-aliased island borders, they still hold white
            valid = valid & np.roll(valid, 1, 0) & np.roll(valid, -1, 0) & np.roll(valid, 1, 1) & np.roll(valid, -1, 1)
        if valid.any():
            out = _bleed(out, valid)
    srgb = _lin_to_srgb(out)
    res = np.concatenate([srgb, np.ones_like(srgb[..., :1])], axis=-1)
    name = os.path.splitext(os.path.basename(alb_img.filepath))[0] + f"_{mat.name}_base"
    img = bpy.data.images.new(name, w, h, alpha=True)
    img.colorspace_settings.name = 'sRGB'
    img.pixels.foreach_set(res.astype(np.float32).ravel())
    img.pack()
    return img

def simplify_materials():
    """Replace the game's custom shader group with a Principled BSDF whose
    Base Color is the baked, tinted albedo (glTF can't export the group)."""
    for mat in list(bpy.data.materials):
        nt = mat.node_tree
        if not nt:
            continue
        grp = next((n for n in nt.nodes if n.type == 'GROUP' and n.inputs.get('Albedo') and n.inputs['Albedo'].links), None)
        if grp is None:
            continue
        alb = grp.inputs['Albedo'].links[0].from_node
        if alb.type != 'TEX_IMAGE' or alb.image is None:
            continue
        lym = None
        if grp.inputs['Lym_color'].links:
            ln = grp.inputs['Lym_color'].links[0].from_node
            if ln.type == 'TEX_IMAGE':
                lym = ln.image
        img = bake_base_color(mat, grp, alb.image, lym)
        for n in list(nt.nodes):
            nt.nodes.remove(n)
        out = nt.nodes.new('ShaderNodeOutputMaterial')
        bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
        tex = nt.nodes.new('ShaderNodeTexImage')
        tex.image = img
        bsdf.inputs['Roughness'].default_value = 0.8
        bsdf.inputs['Metallic'].default_value = 0.0
        nt.links.new(tex.outputs['Color'], bsdf.inputs['Base Color'])
        nt.links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
        print(f"  [MAT] {mat.name}: Base Color <- {img.name}")

TARGETS += [
    {
        "id": "bulbasaur",
        "folder": r"pm0001\pm0001_00_00",
        "trmdl": "pm0001_00_00.trmdl",
        "anims": {
            "idle": "pm0001_00_00_00000_defaultwait01_loop.tranm",
            "battle_idle": "pm0001_00_00_00001_battlewait01_loop.tranm",
            "walk": "pm0001_00_00_00030_walk01_loop.tranm",
            "run": "pm0001_00_00_00100_run01_loop.tranm",
            "attack": "pm0001_00_00_00400_attack01.tranm",
            "attack_special": "pm0001_00_00_00450_rangeattack01.tranm",
            "charge": "pm0001_00_00_00490_charge01_loop.tranm",
            "damage": "pm0001_00_00_00500_damage01.tranm",
            "down": "pm0001_00_00_00520_down01_start.tranm",
            "victory": "pm0001_00_00_00310_appeal01.tranm"
        }
    },
    {
        "id": "charmander",
        "folder": r"pm0004\pm0004_00_00",
        "trmdl": "pm0004_00_00.trmdl",
        "anims": {
            "idle": "pm0004_00_00_00000_defaultwait01_loop.tranm",
            "battle_idle": "pm0004_00_00_00001_battlewait01_loop.tranm",
            "walk": "pm0004_00_00_00030_walk01_loop.tranm",
            "run": "pm0004_00_00_00100_run01_loop.tranm",
            "attack": "pm0004_00_00_00400_attack01.tranm",
            "attack_special": "pm0004_00_00_00450_rangeattack01.tranm",
            "charge": "pm0004_00_00_00490_charge01_loop.tranm",
            "damage": "pm0004_00_00_00500_damage01.tranm",
            "down": "pm0004_00_00_00520_down01_start.tranm",
            "victory": "pm0004_00_00_00310_appeal01.tranm"
        }
    },
    {
        "id": "squirtle",
        "folder": r"pm0007\pm0007_00_00",
        "trmdl": "pm0007_00_00.trmdl",
        "anims": {
            "idle": "pm0007_00_00_00000_defaultwait01_loop.tranm",
            "battle_idle": "pm0007_00_00_00001_battlewait01_loop.tranm",
            "walk": "pm0007_00_00_00030_walk01_loop.tranm",
            "run": "pm0007_00_00_00100_run01_loop.tranm",
            "attack": "pm0007_00_00_00400_attack01.tranm",
            "attack_special": "pm0007_00_00_00450_rangeattack01.tranm",
            "charge": "pm0007_00_00_00490_charge01_loop.tranm",
            "damage": "pm0007_00_00_00500_damage01.tranm",
            "down": "pm0007_00_00_00520_down01_start.tranm",
            "victory": "pm0007_00_00_00310_appeal01.tranm"
        }
    },
    {
        "id": "pikachu",
        "folder": r"pm0025\pm0025_00_00",
        "trmdl": "pm0025_00_00.trmdl",
        "anims": {
            "idle": "pm0025_00_00_00000_defaultwait01_loop.tranm",
            "battle_idle": "pm0025_00_00_00001_battlewait01_loop.tranm",
            "walk": "pm0025_00_00_00030_walk01_loop.tranm",
            "run": "pm0025_00_00_00100_run01_loop.tranm",
            "attack": "pm0025_00_00_00400_attack01.tranm",
            "attack_special": "pm0025_00_00_00450_rangeattack01.tranm",
            "charge": "pm0025_00_00_00490_charge01_loop.tranm",
            "damage": "pm0025_00_00_00500_damage01.tranm",
            "down": "pm0025_00_00_00520_down01_start.tranm",
            "victory": "pm0025_00_00_00310_appeal01.tranm"
        }
    },
    {
        "id": "eevee",
        "folder": r"pm0133\pm0133_00_00",
        "trmdl": "pm0133_00_00.trmdl",
        "anims": {
            "idle": "pm0133_00_00_00000_defaultwait01_loop.tranm",
            "battle_idle": "pm0133_00_00_00001_battlewait01_loop.tranm",
            "walk": "pm0133_00_00_00030_walk01_loop.tranm",
            "run": "pm0133_00_00_00100_run01_loop.tranm",
            "attack": "pm0133_00_00_00400_attack01.tranm",
            "attack_special": "pm0133_00_00_00450_rangeattack01.tranm",
            "charge": "pm0133_00_00_00490_charge01_loop.tranm",
            "damage": "pm0133_00_00_00500_damage01.tranm",
            "down": "pm0133_00_00_00520_down01_start.tranm",
            "victory": "pm0133_00_00_00310_appeal01.tranm"
        }
    }
]
ONLY = os.environ.get('POKE_ONLY')
for target in TARGETS:
    if ONLY and target['id'] not in [x.strip() for x in ONLY.split(',')]:
        continue
    p_id = target["id"]
    CURRENT_ID = p_id
    print(f"\n==========================================")
    print(f"PROCESSING: {p_id.upper()}")
    print(f"==========================================")
    
    # 1. Clean scene
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for act in list(bpy.data.actions):
        bpy.data.actions.remove(act)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat, do_unlink=True)
    for img in list(bpy.data.images):
        bpy.data.images.remove(img, do_unlink=True)
    
    model_dir = os.path.join(ZA_ROOT if os.path.exists(ZA_ROOT) else r"E:\Arenamon\dumper test\LegendsZAPkmnModelDumpWithDLC", target["folder"])
    trmdl_path = os.path.join(model_dir, target["trmdl"])
    
    # 2. Import TRMDL
    print(f"Loading TRMDL from: {trmdl_path}")
    bpy.ops.import_scene.trmdl(filepath=trmdl_path)
    
    armature = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    
    # 3. Import each animation and rename action
    imported_actions = []
    for anim_label, anim_filename in target["anims"].items():
        anim_path = os.path.join(model_dir, anim_filename)
        if not os.path.exists(anim_path):
            print(f"  [WARN] Animation file not found: {anim_filename}")
            continue
            
        print(f"  Importing [{anim_label}] from {anim_filename}...")
        before_actions = set(bpy.data.actions.keys())
        bpy.ops.import_scene.gfbanm(
            directory=model_dir,
            files=[{"name": anim_filename}],
            nla_import=True
        )
        after_actions = set(bpy.data.actions.keys())
        new_actions = after_actions - before_actions
        
        # Rename new action to clean name
        for act_name in new_actions:
            action = bpy.data.actions[act_name]
            action.name = anim_label
            imported_actions.append(anim_label)
    
    print(f"Total animations imported: {len(imported_actions)} ({', '.join(imported_actions)})")
    
    simplify_materials()

    # 4. Export GLB
    out_dir = os.path.join(OUTPUT_BASE, p_id)
    os.makedirs(out_dir, exist_ok=True)
    out_glb = os.path.join(out_dir, f"{p_id}.glb")
    
    print(f"Exporting GLB to: {out_glb}")
    bpy.ops.export_scene.gltf(
        filepath=out_glb,
        export_format='GLB',
        export_animations=True,
        export_skins=True,
        export_morph=True
    )
    
    size_mb = os.path.getsize(out_glb) / (1024 * 1024)
    print(f"[SUCCESS] {p_id}.glb exported successfully! Size: {size_mb:.2f} MB")

print("\n--- ALL 3 POKEMON EXPORTED SUCCESSFULLY ---")
