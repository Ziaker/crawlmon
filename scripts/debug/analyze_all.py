from PIL import Image
import numpy as np

brain = 'C:/Users/zerke/.gemini/antigravity/brain/46602981-5c4d-4b7f-bad5-df456d718436/'

def analyze_crop(filename, desc):
    img = Image.open(brain + filename)
    arr = np.array(img)
    print(f"\n--- {desc} ({filename}, {img.size}) ---")
    # Check for text outside panel
    # In Godot UI, the dark background is #060a10 (around 6, 10, 16)
    # If text is rendered directly on this dark background outside any panel,
    # it indicates text leaking out of its container!

analyze_crop('inspect_lock_notice.png', 'AdvanceLockNotice')
analyze_crop('inspect_hero_gauges.png', 'Hero Gauges & Formula Hints')
analyze_crop('inspect_attr_header.png', 'Attributes Header')
analyze_crop('inspect_attr_footer.png', 'Attributes Footer & Alloc Button')
analyze_crop('inspect_card_0.png', 'Move Card 0 (Tackle)')
analyze_crop('inspect_card_2.png', 'Move Card 2 (Psybeam)')
analyze_crop('inspect_card_4.png', 'Move Card 4 (Empty Slot 5)')
analyze_crop('inspect_modal_b1.png', 'Modal Block 1 (Mechanics)')
analyze_crop('inspect_modal_b2.png', 'Modal Block 2 (Visual Effects)')
