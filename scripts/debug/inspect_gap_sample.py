from PIL import Image
import numpy as np

img = Image.open('level_up_hud_main_capture.png')
arr = np.array(img)

gap = arr[220:224, 870:920, :3]
print("RGB sample at Y=220:")
for x in range(870, 885):
    p = arr[220, x]
    print(f"X={x}: ({p[0]}, {p[1]}, {p[2]})")

print("\nRGB sample at Y=221:")
for x in range(870, 885):
    p = arr[221, x]
    print(f"X={x}: ({p[0]}, {p[1]}, {p[2]})")
