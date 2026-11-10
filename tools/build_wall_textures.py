import os
import cv2
import numpy as np


S = 1024
OUT = "assets/textures/walls"
TAU = np.pi * 2.0
os.makedirs(OUT, exist_ok=True)


def noise(seed, cutoff):
    rng = np.random.default_rng(seed)
    n = rng.standard_normal((S, S))
    f = np.fft.fft2(n)
    fy = np.fft.fftfreq(S)[:, None]
    fx = np.fft.fftfreq(S)[None, :]
    mask = np.exp(-(fx * fx + fy * fy) / (2.0 * cutoff * cutoff))
    out = np.real(np.fft.ifft2(f * mask))
    out -= out.min()
    m = out.max()
    return out / m if m > 1e-9 else out


def fbm(seed, layers):
    acc = np.zeros((S, S), np.float32)
    wsum = 0.0
    for i, (cut, w) in enumerate(layers):
        acc += noise(seed + i * 17, cut) * w
        wsum += w
    return acc / wsum


def smooth(t):
    t = np.clip(t, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def mix(a, b, t):
    t = t[:, :, None] if t.ndim == 2 else t
    return a * (1.0 - t) + b * t


def color(rgb):
    return np.array(rgb, np.float32)


def save(name, rgb):
    img = (np.clip(rgb, 0.0, 1.0) * 255.0).astype(np.uint8)
    cv2.imwrite(os.path.join(OUT, name), cv2.cvtColor(img, cv2.COLOR_RGB2BGR))


def wrap_line(mask, p0, p1, thickness, value=255):
    for ox in (-S, 0, S):
        for oy in (-S, 0, S):
            a = (int(p0[0]) + ox, int(p0[1]) + oy)
            b = (int(p1[0]) + ox, int(p1[1]) + oy)
            cv2.line(mask, a, b, value, thickness, cv2.LINE_AA)


def wrap_ellipse(img, cx, cy, rx, ry, col, fill=True, thickness=1):
    for ox in (-S, 0, S):
        for oy in (-S, 0, S):
            cv2.ellipse(img, (int(cx) + ox, int(cy) + oy), (int(rx), int(ry)),
                        0, 0, 360, col, -1 if fill else thickness, cv2.LINE_AA)


yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)


# 1) Blocos de pedra com musgo.
def mossy_stone():
    base = color((0.105, 0.155, 0.145))
    light = color((0.225, 0.300, 0.275))
    dark = color((0.045, 0.075, 0.070))
    moss = color((0.205, 0.340, 0.165))
    moss_l = color((0.330, 0.490, 0.235))

    n = fbm(101, [(0.006, 0.55), (0.018, 0.30), (0.055, 0.15)])
    jx = (noise(102, 0.012) - 0.5) * 22.0
    jy = (noise(103, 0.012) - 0.5) * 22.0

    rows, cols = 6, 5
    rh, cw = S / rows, S / cols
    ry = (yy + jy) % S
    rx = (xx + jx) % S
    row = np.floor(ry / rh).astype(np.int32) % rows
    off = (row % 2) * 0.5
    col = np.floor(rx / cw + off).astype(np.int32) % cols
    ly = (ry % rh) / rh
    lx = (rx % cw) / cw

    mortar = (ly < 0.055) | (ly > 0.945) | (lx < 0.045) | (lx > 0.955)
    edge = np.minimum(np.minimum(lx, 1 - lx), np.minimum(ly, 1 - ly))
    bevel = smooth(edge / 0.16)
    bottom = smooth((ly - 0.80) / 0.20)
    right = smooth((lx - 0.86) / 0.14)
    tint = (row * 7 + col * 13) % 4
    block = base + (light - base) * (0.25 + 0.45 * n[:, :, None])
    shade = 0.84 + 0.26 * bevel - 0.14 * bottom - 0.08 * right
    block *= shade[:, :, None]
    for k in range(4):
        block[tint == k] *= (0.92 + k * 0.045)
    block[mortar] = dark * (0.7 + 0.5 * n[mortar, None])

    m = smooth((fbm(104, [(0.012, 0.6), (0.05, 0.4)]) - 0.50) / 0.18)
    m *= (0.35 + 0.65 * mortar.astype(np.float32))
    block = mix(block, moss, m * 0.85)
    m2 = smooth((fbm(105, [(0.03, 0.7), (0.11, 0.3)]) - 0.58) / 0.16)
    block = mix(block, moss_l, m2 * 0.55)
    rng = np.random.default_rng(106)
    for _ in range(60):
        x, y = rng.integers(8, S - 8), rng.integers(8, S - 8)
        cv2.circle(block, (int(x), int(y)), int(rng.integers(1, 3)),
                   (0.30, 0.16, 0.34), -1)
    save("murky_wall_mossy_stone.png", block)


