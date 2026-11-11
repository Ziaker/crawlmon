with open("scenes/ui/components/move_inspection_modal.tscn", "r", encoding="utf-8") as f:
    text = f.read()

# Remove clip_text = true from labels in modal
text = text.replace(
    '[node name="Desc" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.88, 0.9, 0.94, 1)\ntheme_override_font_sizes/font_size = 11\ntext = "Projects a concentrated psychic laser beam piercing barriers."\nautowrap_mode = 2\nclip_text = true',
    '[node name="Desc" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.88, 0.9, 0.94, 1)\ntheme_override_font_sizes/font_size = 11\ntext = "Projects a concentrated psychic laser beam piercing barriers."\nautowrap_mode = 2'
)

text = text.replace(
    '[node name="FormulaLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/FormulaBox/Margin/VBox/HBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0, 0.847, 0.965, 1)\ntheme_override_font_sizes/font_size = 12\nclip_text = true',
    '[node name="FormulaLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/FormulaBox/Margin/VBox/HBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0, 0.847, 0.965, 1)\ntheme_override_font_sizes/font_size = 12'
)

text = text.replace(
    '[node name="SynergyLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/FormulaBox/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.55, 0.65, 0.75, 1)\ntheme_override_font_sizes/font_size = 9\ntext = "Synergy: Includes Modest Nature modifier on effective MAG."\nautowrap_mode = 2\nclip_text = true',
    '[node name="SynergyLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/FormulaBox/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.55, 0.65, 0.75, 1)\ntheme_override_font_sizes/font_size = 9\ntext = "Synergy: Includes Modest Nature modifier on effective MAG."\nautowrap_mode = 2'
)

text = text.replace(
    '[node name="ManifestLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.88, 0.9, 0.94, 1)\ntheme_override_font_sizes/font_size = 10.5\ntext = "Concentrated high-energy psychic laser beam with violet distortion rings and particle fracture burst on impact."\nautowrap_mode = 2\nclip_text = true',
    '[node name="ManifestLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.88, 0.9, 0.94, 1)\ntheme_override_font_sizes/font_size = 10.5\ntext = "Concentrated high-energy psychic laser beam with violet distortion rings and particle fracture burst on impact."\nautowrap_mode = 2'
)

text = text.replace(
    '[node name="MotionLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.88, 0.9, 0.94, 1)\ntheme_override_font_sizes/font_size = 10.5\ntext = "User anchors securely in backline formation; fires linear high-velocity projectile piercing target."\nautowrap_mode = 2\nclip_text = true',
    '[node name="MotionLabel" type="Label" parent="CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.88, 0.9, 0.94, 1)\ntheme_override_font_sizes/font_size = 10.5\ntext = "User anchors securely in backline formation; fires linear high-velocity projectile piercing target."\nautowrap_mode = 2'
)

with open("scenes/ui/components/move_inspection_modal.tscn", "w", encoding="utf-8") as f:
    f.write(text)
print("Updated modal tscn")
