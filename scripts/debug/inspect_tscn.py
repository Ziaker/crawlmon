with open('scenes/ui/level_up_hud.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

import re

# Find top level nodes and custom minimum sizes
lines = text.split('\n')
for line in lines:
    if line.startswith('[node name=') or 'custom_minimum_size' in line or 'layout_mode' in line:
        if any(k in line for k in ['HeaderBar', 'ContentArea', 'LeftCol', 'CenterCol', 'RightCol', 'FooterBar', 'HeroCard', 'AffinitiesCard', 'AttributesCard', 'AdvanceLockNotice', 'MovesGrid', 'LootPanel', 'custom_minimum_size']):
            print(line)
