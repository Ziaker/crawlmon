"""
Generates multi-frame VFX flipbook sprite sheets (4x4 = 16 frames, 512x512 RGBA)
and streaked anime slash trail textures in `assets/vfx/`:
  - flipbook_impact.png    (16 frames: spiky anime impact burst + shock ring + shards)
  - flipbook_smoke.png     (16 frames: billowing volumetric dust puff with cel erosion)
  - flipbook_fire.png      (16 frames: erupting flame tongues + swirling fire burst)
  - flipbook_lightning.png (16 frames: branching jagged lightning arcs + plasma sparks)
  - slash_trail_tex.png    (512x128 streaked anime blade/claw trail texture)
"""
import os
import math
import numpy as np
from PIL import Image

OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "vfx"))
os.makedirs(OUT_DIR, exist_ok=True)


def _hash2(x, y, seed=0.0):
    v = np.sin(x * 127.1 + y * 311.7 + seed * 74.7) * 43758.5453
    return v - np.floor(v)


def _vnoise(x, y, seed=0.0):
    ix = np.floor(x)
    iy = np.floor(y)
    fx = x - ix
    fy = y - iy
    ux = fx * fx * (3.0 - 2.0 * fx)
    uy = fy * fy * (3.0 - 2.0 * fy)
    a = _hash2(ix, iy, seed)
    b = _hash2(ix + 1.0, iy, seed)
    c = _hash2(ix, iy + 1.0, seed)
    d = _hash2(ix + 1.0, iy + 1.0, seed)
    return a + (b - a) * ux + (c - a) * uy + (a - b - c + d) * ux * uy


def fbm(x, y, octaves=4, seed=0.0):
    val = np.zeros_like(x)
    amp = 0.5
    freq = 1.0
    for i in range(octaves):
        val += amp * _vnoise(x * freq, y * freq, seed + i * 13.3)
        freq *= 2.05
        amp *= 0.5
    return val


def make_grid(res=128):
    lin = np.linspace(-1.0, 1.0, res, dtype=np.float32)
    y, x = np.meshgrid(lin, lin, indexing="ij")
    r = np.sqrt(x * x + y * y) + 1e-6
    ang = np.arctan2(y, x)
    return x, y, r, ang


