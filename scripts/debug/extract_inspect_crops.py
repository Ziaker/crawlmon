import os
from PIL import Image
import numpy as np

main = Image.open('level_up_hud_main_capture.png')
modal = Image.open('level_up_hud_modal_capture.png')
w, h = main.size

# Let's save focused subcrops to investigate every single panel!
brain = 'C:/Users/zerke/.gemini/antigravity/brain/46602981-5c4d-4b7f-bad5-df456d718436/'

# 1. AdvanceLockNotice
# From inspect_left_col.gd: LeftCol pos=(10, 40), AdvanceLockNotice pos=(0, 531), size=(420, 32).
# Global pos: X=10 to 430, Y=571 to 603.
main.crop((0, 550, 460, 620)).save(brain + 'inspect_lock_notice.png')

# 2. HeroCard bottom (HP / MP gauges and hints)
# Global pos: X=10 to 430, Y=140 to 240.
main.crop((0, 140, 460, 240)).save(brain + 'inspect_hero_gauges.png')

# 3. AttributesCard title and subtitle
main.crop((0, 240, 460, 320)).save(brain + 'inspect_attr_header.png')

# 4. AttributesCard bottom (Allocation button & Reset)
main.crop((0, 500, 460, 560)).save(brain + 'inspect_attr_footer.png')

# 5. Move cards (each of the 8 cards)
# Grid pos: X=820 to 1270, Y=100 to 550
main.crop((820, 90, 1040, 200)).save(brain + 'inspect_card_0.png')
main.crop((1040, 90, 1260, 200)).save(brain + 'inspect_card_1.png')
main.crop((820, 200, 1040, 310)).save(brain + 'inspect_card_2.png')
main.crop((1040, 200, 1260, 310)).save(brain + 'inspect_card_3.png')
main.crop((820, 310, 1040, 420)).save(brain + 'inspect_card_4.png')
main.crop((820, 420, 1040, 530)).save(brain + 'inspect_card_6.png')

# 6. Modal Block 1 & Block 2
modal.crop((140, 180, 640, 600)).save(brain + 'inspect_modal_b1.png')
modal.crop((640, 180, 1140, 600)).save(brain + 'inspect_modal_b2.png')

print("Saved all inspection crops!")