# 2) Casca e raízes verticais.
def bark_roots():
    dark = color((0.115, 0.088, 0.062))
    mid = color((0.250, 0.190, 0.125))
    light = color((0.390, 0.300, 0.190))
    moss = color((0.190, 0.315, 0.140))

    warp = (fbm(201, [(0.008, 0.7), (0.025, 0.3)]) - 0.5) * 125.0
    xw = (xx + warp + 16.0 * np.sin(TAU * yy / S * 3.0)) % S
    bands = 11
    b = xw / (S / bands)
    frac = b % 1.0
    ridge = 0.5 + 0.5 * np.cos(TAU * frac)
    grain = noise(202, 0.12)
    c = mix(dark, mid, (0.35 + 0.55 * ridge)[:, :, None])
    c = mix(c, light, np.clip(ridge * 0.35 + grain * 0.12, 0.0, 1.0)[:, :, None])
    crack = (frac < 0.05) | (frac > 0.95)
    c[crack] = dark * 0.55

    roots = np.zeros((S, S), np.uint8)
    rng = np.random.default_rng(203)
    for _ in range(6):
        x0 = rng.uniform(0, S)
        amp = rng.uniform(30, 90)
        ph = rng.uniform(0, TAU)
        pts = []
        for y in range(-32, S + 32, 24):
            pts.append((x0 + amp * np.sin(TAU * y / S * 2 + ph), y))
        for i in range(len(pts) - 1):
            wrap_line(roots, pts[i], pts[i + 1], int(rng.integers(7, 13)))
    rc = roots.astype(np.float32) / 255.0
    c = mix(c, dark * 0.82, rc * 0.78)

    m = smooth((fbm(204, [(0.02, 0.7), (0.07, 0.3)]) - 0.55) / 0.17)
    c = mix(c, moss, m * 0.55)
    rng = np.random.default_rng(205)
    for _ in range(26):
        x, y = rng.integers(0, S), rng.integers(0, S)
        wrap_ellipse(c, x, y, rng.integers(3, 8), rng.integers(4, 10), (0.34, 0.24, 0.15))
        wrap_ellipse(c, x, y, rng.integers(2, 5), rng.integers(3, 7), (0.08, 0.06, 0.04), False)
    save("murky_wall_bark_roots.png", c)


# 3) Micélio/fungo orgânico.
def mycelium():
    base = color((0.085, 0.160, 0.145))
    pale = color((0.420, 0.620, 0.480))
    purple = color((0.250, 0.140, 0.330))
    dark = color((0.045, 0.085, 0.080))

    rng = np.random.default_rng(301)
    seeds = rng.random((26, 2)) * S
    d1 = np.full((S, S), 1e9, np.float32)
    d2 = np.full((S, S), 1e9, np.float32)
    idx = np.zeros((S, S), np.int32)
    for i, (sx, sy) in enumerate(seeds):
        dx = np.abs(xx - sx)
        dy = np.abs(yy - sy)
        dx = np.minimum(dx, S - dx)
        dy = np.minimum(dy, S - dy)
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < d1
        d2 = np.where(closer, d1, np.minimum(d2, d))
        idx = np.where(closer, i, idx)
        d1 = np.where(closer, d, d1)

    border = np.exp(-((d2 - d1) / 7.0) ** 2)
    n = fbm(302, [(0.012, 0.55), (0.045, 0.30), (0.12, 0.15)])
    c = base + (color((0.18, 0.30, 0.27)) - base) * (0.25 + 0.6 * n[:, :, None])
    c = mix(c, pale, border * 0.85)
    cells = (idx % 3).astype(np.float32) / 2.0
    c *= (0.88 + 0.24 * cells[:, :, None])
    p = smooth((fbm(303, [(0.02, 0.6), (0.08, 0.4)]) - 0.60) / 0.14)
    c = mix(c, purple, p * 0.7)
    c = mix(c, dark, border * 0.20)
    for _ in range(90):
        x, y = rng.integers(0, S), rng.integers(0, S)
        wrap_ellipse(c, x, y, rng.integers(1, 4), rng.integers(1, 4), (0.62, 0.78, 0.64))
    save("murky_wall_mycelium.png", c)


