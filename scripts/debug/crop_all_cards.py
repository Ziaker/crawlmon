from PIL import Image

right = Image.open('C:/Users/zerke/.gemini/antigravity/brain/46602981-5c4d-4b7f-bad5-df456d718436/full_right_col.png')
brain = 'C:/Users/zerke/.gemini/antigravity/brain/46602981-5c4d-4b7f-bad5-df456d718436/'

# In full_right_col.png:
# MovesGrid pos is (0, 48) relative to VBox.
# VBox pos is (20, 8).
# So MovesGrid starts at Y = 8 + 48 = 56 in full_right_col.png!
# Card 0 (Tackle): X=20 to 216, Y=56 to 150
# Card 1 (Confusion): X=222 to 418, Y=56 to 150
# Card 2 (Psybeam): X=20 to 216, Y=156 to 250
# Card 3 (Shock Wave): X=222 to 418, Y=156 to 250
# Card 4 (Empty 5): X=20 to 216, Y=256 to 350
# Card 5 (Empty 6): X=222 to 418, Y=256 to 350
# Card 6 (Empty 7): X=20 to 216, Y=356 to 450
# Card 7 (Empty 8): X=222 to 418, Y=356 to 450
# LootPanel: Y=460 to 520

right.crop((10, 50, 220, 160)).save(brain + 'card_0_tackle.png')
right.crop((215, 50, 435, 160)).save(brain + 'card_1_confusion.png')
right.crop((10, 150, 220, 260)).save(brain + 'card_2_psybeam.png')
right.crop((215, 150, 435, 260)).save(brain + 'card_3_shockwave.png')
right.crop((10, 250, 220, 360)).save(brain + 'card_4_empty5.png')
right.crop((10, 450, 435, 550)).save(brain + 'loot_panel.png')

print("Saved card_0_tackle.png, card_1_confusion.png, card_2_psybeam.png, card_3_shockwave.png, loot_panel.png")
