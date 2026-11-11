from PIL import Image

main = Image.open('level_up_hud_main_capture.png')
brain = 'C:/Users/zerke/.gemini/antigravity/brain/46602981-5c4d-4b7f-bad5-df456d718436/'

# Let's save zoomed-in crops of all suspicious text areas:
# Area 1: Left column full vertical strip (X: 10 to 450, Y: 40 to 650)
main.crop((10, 40, 450, 650)).save(brain + 'zoom_left_column.png')

# Area 2: Right column full vertical strip (X: 820 to 1270, Y: 40 to 650)
main.crop((820, 40, 1270, 650)).save(brain + 'zoom_right_column.png')

# Area 3: Footer bar (X: 10 to 1270, Y: 650 to 715)
main.crop((10, 650, 1270, 715)).save(brain + 'zoom_footer.png')

# Area 4: Header bar (X: 10 to 1270, Y: 0 to 60)
main.crop((10, 0, 1270, 60)).save(brain + 'zoom_header.png')

print("Zoom crops saved!")
