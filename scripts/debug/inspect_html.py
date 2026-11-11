with open('prototypes/hud_post_combat.html', 'r', encoding='utf-8') as f:
    text = f.read()

pos = text.find("Empty Slot")
if pos != -1:
    print(text[pos-200:pos+1000])
