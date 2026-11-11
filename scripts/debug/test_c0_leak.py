from PIL import Image
import numpy as np

# Let's inspect where text appears in full_right_col.png
img = Image.open('C:/Users/zerke/.gemini/antigravity/brain/46602981-5c4d-4b7f-bad5-df456d718436/full_right_col.png')
w, h = img.size
print("full_right_col size:", w, h)
arr = np.array(img)

# In full_right_col, the container panel is a SlantedPanel with bg_color #0d1824 = (13, 24, 36).
# The cards are inside it.
# Card 0, 1, 2, 3 have bright colored backgrounds:
# Card 0 (Tackle): Neutral gray (#cbd5e1 = 203, 213, 225)
# Card 1 (Confusion): Psychic pink (#ec4899 = 236, 72, 153)
# Card 2 (Psybeam): Psychic pink (#ec4899)
# Card 3 (Shock Wave): Electric yellow (#fde047 = 253, 224, 71)

# Card 4, 5, 6, 7 are empty slots: dark slate bg_color = (11, 19, 29)
# Where is text overflowing?
# Look at Card 0 (Tackle) bottom edge:
# The background of Card 0 is light gray. Where does the light gray end vertically?
card0_mask = (arr[:, :200, 0] > 180) & (arr[:, :200, 1] > 190) & (arr[:, :200, 2] > 200)
c0_y, c0_x = np.where(card0_mask)
print(f"Card 0 background Y: [{c0_y.min()}..{c0_y.max()}], X: [{c0_x.min()}..{c0_x.max()}]")

# Now where is the text of Card 0?
# Text is dark (#334155 = ~50, 65, 85)
# Check for text pixels around the bottom of Card 0 and below c0_y.max():
sub = arr[c0_y.max()-10:c0_y.max()+25, :200, :3]
# Below Card 0 is #0d1824 = (13, 24, 36)
# If there are pixels with brightness > 40 below c0_y.max():
for dy in range(sub.shape[0]):
    y_actual = c0_y.max() - 10 + dy
    row = sub[dy]
    # text on dark bg will have color noticeably different from (13, 24, 36)
    diff = np.abs(row - np.array([13, 24, 36])).sum(axis=1)
    bright_txt = np.where(diff > 35)[0]
    if y_actual > c0_y.max() and len(bright_txt) > 0:
        print(f"  Y={y_actual} (BELOW CARD 0 by {y_actual - c0_y.max()}px): {len(bright_txt)} text pixels! X=[{bright_txt.min()}..{bright_txt.max()}]")
