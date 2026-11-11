from PIL import Image
import numpy as np

img = Image.open('level_up_hud_main_capture.png')
arr = np.array(img)

# In level_up_hud_main_capture.png:
# MovesGrid starts at X=856, Y=100.
# Card 0 ends at Y = 100 + 114 = 214.
# Card 2 starts at Y = 100 + 120 = 220.
# The gap between Card 0 and Card 2 is Y in [215..219], X in [856..1052].
# In this gap, the background color is the RightCol dark background: RGB ~ (13, 24, 36).
# If text was leaking from Card 0 or Card 2 into the gap, there would be text pixels (different from background).

gap = arr[215:220, 870:1040, :3]
bg = np.array([13, 24, 36])
diff = np.abs(gap.astype(int) - bg)
max_diff = np.max(diff, axis=2)

rogue_pixels = np.where(max_diff > 35)
print(f"Rogue text pixels in the gap between Card 0 and Card 2: {len(rogue_pixels[0])}")

# Let's also check between Card 1 and Card 3: X in [1072..1240]
gap1 = arr[215:220, 1072:1240, :3]
diff1 = np.abs(gap1.astype(int) - bg)
max_diff1 = np.max(diff1, axis=2)
rogue_pixels1 = np.where(max_diff1 > 35)
print(f"Rogue text pixels in the gap between Card 1 and Card 3: {len(rogue_pixels1[0])}")

# Let's check the right edge of the screen: X in [1270..1280]
right_strip = arr[:, 1270:1280, :3]
print(f"Right edge shape: {right_strip.shape}")
print(f"Right edge max brightness: {right_strip.max()}")
print("Pixel audit complete!")
