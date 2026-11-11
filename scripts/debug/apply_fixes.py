import re

# 1. Update scenes/ui/level_up_hud.tscn
with open("scenes/ui/level_up_hud.tscn", "r", encoding="utf-8") as f:
    hud_tscn = f.read()

# Margin on HeaderBar
hud_tscn = hud_tscn.replace(
    'theme_override_constants/margin_left = 16\ntheme_override_constants/margin_top = 6\ntheme_override_constants/margin_right = 16\ntheme_override_constants/margin_bottom = 2',
    'theme_override_constants/margin_left = 12\ntheme_override_constants/margin_top = 6\ntheme_override_constants/margin_right = 12\ntheme_override_constants/margin_bottom = 2'
)

# HeaderBar HBox separation
hud_tscn = hud_tscn.replace(
    '[node name="HBox" type="HBoxContainer" parent="MainVBox/HeaderBar/Margin"]\nlayout_mode = 2\ntheme_override_constants/separation = 12',
    '[node name="HBox" type="HBoxContainer" parent="MainVBox/HeaderBar/Margin"]\nlayout_mode = 2\ntheme_override_constants/separation = 8'
)

# TeamStatsBadge min_size & font_size
hud_tscn = hud_tscn.replace(
    'custom_minimum_size = Vector2(176, 34)',
    'custom_minimum_size = Vector2(136, 32)'
)
hud_tscn = hud_tscn.replace(
    '[node name="Label" type="Label" parent="MainVBox/HeaderBar/Margin/HBox/TeamStatsBadge"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0, 0, 0, 1)\ntheme_override_fonts/font = ExtResource("2_font")\ntheme_override_font_sizes/font_size = 24',
    '[node name="Label" type="Label" parent="MainVBox/HeaderBar/Margin/HBox/TeamStatsBadge"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0, 0, 0, 1)\ntheme_override_fonts/font = ExtResource("2_font")\ntheme_override_font_sizes/font_size = 20'
)

# Sub1 & Sub2 font size
hud_tscn = hud_tscn.replace(
    '[node name="Sub1" type="Label" parent="MainVBox/HeaderBar/Margin/HBox/TitlesVBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0, 0.847, 0.965, 1)\ntheme_override_font_sizes/font_size = 11',
    '[node name="Sub1" type="Label" parent="MainVBox/HeaderBar/Margin/HBox/TitlesVBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0, 0.847, 0.965, 1)\ntheme_override_font_sizes/font_size = 10.5'
)
hud_tscn = hud_tscn.replace(
    '[node name="Sub2" type="Label" parent="MainVBox/HeaderBar/Margin/HBox/TitlesVBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.392, 0.455, 0.545, 1)\ntheme_override_font_sizes/font_size = 9.5',
    '[node name="Sub2" type="Label" parent="MainVBox/HeaderBar/Margin/HBox/TitlesVBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.392, 0.455, 0.545, 1)\ntheme_override_font_sizes/font_size = 8.5'
)

# PartyLabel
hud_tscn = hud_tscn.replace(
    '[node name="PartyLabel" type="Label" parent="MainVBox/HeaderBar/Margin/HBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.58, 0.64, 0.72, 1)\ntheme_override_font_sizes/font_size = 11',
    '[node name="PartyLabel" type="Label" parent="MainVBox/HeaderBar/Margin/HBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.58, 0.64, 0.72, 1)\ntheme_override_font_sizes/font_size = 10.5'
)

# TabsContainer & HeaderControls separation
hud_tscn = hud_tscn.replace(
    '[node name="TabsContainer" type="HBoxContainer" parent="MainVBox/HeaderBar/Margin/HBox"]\nlayout_mode = 2\ntheme_override_constants/separation = 8',
    '[node name="TabsContainer" type="HBoxContainer" parent="MainVBox/HeaderBar/Margin/HBox"]\nlayout_mode = 2\ntheme_override_constants/separation = 6'
)
hud_tscn = hud_tscn.replace(
    '[node name="HeaderControls" type="HBoxContainer" parent="MainVBox/HeaderBar/Margin/HBox"]\nlayout_mode = 2\ntheme_override_constants/separation = 8',
    '[node name="HeaderControls" type="HBoxContainer" parent="MainVBox/HeaderBar/Margin/HBox"]\nlayout_mode = 2\ntheme_override_constants/separation = 6'
)

