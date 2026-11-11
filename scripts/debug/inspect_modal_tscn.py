with open('scenes/ui/components/move_inspection_modal.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

import re
pos = text.find('ModalCard')
print(text[pos:pos+2000])
