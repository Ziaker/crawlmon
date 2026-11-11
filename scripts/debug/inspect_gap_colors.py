from PIL import Image
import numpy as np

img = Image.open('level_up_hud_main_capture.png')
arr = np.array(img)

# Let's inspect rows 210 to 225 around X=900
for y in range(210, 225):
    p = arr[y, 900]
    print(f"Y={y}: RGB=({p[0]}, {p[1]}, {p[2]})")
