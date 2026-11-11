from PIL import Image

modal = Image.open('level_up_hud_modal_capture.png')
brain = 'C:/Users/zerke/.gemini/antigravity/brain/46602981-5c4d-4b7f-bad5-df456d718436/'

# Modal is centered, size ~940x520. In 1280x720, that's X=170..1110, Y=100..620
modal.crop((160, 90, 1120, 630)).save(brain + 'modal_full_new.png')
# Block 1:
modal.crop((190, 180, 640, 560)).save(brain + 'modal_block1_new.png')
# Block 2:
modal.crop((640, 180, 1090, 560)).save(brain + 'modal_block2_new.png')

print("Cropped modal")
