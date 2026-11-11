with open('scripts/ui/level_up_hud.gd', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace NatureData call
text = text.replace(
    'nature_mod = NatureData.get_stat_modifier(hero.nature_id, stat_name)',
    'var nd: Dictionary = NatureData.get_nature(hero.nature_id)\n\t\t\tnature_mod = int(nd.get("mods", {}).get(stat_name, 0))'
)

# Replace CharacterModelLoader.create_model
text = text.replace(
    'var char_node: Node3D = CharacterModelLoader.create_model(species)',
    'var char_node: Node3D = CharacterModelLoader.create_character_model(hero)'
)

# Replace play_victory_jump
old_jump = """\tvar char_node = model_mount.get_child(0) if model_mount.get_child_count() > 0 else null
\tif char_node:
\t\tCharacterModelLoader.play_victory_jump(char_node, 0.55)

\tvar tween = create_tween()"""

new_jump = """\tvar tween = create_tween()
\tvar char_node = model_mount.get_child(0) if model_mount.get_child_count() > 0 else null
\tif char_node:
\t\tCharacterModelLoader.play_victory_jump(char_node, tween)"""

text = text.replace(old_jump, new_jump)

with open('scripts/ui/level_up_hud.gd', 'w', encoding='utf-8') as f:
    f.write(text)

print('Updated level_up_hud.gd successfully')