# Buttons in HeaderControls
hud_tscn = hud_tscn.replace(
    '[node name="ReplayBtn" type="Button" parent="MainVBox/HeaderBar/Margin/HBox/HeaderControls"]\ncustom_minimum_size = Vector2(116, 28)\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0, 0, 0, 1)\ntheme_override_fonts/font = ExtResource("2_font")\ntheme_override_font_sizes/font_size = 13',
    '[node name="ReplayBtn" type="Button" parent="MainVBox/HeaderBar/Margin/HBox/HeaderControls"]\ncustom_minimum_size = Vector2(96, 26)\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0, 0, 0, 1)\ntheme_override_fonts/font = ExtResource("2_font")\ntheme_override_font_sizes/font_size = 11.5'
)
hud_tscn = hud_tscn.replace(
    '[node name="MilestoneBtn" type="Button" parent="MainVBox/HeaderBar/Margin/HBox/HeaderControls"]\ncustom_minimum_size = Vector2(110, 28)\nlayout_mode = 2\ntheme_override_colors/font_color = Color(1, 1, 1, 1)\ntheme_override_font_sizes/font_size = 10',
    '[node name="MilestoneBtn" type="Button" parent="MainVBox/HeaderBar/Margin/HBox/HeaderControls"]\ncustom_minimum_size = Vector2(88, 26)\nlayout_mode = 2\ntheme_override_colors/font_color = Color(1, 1, 1, 1)\ntheme_override_font_sizes/font_size = 9'
)
hud_tscn = hud_tscn.replace(
    '[node name="ShiftBtn" type="Button" parent="MainVBox/HeaderBar/Margin/HBox/HeaderControls"]\ncustom_minimum_size = Vector2(110, 28)\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.984, 0.749, 0.141, 1)\ntheme_override_font_sizes/font_size = 10',
    '[node name="ShiftBtn" type="Button" parent="MainVBox/HeaderBar/Margin/HBox/HeaderControls"]\ncustom_minimum_size = Vector2(84, 26)\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.984, 0.749, 0.141, 1)\ntheme_override_font_sizes/font_size = 9'
)
hud_tscn = hud_tscn.replace(
    '[node name="AudioBtn" type="Button" parent="MainVBox/HeaderBar/Margin/HBox/HeaderControls"]\ncustom_minimum_size = Vector2(80, 28)\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0, 0.847, 0.965, 1)\ntheme_override_font_sizes/font_size = 10',
    '[node name="AudioBtn" type="Button" parent="MainVBox/HeaderBar/Margin/HBox/HeaderControls"]\ncustom_minimum_size = Vector2(62, 26)\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0, 0.847, 0.965, 1)\ntheme_override_font_sizes/font_size = 9'
)

with open("scenes/ui/level_up_hud.tscn", "w", encoding="utf-8") as f:
    f.write(hud_tscn)
print("Updated level_up_hud.tscn")

# 2. Update scripts/ui/level_up_hud.gd
with open("scripts/ui/level_up_hud.gd", "r", encoding="utf-8") as f:
    hud_gd = f.read()

hud_gd = hud_gd.replace(
    'btn.custom_minimum_size = Vector2(148, 30)',
    'btn.custom_minimum_size = Vector2(116, 28)'
)

with open("scripts/ui/level_up_hud.gd", "w", encoding="utf-8") as f:
    f.write(hud_gd)
print("Updated level_up_hud.gd")

# 3. Update scenes/ui/components/move_card.tscn
with open("scenes/ui/components/move_card.tscn", "r", encoding="utf-8") as f:
    card_tscn = f.read()

card_tscn = card_tscn.replace(
    '[node name="MoveCard" type="Control"]\ncustom_minimum_size = Vector2(196, 94)\nlayout_mode = 3\nanchors_preset = 0\noffset_right = 196.0\noffset_bottom = 94.0\nmouse_filter = 0\nscript = ExtResource("1_mcard")',
    '[node name="MoveCard" type="Control"]\nclip_contents = true\ncustom_minimum_size = Vector2(196, 114)\nlayout_mode = 3\nanchors_preset = 0\noffset_right = 196.0\noffset_bottom = 114.0\nmouse_filter = 0\nscript = ExtResource("1_mcard")'
)

card_tscn = card_tscn.replace(
    'theme_override_constants/margin_left = 6\ntheme_override_constants/margin_top = 5\ntheme_override_constants/margin_right = 5\ntheme_override_constants/margin_bottom = 5',
    'theme_override_constants/margin_left = 8\ntheme_override_constants/margin_top = 6\ntheme_override_constants/margin_right = 8\ntheme_override_constants/margin_bottom = 6'
)

card_tscn = card_tscn.replace(
    '[node name="TitleLabel" type="Label" parent="ContentMargin/VBox"]\nlayout_mode = 2\nmouse_filter = 2\ntheme_override_fonts/font = ExtResource("2_font")\ntheme_override_font_sizes/font_size = 18',
    '[node name="TitleLabel" type="Label" parent="ContentMargin/VBox"]\nlayout_mode = 2\nmouse_filter = 2\ntheme_override_fonts/font = ExtResource("2_font")\ntheme_override_font_sizes/font_size = 17'
)

card_tscn = card_tscn.replace(
    '[node name="DescLabel" type="Label" parent="ContentMargin/VBox"]\nlayout_mode = 2\nsize_flags_vertical = 3\nmouse_filter = 2\ntheme_override_font_sizes/font_size = 9\ntext = "Charges headfirst into the opponent with full bodily force."\nautowrap_mode = 2',
    '[node name="DescLabel" type="Label" parent="ContentMargin/VBox"]\nlayout_mode = 2\nsize_flags_vertical = 3\nmouse_filter = 2\ntheme_override_font_sizes/font_size = 9\ntext = "Charges headfirst into the opponent with full bodily force."\nautowrap_mode = 2\nclip_text = true'
)