# 4) Ardósia rachada com musgo.
def slate_cracks():
    base = color((0.100, 0.158, 0.158))
    light = color((0.235, 0.315, 0.305))
    dark = color((0.038, 0.062, 0.064))
    moss = color((0.150, 0.250, 0.115))

    rng = np.random.default_rng(401)
    seeds = rng.random((18, 2)) * S
    d1 = np.full((S, S), 1e9, np.float32)
    d2 = np.full((S, S), 1e9, np.float32)
    idx = np.zeros((S, S), np.int32)
    for i, (sx, sy) in enumerate(seeds):
        dx = np.abs(xx - sx)
        dy = np.abs(yy - sy)
        dx = np.minimum(dx, S - dx)
        dy = np.minimum(dy, S - dy)
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < d1
        d2 = np.where(closer, d1, np.minimum(d2, d))
        idx = np.where(closer, i, idx)
        d1 = np.where(closer, d, d1)

    edge = np.maximum((d2 - d1) * 0.5, 0.0)
    fissure = smooth(1.0 - edge / 5.0)
    bevel = smooth(1.0 - np.clip(edge / 26.0, 0.0, 1.0))
    n = fbm(402, [(0.008, 0.55), (0.035, 0.30), (0.12, 0.15)])
    facets = np.floor(n * 5.0) / 5.0

    c = base + (light - base) * (0.22 + 0.50 * n[:, :, None])
    cells = (idx % 4).astype(np.float32) / 3.0
    c *= (0.86 + 0.26 * cells[:, :, None])
    c *= (0.94 + 0.10 * facets[:, :, None])
    c = mix(c, light, (bevel * 0.18)[:, :, None])
    c = mix(c, dark, fissure * 0.95)

    cracks = np.zeros((S, S), np.uint8)
    for _ in range(11):
        x, y = rng.uniform(0, S), rng.uniform(0, S)
        for _ in range(int(rng.integers(2, 5))):
            nx = x + rng.uniform(-240, 240)
            ny = y + rng.uniform(-240, 240)
            wrap_line(cracks, (x, y), (nx, ny), int(rng.integers(2, 5)))
            x, y = nx, ny
    cm = cracks.astype(np.float32) / 255.0
    c = mix(c, dark, cm * 0.92)
    c = mix(c, light, np.clip(cv2.GaussianBlur(cm, (0, 0), 1.2) - cm, 0.0, 1.0)[:, :, None] * 0.45)

    moss_m = np.clip(cv2.GaussianBlur(cm, (0, 0), 4.0) * 2.0, 0.0, 1.0)
    moss_m *= smooth((fbm(403, [(0.02, 0.6), (0.08, 0.4)]) - 0.48) / 0.22)
    moss_m += fissure * 0.35 * smooth((fbm(404, [(0.03, 0.7), (0.1, 0.3)]) - 0.52) / 0.2)
    c = mix(c, moss, np.clip(moss_m, 0.0, 1.0) * 0.72)

    veins = np.zeros((S, S), np.uint8)
    for _ in range(6):
        x, y = rng.uniform(0, S), rng.uniform(0, S)
        for _ in range(int(rng.integers(2, 6))):
            nx = x + rng.uniform(-160, 160)
            ny = y + rng.uniform(-160, 160)
            wrap_line(veins, (x, y), (nx, ny), 1)
            x, y = nx, ny
    c = mix(c, light, (veins.astype(np.float32) / 255.0) * 0.18)
    save("murky_wall_slate_cracks.png", c)