def build_impact_flipbook():
    """4x4 (16 frames) anime impact burst: spiky core -> shockwave ring -> flying shards."""
    cell = 128
    sheet = np.zeros((cell * 4, cell * 4, 4), dtype=np.uint8)
    x, y, r, ang = make_grid(cell)

    for idx in range(16):
        t = idx / 15.0
        row, col = divmod(idx, 4)

        # 1. Spiky star rays (strong in early frames)
        ray_freq1 = np.abs(np.cos(ang * 4.0 + 0.3)) ** 14.0
        ray_freq2 = np.abs(np.cos(ang * 8.0 - 0.5)) ** 24.0
        ray_noise = fbm(np.cos(ang) * 3.5, np.sin(ang) * 3.5, 3, seed=2.0)
        spikes = (ray_freq1 * 0.85 + ray_freq2 * 0.55 + (ray_noise ** 3.0) * 0.9)
        spike_reach = 0.35 + 0.65 * (1.0 - (1.0 - t) ** 2.5)
        spike_fade = max(0.0, 1.0 - t * 1.45)
        spike_mask = np.clip((1.0 - r / (spike_reach * (0.45 + 0.65 * spikes) + 1e-4)), 0.0, 1.0) ** 1.4 * spike_fade

        # 2. Expanding jagged shockwave ring
        ring_r = 0.14 + 0.72 * (t ** 0.65)
        ring_w = 0.14 * (1.0 - 0.65 * t)
        angular_jag = (fbm(np.cos(ang) * 4.0, np.sin(ang) * 4.0, 3, seed=7.0 + t * 2.0) - 0.5) * 0.12
        dist_ring = np.abs(r - (ring_r + angular_jag))
        ring_mask = np.clip(1.0 - dist_ring / max(ring_w, 0.02), 0.0, 1.0) ** 1.8
        # Erode ring in late frames into broken arcs
        erosion = fbm(x * 5.0, y * 5.0, 3, seed=11.0)
        ring_mask = np.clip((ring_mask - max(0.0, t - 0.45) * 1.3 * (1.0 - erosion)), 0.0, 1.0)
        ring_mask *= (1.0 - t ** 2.2)

        # 3. Flying radial impact shards
        shard_ang = np.floor((ang + math.pi) / (math.tau / 18.0))
        shard_rand = _hash2(shard_ang, shard_ang * 1.7, 5.0)
        shard_r = (0.18 + 0.76 * (t ** 0.75)) * (0.65 + 0.45 * shard_rand)
        shard_len = 0.14 * (1.0 - t * 0.5)
        in_shard_r = np.clip(1.0 - np.abs(r - shard_r) / max(shard_len, 0.02), 0.0, 1.0)
        in_shard_a = (np.abs(np.cos(ang * 9.0 + shard_rand * 6.0)) ** 30.0)
        shards = in_shard_r * in_shard_a * np.sin(t * math.pi) * 1.3

        # 4. Hot center flash (frames 0..4)
        core = np.exp(-r * r * (14.0 + t * 40.0)) * max(0.0, 1.0 - t * 2.4)

        intensity = np.clip(core * 1.5 + spike_mask * 1.15 + ring_mask * 1.25 + shards, 0.0, 1.0)
        edge_falloff = np.clip((1.0 - r) / 0.08, 0.0, 1.0)
        alpha = intensity * edge_falloff

        # Color: white-hot core, golden-white inner, warm tint outer
        rgb_r = np.clip(intensity * 1.35, 0.0, 1.0)
        rgb_g = np.clip(intensity * 1.15 + core * 0.4, 0.0, 1.0)
        rgb_b = np.clip(intensity * 0.85 + core * 0.6, 0.0, 1.0)

        frame = np.stack([
            (rgb_r * 255).astype(np.uint8),
            (rgb_g * 255).astype(np.uint8),
            (rgb_b * 255).astype(np.uint8),
            (alpha * 255).astype(np.uint8)
        ], axis=-1)
        sheet[row * cell:(row + 1) * cell, col * cell:(col + 1) * cell] = frame

    out_path = os.path.join(OUT_DIR, "flipbook_impact.png")
    Image.fromarray(sheet, "RGBA").save(out_path)
    print("Saved:", out_path)


def build_smoke_flipbook():
    """4x4 (16 frames) stylized anime billowing dust/smoke cloud with cel-shaded lobes & erosion."""
    cell = 128
    sheet = np.zeros((cell * 4, cell * 4, 4), dtype=np.uint8)
    x, y, r, ang = make_grid(cell)

    for idx in range(16):
        t = idx / 15.0
        row, col = divmod(idx, 4)

        rad = 0.28 + 0.56 * (t ** 0.55)
        # Advect noise outward and upward over time
        nx = x / max(rad, 0.15) * 2.2
        ny = (y + t * 0.25) / max(rad, 0.15) * 2.2
        n1 = fbm(nx, ny, 4, seed=3.1)
        n2 = fbm(nx * 1.8 + t * 1.5, ny * 1.8 - t * 1.2, 3, seed=9.4)

        lobe_shape = 1.0 - (r / max(rad, 0.1)) + (n1 - 0.48) * 0.65 + (n2 - 0.5) * 0.35
        # Erode holes as smoke dissipates
        erode_thresh = 0.12 + (t ** 1.45) * 0.72
        alpha = np.clip((lobe_shape - erode_thresh) / 0.18, 0.0, 1.0)
        alpha *= np.clip((1.0 - r) / 0.08, 0.0, 1.0) * (1.0 - (t ** 3.2))

        # Stylized cel lighting (bright top-left rim, warm-gray body, darker underside)
        light_dir = (-x * 0.45 - y * 0.75) / (r + 0.2)
        shade = 0.68 + 0.28 * np.clip(light_dir + (n1 - 0.5) * 0.6, -0.5, 1.0)
        # Quantize slightly for anime cel-smoke look
        shade = np.floor(shade * 4.0) / 4.0 * 0.6 + shade * 0.4
        c = np.clip(shade, 0.35, 1.0)

        frame = np.stack([
            (c * 255).astype(np.uint8),
            (c * 255).astype(np.uint8),
            (c * 255).astype(np.uint8),
            (alpha * 255).astype(np.uint8)
        ], axis=-1)
        sheet[row * cell:(row + 1) * cell, col * cell:(col + 1) * cell] = frame

    out_path = os.path.join(OUT_DIR, "flipbook_smoke.png")
    Image.fromarray(sheet, "RGBA").save(out_path)
    print("Saved:", out_path)


