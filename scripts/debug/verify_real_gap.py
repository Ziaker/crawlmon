from PIL import Image
import numpy as np

img = Image.open('level_up_hud_main_capture.png')
arr = np.array(img)

# Card 0 ends at Y=219 with border.
# Card 2 starts around Y=225.
# Let's check Y=220..223 across X=870..1040:
gap_actual = arr[220:224, 870:1040, :3]
gap_bg = np.array([6, 10, 16])
diff = np.abs(gap_actual.astype(int) - gap_bg)
max_diff = np.max(diff, axis=2)

rogue_pixels = np.where(max_diff > 10)
print(f"ACTUAL rogue text pixels in gap between Card 0 and Card 2 (Y in 220..223): {len(rogue_pixels[0])}")

# Let's check the gap between Card 1 and Card 3 (Y in 220..223, X in 1072..1240):
gap1_actual = arr[220:224, 1072:1240, :3]
diff1 = np.abs(gap1_actual.astype(int) - gap_bg)
max_diff1 = np.max(diff1, axis=2)
rogue_pixels1 = np.where(max_diff1 > 10)
print(f"ACTUAL rogue text pixels in gap between Card 1 and Card 3 (Y in 220..223): {len(rogue_pixels1[0])}")
