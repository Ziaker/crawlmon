with open('prototypes/hud_post_combat.html', 'r', encoding='utf-8') as f:
    text = f.read()

pos = text.find('const ELEMENTS_12')
print(text[pos:pos+1500])