def build_fire_flipbook():
    """4x4 (16 frames) roaring anime flame burst with swirling tongues & embers."""
    cell = 128
    sheet = np.zeros((cell * 4, cell * 4, 4), dtype=np.uint8)
    x, y, r, ang = make_grid(cell)

    for idx in range(16):
        t = idx / 15.0
        row, col = divmod(idx, 4)

        rad = 0.32 + 0.55 * (t ** 0.6)
        swirl = ang + r * (2.2 - t * 1.0) - t * 3.5
        sx = np.cos(swirl) * r * 3.2
        sy = (y + t * 0.65) * 3.4
        flame_n = fbm(sx, sy, 4, seed=15.0)
        tongue = fbm(x * 4.5, y * 4.5 + t * 4.0, 3, seed=21.0)

        density = (1.0 - r / max(rad, 0.12)) + (flame_n - 0.42) * 0.75 + (tongue - 0.5) * 0.4
        erode = 0.08 + (t ** 1.3) * 0.78
        heat = np.clip((density - erode) / 0.32, 0.0, 1.0)
        edge = np.clip((1.0 - r) / 0.08, 0.0, 1.0)
        alpha = np.clip(heat * 1.4, 0.0, 1.0) * edge * (1.0 - t ** 2.6)

        # Fire color ramp: dark crimson outer -> orange mid -> yellow-white hot core
        cr = np.clip(heat * 2.2, 0.0, 1.0)
        cg = np.clip((heat - 0.22) * 1.75, 0.0, 1.0)
        cb = np.clip((heat - 0.62) * 2.5, 0.0, 1.0)

        frame = np.stack([
            (cr * 255).astype(np.uint8),
            (cg * 255).astype(np.uint8),
            (cb * 255).astype(np.uint8),
            (alpha * 255).astype(np.uint8)
        ], axis=-1)
        sheet[row * cell:(row + 1) * cell, col * cell:(col + 1) * cell] = frame

    out_path = os.path.join(OUT_DIR, "flipbook_fire.png")
    Image.fromarray(sheet, "RGBA").save(out_path)
    print("Saved:", out_path)


