with open('scripts/debug/gen_hud.py', 'r', encoding='utf-8') as f:
    text = f.read()

pos = text.find('[node name="STR"')
print(text[pos:pos+1500])
