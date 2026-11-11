from PIL import Image

main = Image.open('level_up_hud_main_capture.png')
brain = 'C:/Users/zerke/.gemini/antigravity/brain/46602981-5c4d-4b7f-bad5-df456d718436/'

# In level_up_hud_main_capture.png (1280x720):
# RightCol is around X=820 to 1260
# Let's save the entire RightCol:
right_col = main.crop((820, 40, 1260, 660))
right_col.save(brain + 'full_right_col.png')

# LeftCol is around X=20 to 450
left_col = main.crop((20, 40, 450, 660))
left_col.save(brain + 'full_left_col.png')

print("Saved full_right_col.png and full_left_col.png")