def build_lightning_flipbook():
    """4x4 (16 frames) jagged branching anime lightning arcs & plasma discharge."""
    cell = 128
    sheet = np.zeros((cell * 4, cell * 4, 4), dtype=np.uint8)
    x, y, r, ang = make_grid(cell)

    for idx in range(16):
        t = idx / 15.0
        row, col = divmod(idx, 4)

        # Jagged high-frequency domain warp for electric bolts
        seed_f = idx * 3.7 + 1.0
        warp1 = fbm(x * 4.5, y * 4.5, 4, seed=seed_f) - 0.5
        warp2 = fbm(x * 8.0 + 2.0, y * 8.0 - 1.5, 3, seed=seed_f + 5.0) - 0.5

        # Multiple radial branching bolt channels
        bolt_uv = np.sin(ang * 5.0 + warp1 * 6.5 + warp2 * 3.2)
        bolt_thin = np.clip(1.0 - np.abs(bolt_uv) / (0.14 * (1.0 - 0.4 * t) + 0.02), 0.0, 1.0) ** 3.0

        # Circular arc ring snapping outward
        arc_r = 0.2 + 0.65 * (t ** 0.6) + warp1 * 0.24
        arc_ring = np.clip(1.0 - np.abs(r - arc_r) / 0.065, 0.0, 1.0) ** 2.2

        reach = np.clip(1.0 - r / (0.45 + 0.5 * (1.0 - abs(t - 0.35))), 0.0, 1.0)
        core = np.exp(-r * r * (18.0 + t * 35.0)) * max(0.0, 1.0 - t * 1.8)

        elec = np.clip((bolt_thin * reach * 1.2 + arc_ring * 1.1 + core * 1.4), 0.0, 1.0)
        elec *= (1.0 - t ** 2.0) * np.clip((1.0 - r) / 0.07, 0.0, 1.0)

        cr = np.clip(elec * 1.25 + core * 0.5, 0.0, 1.0)
        cg = np.clip(elec * 1.2 + core * 0.5, 0.0, 1.0)
        cb = np.clip(elec * 0.75 + (bolt_thin ** 2.0) * 0.6, 0.0, 1.0)

        frame = np.stack([
            (cr * 255).astype(np.uint8),
            (cg * 255).astype(np.uint8),
            (cb * 255).astype(np.uint8),
            (elec * 255).astype(np.uint8)
        ], axis=-1)
        sheet[row * cell:(row + 1) * cell, col * cell:(col + 1) * cell] = frame

    out_path = os.path.join(OUT_DIR, "flipbook_lightning.png")
    Image.fromarray(sheet, "RGBA").save(out_path)
    print("Saved:", out_path)


def build_slash_trail_tex():
    """512x128 anime sword/claw slash texture with razor streaks, serrated edge & hot tip."""
    w, h = 512, 128
    u = np.linspace(0.0, 1.0, w, dtype=np.float32)
    v = np.linspace(0.0, 1.0, h, dtype=np.float32)
    vv, uu = np.meshgrid(v, u, indexing="ij")

    # Outer blade edge (v near 0.85) is razor-sharp; inner edge (v near 0.15) has speed streaks
    blade_profile = np.exp(-((vv - 0.68) / 0.16) ** 2.0)
    inner_streaks = (
        np.exp(-((vv - 0.36) / 0.035) ** 2.0) * 0.75
        + np.exp(-((vv - 0.22) / 0.022) ** 2.0) * 0.55
        + np.exp(-((vv - 0.50) / 0.028) ** 2.0) * 0.65
    )

    # High-speed longitudinal streaks & serrated tail erosion
    streak_n = fbm(uu * 6.0, vv * 28.0, 4, seed=42.0)
    tail_taper = (np.clip(np.sin(uu * math.pi), 0.0, 1.0) ** 0.55) * np.clip((1.0 - (1.0 - uu) ** 2.8), 0.0, 1.0)
    head_flare = np.exp(-((uu - 0.82) / 0.12) ** 2.0) * np.exp(-((vv - 0.65) / 0.22) ** 2.0)

    raw = (blade_profile * (0.7 + 0.5 * streak_n) + inner_streaks * (np.clip(streak_n, 0.0, 1.0) ** 1.5)) * tail_taper + head_flare * 0.9
    # Edge cleanup so v=0 and v=1 are 0 alpha
    v_fade = np.clip(np.sin(vv * math.pi), 0.0, 1.0) ** 0.7
    intensity = np.clip(raw * v_fade * 1.35, 0.0, 1.0)

    # Store intensity in RGB and alpha for versatile shader tinting
    core = np.clip((intensity - 0.45) / 0.55, 0.0, 1.0)
    rgb = np.clip(intensity * 0.85 + core * 0.5, 0.0, 1.0)
    img = np.stack([
        (rgb * 255).astype(np.uint8),
        (rgb * 255).astype(np.uint8),
        (rgb * 255).astype(np.uint8),
        (intensity * 255).astype(np.uint8)
    ], axis=-1)

    out_path = os.path.join(OUT_DIR, "slash_trail_tex.png")
    Image.fromarray(img, "RGBA").save(out_path)
    print("Saved:", out_path)


if __name__ == "__main__":
    build_impact_flipbook()
    build_smoke_flipbook()
    build_fire_flipbook()
    build_lightning_flipbook()
    build_slash_trail_tex()
