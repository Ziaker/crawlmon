from PIL import Image
import numpy as np

img = Image.open('C:/Users/zerke/.gemini/antigravity/brain/46602981-5c4d-4b7f-bad5-df456d718436/zoom_left_column.png')
arr = np.array(img)
w, h = img.size

# Panel borders in LeftCol:
# The panels have black borders (RGB < 15) or dark cyan borders (#203548 = 32, 53, 72)
# Inside the panels, background is light (#f5f6f8 for HeroCard) or dark (#0d1824 for AttributesCard)
# Outside LeftCol, the column background is the window background (#060a10 = 6, 10, 16)

# Let's check for any bright pixels (text) that fall outside the panels on the right side (X > 420)!
# LeftCol is custom_minimum_size = Vector2(420, ...)
# In zoom_left_column (crop from X=10 to 450), X=420 relative to window is X=410 relative to crop!
right_edge = arr[:, 410:, :3]
# Any pixels with brightness > 80?
bright_outside = np.any(right_edge > 80, axis=2)
y_leak, x_leak = np.where(bright_outside)
if len(y_leak) > 0:
    print(f"LEAK FOUND ON RIGHT OF LEFT COLUMN (X > 420):")
    for y in sorted(list(set(y_leak))):
        xs = np.where(bright_outside[y, :])[0] + 410
        print(f"  Y={y} (global Y={y+40}): X=[{xs[0]}..{xs[-1]}]")
else:
    print("No pixels leaking to the right of LeftCol (X > 420)")
