with open('scenes/ui/level_up_hud.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. HeroCard margin_right = 22
text = text.replace(
    '[node name="Margin" type="MarginContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard"]\nlayout_mode = 2\ntheme_override_constants/margin_left = 22\ntheme_override_constants/margin_top = 8\ntheme_override_constants/margin_right = 14',
    '[node name="Margin" type="MarginContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard"]\nlayout_mode = 2\ntheme_override_constants/margin_left = 22\ntheme_override_constants/margin_top = 8\ntheme_override_constants/margin_right = 22'
)

# 2. RegenHint font size = 7.5
text = text.replace(
    '[node name="RegenHint" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/MpGauge"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.494, 0.133, 0.808, 1)\ntheme_override_font_sizes/font_size = 8.5',
    '[node name="RegenHint" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/MpGauge"]\nlayout_mode = 2\ntheme_override_colors/font_color = Color(0.494, 0.133, 0.808, 1)\ntheme_override_font_sizes/font_size = 7.5'
)

# 3. Hide ShiftKey in Footer
text = text.replace(
    '[node name="ShiftKey" type="HBoxContainer" parent="MainVBox/FooterBar/Margin/HBox/KeysRow"]',
    '[node name="ShiftKey" type="HBoxContainer" parent="MainVBox/FooterBar/Margin/HBox/KeysRow"]\nvisible = false'
)

with open('scenes/ui/level_up_hud.tscn', 'w', encoding='utf-8') as f:
    f.write(text)

print("Updated level_up_hud.tscn successfully.")