card_tscn = card_tscn.replace(
    '[node name="EmptyLabel" type="Label" parent="."]\nvisible = false',
    '[node name="EmptyLabel" type="Label" parent="."]\nvisible = false\nclip_text = true'
)

with open("scenes/ui/components/move_card.tscn", "w", encoding="utf-8") as f:
    f.write(card_tscn)
print("Updated move_card.tscn")

# 4. Update scenes/ui/components/move_inspection_modal.tscn
with open("scenes/ui/components/move_inspection_modal.tscn", "r", encoding="utf-8") as f:
    modal_tscn = f.read()

modal_tscn = modal_tscn.replace(
    '[node name="ModalCard" type="PanelContainer" parent="CenterContainer"]\ncustom_minimum_size = Vector2(940, 520)',
    '[node name="ModalCard" type="PanelContainer" parent="CenterContainer"]\nclip_contents = true\ncustom_minimum_size = Vector2(940, 520)'
)

modal_tscn = modal_tscn.replace(
    '[node name="Block1" type="PanelContainer" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow"]\nlayout_mode = 2\nsize_flags_horizontal = 3\nscript = ExtResource("3_spanel")',
    '[node name="Block1" type="PanelContainer" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow"]\nclip_contents = true\nlayout_mode = 2\nsize_flags_horizontal = 3\nscript = ExtResource("3_spanel")'
)

modal_tscn = modal_tscn.replace(
    '[node name="Desc" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.88, 0.9, 0.94, 1)\ntheme_override_font_sizes/font_size = 11\ntext = "Projects a concentrated psychic laser beam piercing barriers."\nautowrap_mode = 2',
    '[node name="Desc" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.88, 0.9, 0.94, 1)\ntheme_override_font_sizes/font_size = 11\ntext = "Projects a concentrated psychic laser beam piercing barriers."\nautowrap_mode = 2\nclip_text = true'
)

modal_tscn = modal_tscn.replace(
    '[node name="FormulaLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/FormulaBox/Margin/VBox/HBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0, 0.847, 0.965, 1)\ntheme_override_font_sizes/font_size = 12',
    '[node name="FormulaLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/FormulaBox/Margin/VBox/HBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0, 0.847, 0.965, 1)\ntheme_override_font_sizes/font_size = 12\nclip_text = true'
)

modal_tscn = modal_tscn.replace(
    '[node name="SynergyLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/FormulaBox/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.55, 0.65, 0.75, 1)\ntheme_override_font_sizes/font_size = 9\ntext = "Synergy: Includes Modest Nature modifier on effective MAG."',
    '[node name="SynergyLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/FormulaBox/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.55, 0.65, 0.75, 1)\ntheme_override_font_sizes/font_size = 9\ntext = "Synergy: Includes Modest Nature modifier on effective MAG."\nautowrap_mode = 2\nclip_text = true'
)

modal_tscn = modal_tscn.replace(
    '[node name="Block2" type="PanelContainer" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow"]\nlayout_mode = 2\nsize_flags_horizontal = 3\nscript = ExtResource("3_spanel")',
    '[node name="Block2" type="PanelContainer" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow"]\nclip_contents = true\nlayout_mode = 2\nsize_flags_horizontal = 3\nscript = ExtResource("3_spanel")'
)

modal_tscn = modal_tscn.replace(
    '[node name="ManifestLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.88, 0.9, 0.94, 1)\ntheme_override_font_sizes/font_size = 10.5\ntext = "Concentrated high-energy psychic laser beam with violet distortion rings and particle fracture burst on impact."\nautowrap_mode = 2',
    '[node name="ManifestLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.88, 0.9, 0.94, 1)\ntheme_override_font_sizes/font_size = 10.5\ntext = "Concentrated high-energy psychic laser beam with violet distortion rings and particle fracture burst on impact."\nautowrap_mode = 2\nclip_text = true'
)

modal_tscn = modal_tscn.replace(
    '[node name="MotionLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.88, 0.9, 0.94, 1)\ntheme_override_font_sizes/font_size = 10.5\ntext = "User anchors securely in backline formation; fires linear high-velocity projectile piercing target."\nautowrap_mode = 2',
    '[node name="MotionLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.88, 0.9, 0.94, 1)\ntheme_override_font_sizes/font_size = 10.5\ntext = "User anchors securely in backline formation; fires linear high-velocity projectile piercing target."\nautowrap_mode = 2\nclip_text = true'
)

with open("scenes/ui/components/move_inspection_modal.tscn", "w", encoding="utf-8") as f:
    f.write(modal_tscn)
print("Updated move_inspection_modal.tscn")
