with open("scenes/ui/components/move_card.tscn", "r", encoding="utf-8") as f:
    text = f.read()

# MarginContainer margins
text = text.replace(
    'theme_override_constants/margin_left = 8\ntheme_override_constants/margin_top = 6\ntheme_override_constants/margin_right = 8\ntheme_override_constants/margin_bottom = 6',
    'theme_override_constants/margin_left = 16\ntheme_override_constants/margin_top = 6\ntheme_override_constants/margin_right = 16\ntheme_override_constants/margin_bottom = 6'
)

# Badges and Chips separations
text = text.replace(
    '[node name="BadgesRow" type="HBoxContainer" parent="ContentMargin/VBox/TopRow"]\nlayout_mode = 2\ntheme_override_constants/separation = 4',
    '[node name="BadgesRow" type="HBoxContainer" parent="ContentMargin/VBox/TopRow"]\nlayout_mode = 2\ntheme_override_constants/separation = 3'
)
text = text.replace(
    '[node name="ChipsRow" type="HBoxContainer" parent="ContentMargin/VBox/TopRow"]\nlayout_mode = 2\ntheme_override_constants/separation = 4',
    '[node name="ChipsRow" type="HBoxContainer" parent="ContentMargin/VBox/TopRow"]\nlayout_mode = 2\ntheme_override_constants/separation = 3'
)

# Chips sizes
text = text.replace(
    '[node name="AtbChip" type="PanelContainer" parent="ContentMargin/VBox/TopRow/ChipsRow"]\ncustom_minimum_size = Vector2(40, 17)',
    '[node name="AtbChip" type="PanelContainer" parent="ContentMargin/VBox/TopRow/ChipsRow"]\ncustom_minimum_size = Vector2(36, 16)'
)
text = text.replace(
    '[node name="MpChip" type="PanelContainer" parent="ContentMargin/VBox/TopRow/ChipsRow"]\ncustom_minimum_size = Vector2(40, 17)',
    '[node name="MpChip" type="PanelContainer" parent="ContentMargin/VBox/TopRow/ChipsRow"]\ncustom_minimum_size = Vector2(36, 16)'
)
text = text.replace(
    '[node name="DmgChip" type="PanelContainer" parent="ContentMargin/VBox/TopRow/ChipsRow"]\ncustom_minimum_size = Vector2(48, 17)',
    '[node name="DmgChip" type="PanelContainer" parent="ContentMargin/VBox/TopRow/ChipsRow"]\ncustom_minimum_size = Vector2(42, 16)'
)

# TitleLabel font size
text = text.replace(
    '[node name="TitleLabel" type="Label" parent="ContentMargin/VBox"]\nlayout_mode = 2\nmouse_filter = 2\ntheme_override_fonts/font = ExtResource("2_font")\ntheme_override_font_sizes/font_size = 17',
    '[node name="TitleLabel" type="Label" parent="ContentMargin/VBox"]\nlayout_mode = 2\nmouse_filter = 2\ntheme_override_fonts/font = ExtResource("2_font")\ntheme_override_font_sizes/font_size = 16'
)

# DescLabel font size
text = text.replace(
    '[node name="DescLabel" type="Label" parent="ContentMargin/VBox"]\nlayout_mode = 2\nsize_flags_vertical = 3\nmouse_filter = 2\ntheme_override_font_sizes/font_size = 9',
    '[node name="DescLabel" type="Label" parent="ContentMargin/VBox"]\nlayout_mode = 2\nsize_flags_vertical = 3\nmouse_filter = 2\ntheme_override_font_sizes/font_size = 8.5'
)

with open("scenes/ui/components/move_card.tscn", "w", encoding="utf-8") as f:
    f.write(text)
print("Updated move_card.tscn with safe geometry padding")