# 5) Paliçada de raízes e tábuas.
def root_palisade():
    dark = color((0.075, 0.062, 0.045))
    mid = color((0.205, 0.160, 0.100))
    light = color((0.335, 0.270, 0.175))
    moss = color((0.150, 0.265, 0.110))
    green = color((0.075, 0.160, 0.065))
    rope = color((0.105, 0.115, 0.055))
    rope_l = color((0.245, 0.250, 0.120))

    warp = (fbm(501, [(0.008, 0.7), (0.025, 0.3)]) - 0.5) * 70.0
    b = ((xx + warp) % S) / S

    rng = np.random.default_rng(500)
    widths = rng.uniform(0.10, 0.165, 8)
    widths /= widths.sum()
    bounds = np.concatenate([[0.0], np.cumsum(widths)])
    pid = np.clip(np.searchsorted(bounds, b, side="right") - 1, 0, len(widths) - 1)
    start = bounds[pid]
    frac = np.clip((b - start) / widths[pid], 0.0, 1.0)

    phase = rng.uniform(0.0, TAU, len(widths))[pid]
    grain = 0.5 + 0.5 * np.sin(TAU * (yy / S * 4.0 + noise(502, 0.03) * 1.6) + phase)
    grain2 = noise(503, 0.14)
    c = mix(dark, mid, (0.28 + 0.58 * grain)[:, :, None])
    c = mix(c, light, np.clip(grain * 0.28 + grain2 * 0.11, 0.0, 1.0)[:, :, None])

    edge = np.minimum(frac, 1.0 - frac)
    bevel = smooth(edge / 0.10)
    left_edge = smooth((0.075 - frac) / 0.075)
    right_shadow = smooth((frac - 0.90) / 0.10)
    c *= (0.80 + 0.32 * bevel - 0.20 * right_shadow + 0.12 * left_edge)[:, :, None]
    gap = (frac < 0.030) | (frac > 0.970)
    c[gap] = dark * 0.50

    for _ in range(20):
        x, y = rng.uniform(0, S), rng.uniform(0, S)
        wrap_ellipse(c, x, y, rng.integers(4, 10), rng.integers(7, 16), (0.09, 0.07, 0.045))
        wrap_ellipse(c, x, y, rng.integers(3, 7), rng.integers(5, 12), (0.31, 0.25, 0.16), False)

    # Amarrações horizontais de cipó, para ler como paliçada construída.
    ropes = np.zeros((S, S), np.uint8)
    ropes_l = np.zeros((S, S), np.uint8)
    for k, y0 in enumerate((0.24, 0.56, 0.86)):
        ph = rng.uniform(0.0, TAU)
        pts = []
        for x in range(-64, S + 65, 32):
            y = y0 * S + 13.0 * np.sin(TAU * x / S * 2.0 + ph) + 5.0 * np.sin(TAU * x / S * 5.0 + ph * 2.0)
            pts.append((x, y))
        for i in range(len(pts) - 1):
            wrap_line(ropes, pts[i], pts[i + 1], 8)
            wrap_line(ropes_l, (pts[i][0], pts[i][1] - 2), (pts[i + 1][0], pts[i + 1][1] - 2), 2)
        for _ in range(10):
            lx = rng.uniform(0, S)
            ly = y0 * S + 13.0 * np.sin(TAU * lx / S * 2.0 + ph) + 5.0 * np.sin(TAU * lx / S * 5.0 + ph * 2.0)
            wrap_ellipse(c, lx, ly + rng.uniform(-8, 8), rng.integers(4, 8), rng.integers(2, 4),
                         (0.12, 0.22, 0.08))
    c = mix(c, rope, (ropes.astype(np.float32) / 255.0) * 0.80)
    c = mix(c, rope_l, (ropes_l.astype(np.float32) / 255.0) * 0.45)

    m = smooth((fbm(505, [(0.02, 0.7), (0.07, 0.3)]) - 0.52) / 0.18)
    c = mix(c, moss, m * 0.55)
    moss_gap = np.clip(cv2.GaussianBlur(gap.astype(np.float32), (0, 0), 5.0) * 2.2, 0.0, 1.0)
    c = mix(c, moss, moss_gap * 0.45)
    save("murky_wall_root_palisade.png", c)


mossy_stone()
bark_roots()
mycelium()
slate_cracks()
root_palisade()
print("OK: 5 wall textures in", OUT)
