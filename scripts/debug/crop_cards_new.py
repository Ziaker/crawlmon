from PIL import Image

main = Image.open('level_up_hud_main_capture.png')
brain = 'C:/Users/zerke/.gemini/antigravity/brain/46602981-5c4d-4b7f-bad5-df456d718436/'

# In level_up_hud_main_capture.png (1280x720):
# Right column starts around X = 836, width 444.
# VBox inside RightCol has margin_left = 20, margin_top = 8.
# So MovesGrid is around X = 836 + 20 = 856.
# HeaderBox takes ~48px.
# MovesGrid starts at Y = 46 (header) + 8 (margin) + 48 (title) = 102.
# Card 0 (Tackle): X=856..1052, Y=102..216
# Card 1 (Confusion): X=1062..1258, Y=102..216
# Card 2 (Psybeam): X=856..1052, Y=222..336
# Card 3 (Shock Wave): X=1062..1258, Y=222..336
# Modal: centered at X=170..1110, Y=100..620

main.crop((850, 95, 1055, 225)).save(brain + 'card0_tackle_new.png')
main.crop((1055, 95, 1265, 225)).save(brain + 'card1_confusion_new.png')
main.crop((850, 215, 1055, 345)).save(brain + 'card2_psybeam_new.png')
main.crop((1055, 215, 1265, 345)).save(brain + 'card3_shockwave_new.png')

print("Cropped cards 0, 1, 2, 3")
