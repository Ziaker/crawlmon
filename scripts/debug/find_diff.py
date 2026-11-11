from PIL import Image
import numpy as np

img = Image.open('level_up_hud_main_capture.png')
arr = np.array(img)

gap_actual = arr[220:224, 870:1040, :3]
gap_bg = np.array([6, 10, 16])
diff = np.abs(gap_actual.astype(int) - gap_bg)
max_diff = np.max(diff, axis=2)

ys, xs = np.where(max_diff > 10)
for i in range(min(15, len(ys))):
    y = ys[i] + 220
    x = xs[i] + 870
    p = arr[y, x]
    print(f"Y={y}, X={x}: ({p[0]}, {p[1]}, {p[2]})")
