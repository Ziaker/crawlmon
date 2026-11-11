import os

tscn_content = '''[gd_scene format=3 uid="uid://dlvluphud001"]

[ext_resource type="Script" path="res://scripts/ui/level_up_hud.gd" id="1_lvhud"]
[ext_resource type="Shader" path="res://shaders/ui/skew_panel.gdshader" id="2_skew"]
[ext_resource type="Shader" path="res://shaders/ui/dragonball_aura.gdshader" id="3_aura"]
[ext_resource type="Shader" path="res://shaders/ui/ground_shock_ring.gdshader" id="4_ring"]
[ext_resource type="PackedScene" path="res://scenes/ui/components/stat_pips_strip.tscn" id="5_pips"]
[ext_resource type="Script" path="res://scripts/ui/components/slanted_button.gd" id="6_sbtn"]
[ext_resource type="PackedScene" path="res://scenes/ui/components/move_inspection_modal.tscn" id="7_modal"]

[sub_resource type="ShaderMaterial" id="ShaderMaterial_header_badge"]
shader = ExtResource("2_skew")
shader_parameter/rect_size = Vector2(170, 36)
shader_parameter/skew_angle_deg = -9.0
shader_parameter/bg_color = Color(1, 1, 1, 1)
shader_parameter/border_color = Color(0, 0, 0, 1)
shader_parameter/border_width = 2.0
shader_parameter/use_texture = false

[sub_resource type="ShaderMaterial" id="ShaderMaterial_volt_btn"]
shader = ExtResource("2_skew")
shader_parameter/rect_size = Vector2(110, 28)
shader_parameter/skew_angle_deg = -9.0
shader_parameter/bg_color = Color(0.831, 1, 0.196, 1)
shader_parameter/border_color = Color(0, 0, 0, 1)
shader_parameter/border_width = 1.5
shader_parameter/use_texture = false

[sub_resource type="ShaderMaterial" id="ShaderMaterial_dark_btn"]
shader = ExtResource("2_skew")
shader_parameter/rect_size = Vector2(110, 28)
shader_parameter/skew_angle_deg = -9.0
shader_parameter/bg_color = Color(0.078, 0.137, 0.204, 1)
shader_parameter/border_color = Color(0.18, 0.24, 0.32, 1)
shader_parameter/border_width = 1.5
shader_parameter/use_texture = false

[sub_resource type="ShaderMaterial" id="ShaderMaterial_hero_card"]
shader = ExtResource("2_skew")
shader_parameter/rect_size = Vector2(360, 154)
shader_parameter/skew_angle_deg = -9.0
shader_parameter/bg_color = Color(0.961, 0.965, 0.973, 1)
shader_parameter/border_color = Color(0, 0, 0, 1)
shader_parameter/border_width = 2.0
shader_parameter/use_texture = false

[sub_resource type="ShaderMaterial" id="ShaderMaterial_affinities_card"]
shader = ExtResource("2_skew")
shader_parameter/rect_size = Vector2(360, 68)
shader_parameter/skew_angle_deg = -9.0
shader_parameter/bg_color = Color(0.051, 0.094, 0.141, 0.96)
shader_parameter/border_color = Color(0.086, 0.251, 0.38, 0.9)
shader_parameter/border_width = 1.5
shader_parameter/use_texture = false

[sub_resource type="ShaderMaterial" id="ShaderMaterial_attributes_card"]
shader = ExtResource("2_skew")
shader_parameter/rect_size = Vector2(360, 260)
shader_parameter/skew_angle_deg = -9.0
shader_parameter/bg_color = Color(0.051, 0.094, 0.141, 0.96)
shader_parameter/border_color = Color(0.12, 0.16, 0.23, 1)
shader_parameter/border_width = 2.0
shader_parameter/use_texture = false

[sub_resource type="ShaderMaterial" id="ShaderMaterial_lock_notice"]
shader = ExtResource("2_skew")
shader_parameter/rect_size = Vector2(360, 36)
shader_parameter/skew_angle_deg = -9.0
shader_parameter/bg_color = Color(1, 1, 1, 1)
shader_parameter/border_color = Color(0, 0, 0, 1)
shader_parameter/border_width = 2.0
shader_parameter/use_texture = false

[sub_resource type="ShaderMaterial" id="ShaderMaterial_right_panel"]
shader = ExtResource("2_skew")
shader_parameter/rect_size = Vector2(520, 530)
shader_parameter/skew_angle_deg = -9.0
shader_parameter/bg_color = Color(0.051, 0.094, 0.141, 0.96)
shader_parameter/border_color = Color(0.12, 0.16, 0.23, 1)
shader_parameter/border_width = 2.0
shader_parameter/use_texture = false

[sub_resource type="ShaderMaterial" id="ShaderMaterial_return_btn"]
shader = ExtResource("2_skew")
shader_parameter/rect_size = Vector2(230, 28)
shader_parameter/skew_angle_deg = -9.0
shader_parameter/bg_color = Color(0.831, 1, 0.196, 1)
shader_parameter/border_color = Color(0, 0, 0, 1)
shader_parameter/border_width = 1.5
shader_parameter/use_texture = false

[sub_resource type="ShaderMaterial" id="ShaderMaterial_btn_minus"]
shader = ExtResource("2_skew")
shader_parameter/rect_size = Vector2(24, 20)
shader_parameter/skew_angle_deg = -9.0
shader_parameter/bg_color = Color(0.12, 0.15, 0.2, 1)
shader_parameter/border_color = Color(0, 0, 0, 1)
shader_parameter/border_width = 1.0
shader_parameter/use_texture = false

[sub_resource type="ShaderMaterial" id="ShaderMaterial_btn_plus"]
shader = ExtResource("2_skew")
shader_parameter/rect_size = Vector2(24, 20)
shader_parameter/skew_angle_deg = -9.0
shader_parameter/bg_color = Color(0, 0.847, 0.965, 1)
shader_parameter/border_color = Color(0, 0, 0, 1)
shader_parameter/border_width = 1.0
shader_parameter/use_texture = false

[sub_resource type="ShaderMaterial" id="ShaderMaterial_aura"]
shader = ExtResource("3_aura")
shader_parameter/aura_color = Color(1, 0.85, 0.2, 1)
shader_parameter/aura_intensity = 1.5
shader_parameter/speed = 3.0
shader_parameter/alpha_fade = 0.18

[sub_resource type="CylinderMesh" id="CylinderMesh_aura"]
material = SubResource("ShaderMaterial_aura")
top_radius = 0.85
bottom_radius = 1.15
height = 3.2
cap_top = false
cap_bottom = false

[sub_resource type="ShaderMaterial" id="ShaderMaterial_ring"]
shader = ExtResource("4_ring")
shader_parameter/ring_color = Color(0, 0.85, 1, 1)
shader_parameter/ring_radius = 0.05
shader_parameter/ring_thickness = 0.035
shader_parameter/opacity = 0.9

[sub_resource type="QuadMesh" id="QuadMesh_ring"]
material = SubResource("ShaderMaterial_ring")
size = Vector2(6, 6)
orientation = 1

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_quad"]
bg_color = Color(1, 1, 1, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_pill_black"]
bg_color = Color(0, 0, 0, 1)
corner_radius_top_left = 3
corner_radius_top_right = 3
corner_radius_bottom_right = 3
corner_radius_bottom_left = 3

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_pill_volt"]
bg_color = Color(0.831, 1, 0.196, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0, 0, 0, 1)
corner_radius_top_left = 3
corner_radius_top_right = 3
corner_radius_bottom_right = 3
corner_radius_bottom_left = 3

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_pill_psy"]
bg_color = Color(0.925, 0.282, 0.6, 1)
corner_radius_top_left = 3
corner_radius_top_right = 3
corner_radius_bottom_right = 3
corner_radius_bottom_left = 3

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_dark_card"]
bg_color = Color(0.08, 0.11, 0.16, 0.9)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.18, 0.24, 0.32, 0.8)
corner_radius_top_left = 3
corner_radius_top_right = 3
corner_radius_bottom_right = 3
corner_radius_bottom_left = 3

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_exp_bg"]
bg_color = Color(0.82, 0.84, 0.86, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0, 0, 0, 1)
corner_radius_top_left = 2
corner_radius_top_right = 2
corner_radius_bottom_right = 2
corner_radius_bottom_left = 2

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_exp_fill"]
bg_color = Color(0.831, 1, 0.196, 1)
corner_radius_top_left = 2
corner_radius_top_right = 2
corner_radius_bottom_right = 2
corner_radius_bottom_left = 2

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_hp_fill"]
bg_color = Color(0.133, 0.773, 0.369, 1)
corner_radius_top_left = 2
corner_radius_top_right = 2
corner_radius_bottom_right = 2
corner_radius_bottom_left = 2

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_mp_fill"]
bg_color = Color(0.576, 0.227, 0.918, 1)
corner_radius_top_left = 2
corner_radius_top_right = 2
corner_radius_bottom_right = 2
corner_radius_bottom_left = 2

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_kbd"]
bg_color = Color(0.15, 0.15, 0.15, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0, 0, 0, 1)
corner_radius_top_left = 2
corner_radius_top_right = 2
corner_radius_bottom_right = 2
corner_radius_bottom_left = 2

[node name="LevelUpHUD" type="Control"]
process_mode = 3
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_lvhud")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.024, 0.039, 0.063, 1)

[node name="MainVBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 4

[node name="HeaderBar" type="PanelContainer" parent="MainVBox"]
custom_minimum_size = Vector2(0, 48)
layout_mode = 2

[node name="Margin" type="MarginContainer" parent="MainVBox/HeaderBar"]
layout_mode = 2
theme_override_constants/margin_left = 28
theme_override_constants/margin_right = 28
theme_override_constants/margin_top = 6
theme_override_constants/margin_bottom = 6

[node name="HBox" type="HBoxContainer" parent="MainVBox/HeaderBar/Margin"]
layout_mode = 2
theme_override_constants/separation = 16

[node name="TeamStatsBox" type="HBoxContainer" parent="MainVBox/HeaderBar/Margin/HBox"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="TeamStatsBadge" type="PanelContainer" parent="MainVBox/HeaderBar/Margin/HBox/TeamStatsBox"]
material = SubResource("ShaderMaterial_header_badge")
custom_minimum_size = Vector2(170, 36)
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_quad")

[node name="Margin" type="MarginContainer" parent="MainVBox/HeaderBar/Margin/HBox/TeamStatsBox/TeamStatsBadge"]
layout_mode = 2
theme_override_constants/margin_left = 18
theme_override_constants/margin_right = 14

[node name="Label" type="Label" parent="MainVBox/HeaderBar/Margin/HBox/TeamStatsBox/TeamStatsBadge/Margin"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 0, 0, 1)
theme_override_font_sizes/font_size = 22
text = "TEAM / STATS"
vertical_alignment = 1

[node name="TitlesVBox" type="VBoxContainer" parent="MainVBox/HeaderBar/Margin/HBox/TeamStatsBox"]
layout_mode = 2
alignment = 1

[node name="Sub1" type="Label" parent="MainVBox/HeaderBar/Margin/HBox/TeamStatsBox/TitlesVBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 0.847, 0.965, 1)
theme_override_font_sizes/font_size = 11
text = "POST-COMBAT STATUS & PROGRESSION"

[node name="Sub2" type="Label" parent="MainVBox/HeaderBar/Margin/HBox/TeamStatsBox/TitlesVBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.612, 0.64, 0.686, 1)
theme_override_font_sizes/font_size = 9
text = "SMT III NOCTURNE FIDELITY • D-413 / D-401 / D-394 / D-393"

[node name="Spacer1" type="Control" parent="MainVBox/HeaderBar/Margin/HBox"]
layout_mode = 2
size_flags_horizontal = 3

[node name="TabsContainer" type="HBoxContainer" parent="MainVBox/HeaderBar/Margin/HBox"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="Spacer2" type="Control" parent="MainVBox/HeaderBar/Margin/HBox"]
layout_mode = 2
size_flags_horizontal = 3

[node name="HeaderControls" type="HBoxContainer" parent="MainVBox/HeaderBar/Margin/HBox"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="ReplayBtn" type="Button" parent="MainVBox/HeaderBar/Margin/HBox/HeaderControls"]
material = SubResource("ShaderMaterial_volt_btn")
custom_minimum_size = Vector2(110, 28)
layout_mode = 2
theme_override_colors/font_color = Color(0, 0, 0, 1)
theme_override_font_sizes/font_size = 11
text = "▶ REPLAY EXP"
script = ExtResource("6_sbtn")

[node name="MilestoneBtn" type="Button" parent="MainVBox/HeaderBar/Margin/HBox/HeaderControls"]
material = SubResource("ShaderMaterial_dark_btn")
custom_minimum_size = Vector2(110, 28)
layout_mode = 2
theme_override_colors/font_color = Color(0.8, 0.85, 0.9, 1)
theme_override_font_sizes/font_size = 11
text = "LV 1->2 (1 PT)"
script = ExtResource("6_sbtn")

[node name="ContentArea" type="HBoxContainer" parent="MainVBox"]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/separation = 16

[node name="MarginLeft" type="Control" parent="MainVBox/ContentArea"]
custom_minimum_size = Vector2(16, 0)
layout_mode = 2

[node name="LeftCol" type="VBoxContainer" parent="MainVBox/ContentArea"]
custom_minimum_size = Vector2(360, 0)
layout_mode = 2
theme_override_constants/separation = 8

[node name="HeroCard" type="PanelContainer" parent="MainVBox/ContentArea/LeftCol"]
material = SubResource("ShaderMaterial_hero_card")
custom_minimum_size = Vector2(360, 154)
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_quad")

[node name="Margin" type="MarginContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard"]
layout_mode = 2
theme_override_constants/margin_left = 34
theme_override_constants/margin_top = 10
theme_override_constants/margin_right = 24
theme_override_constants/margin_bottom = 10

[node name="VBox" type="VBoxContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="TopRow" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="RoleBadge" type="PanelContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow"]
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_pill_black")

[node name="Margin" type="MarginContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow/RoleBadge"]
layout_mode = 2
theme_override_constants/margin_left = 6
theme_override_constants/margin_right = 6

[node name="RoleLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow/RoleBadge/Margin"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 9
text = "PROTAGONIST / LEADER"

[node name="SpeciesLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0.42, 0.45, 0.5, 1)
theme_override_font_sizes/font_size = 10
text = "PSI POKÉMON"

[node name="Spacer" type="Control" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="LevelBox" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow"]
layout_mode = 2
theme_override_constants/separation = 4
alignment = 2

[node name="LvTag" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow/LevelBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.3, 0.35, 0.4, 1)
theme_override_font_sizes/font_size = 11
text = "LV"

[node name="HeroLevel" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow/LevelBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 0, 0, 1)
theme_override_font_sizes/font_size = 24
text = "2"

[node name="NextExp" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/TopRow/LevelBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.42, 0.45, 0.5, 1)
theme_override_font_sizes/font_size = 9
text = "NEXT 200 EXP"

[node name="NameRow" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="HeroName" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/NameRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 0, 0, 1)
theme_override_font_sizes/font_size = 32
text = "ABRA"

[node name="NatureBadge" type="PanelContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/NameRow"]
layout_mode = 2
size_flags_vertical = 4
theme_override_styles/panel = SubResource("StyleBoxFlat_pill_psy")

[node name="Margin" type="MarginContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/NameRow/NatureBadge"]
layout_mode = 2
theme_override_constants/margin_left = 6
theme_override_constants/margin_right = 6

[node name="Label" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/NameRow/NatureBadge/Margin"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 10
text = "PSYCHIC"

[node name="Spacer" type="Control" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/NameRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="ReadyRow" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/NameRow"]
layout_mode = 2
alignment = 2

[node name="Dot" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/NameRow/ReadyRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0.133, 0.773, 0.369, 1)
theme_override_font_sizes/font_size = 10
text = "●"

[node name="ReadyLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/NameRow/ReadyRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0.22, 0.25, 0.32, 1)
theme_override_font_sizes/font_size = 10
text = "ACTIVE BATTLE READY"

[node name="ExpBox" type="VBoxContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox"]
layout_mode = 2
theme_override_constants/separation = 2

[node name="ExpTextRow" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/ExpBox"]
layout_mode = 2

[node name="Label" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/ExpBox/ExpTextRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0.42, 0.45, 0.5, 1)
theme_override_font_sizes/font_size = 9
text = "EXP PROGRESSION"

[node name="Spacer" type="Control" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/ExpBox/ExpTextRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="ExpEarnedLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/ExpBox/ExpTextRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0.85, 0.46, 0.05, 1)
theme_override_font_sizes/font_size = 10
text = "+60 EXP EARNED"

[node name="ExpProgressBar" type="ProgressBar" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/ExpBox"]
custom_minimum_size = Vector2(0, 8)
layout_mode = 2
theme_override_styles/background = SubResource("StyleBoxFlat_exp_bg")
theme_override_styles/fill = SubResource("StyleBoxFlat_exp_fill")
show_percentage = false

[node name="GaugesRow" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="HpGauge" type="VBoxContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 2

[node name="TextRow" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/HpGauge"]
layout_mode = 2

[node name="HpTag" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/HpGauge/TextRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0.02, 0.58, 0.41, 1)
theme_override_font_sizes/font_size = 12
text = "HP"

[node name="Spacer" type="Control" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/HpGauge/TextRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="ValLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/HpGauge/TextRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 0, 0, 1)
theme_override_font_sizes/font_size = 11
text = "49 / 49"

[node name="ProgressBar" type="ProgressBar" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/HpGauge"]
custom_minimum_size = Vector2(0, 6)
layout_mode = 2
theme_override_styles/background = SubResource("StyleBoxFlat_exp_bg")
theme_override_styles/fill = SubResource("StyleBoxFlat_hp_fill")
show_percentage = false

[node name="FormulaHint" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/HpGauge"]
layout_mode = 2
theme_override_colors/font_color = Color(0.42, 0.45, 0.5, 1)
theme_override_font_sizes/font_size = 8
text = "25 + 10L + 25[L/10] + 2VIT (D-392)"

[node name="MpGauge" type="VBoxContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 2

[node name="TextRow" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/MpGauge"]
layout_mode = 2

[node name="MpTag" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/MpGauge/TextRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0.48, 0.23, 0.85, 1)
theme_override_font_sizes/font_size = 12
text = "MP"

[node name="Spacer" type="Control" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/MpGauge/TextRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="ValLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/MpGauge/TextRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 0, 0, 1)
theme_override_font_sizes/font_size = 11
text = "26 / 26"

[node name="ProgressBar" type="ProgressBar" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/MpGauge"]
custom_minimum_size = Vector2(0, 6)
layout_mode = 2
theme_override_styles/background = SubResource("StyleBoxFlat_exp_bg")
theme_override_styles/fill = SubResource("StyleBoxFlat_mp_fill")
show_percentage = false

[node name="RegenHint" type="Label" parent="MainVBox/ContentArea/LeftCol/HeroCard/Margin/VBox/GaugesRow/MpGauge"]
layout_mode = 2
theme_override_colors/font_color = Color(0.48, 0.23, 0.85, 1)
theme_override_font_sizes/font_size = 8
text = "REGEN: +4 MP / 8s • FLOOR: 20 MP"

[node name="AffinitiesCard" type="PanelContainer" parent="MainVBox/ContentArea/LeftCol"]
material = SubResource("ShaderMaterial_affinities_card")
custom_minimum_size = Vector2(360, 68)
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_quad")

[node name="Margin" type="MarginContainer" parent="MainVBox/ContentArea/LeftCol/AffinitiesCard"]
layout_mode = 2
theme_override_constants/margin_left = 32
theme_override_constants/margin_top = 6
theme_override_constants/margin_right = 24
theme_override_constants/margin_bottom = 6

[node name="VBox" type="VBoxContainer" parent="MainVBox/ContentArea/LeftCol/AffinitiesCard/Margin"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="TopRow" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/AffinitiesCard/Margin/VBox"]
layout_mode = 2

[node name="Title" type="Label" parent="MainVBox/ContentArea/LeftCol/AffinitiesCard/Margin/VBox/TopRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 0.847, 0.965, 1)
theme_override_font_sizes/font_size = 10
text = "ELEMENTAL AFFINITIES & WEAKNESSES"

[node name="Spacer" type="Control" parent="MainVBox/ContentArea/LeftCol/AffinitiesCard/Margin/VBox/TopRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Sub" type="Label" parent="MainVBox/ContentArea/LeftCol/AffinitiesCard/Margin/VBox/TopRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0.42, 0.45, 0.5, 1)
theme_override_font_sizes/font_size = 8
text = "CLICK FOR DETAILS"

[node name="AffinitiesRow" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/AffinitiesCard/Margin/VBox"]
layout_mode = 2
theme_override_constants/separation = 4
alignment = 1

[node name="AttributesCard" type="PanelContainer" parent="MainVBox/ContentArea/LeftCol"]
material = SubResource("ShaderMaterial_attributes_card")
custom_minimum_size = Vector2(360, 260)
layout_mode = 2
size_flags_vertical = 3
theme_override_styles/panel = SubResource("StyleBoxFlat_quad")

[node name="Margin" type="MarginContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard"]
layout_mode = 2
theme_override_constants/margin_left = 32
theme_override_constants/margin_top = 10
theme_override_constants/margin_right = 24
theme_override_constants/margin_bottom = 10

[node name="VBox" type="VBoxContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="HeaderRow" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox"]
layout_mode = 2

[node name="TitleBox" type="VBoxContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/HeaderRow"]
layout_mode = 2

[node name="Title" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/HeaderRow/TitleBox"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 16
text = "ATTRIBUTES (6 STATS)"

[node name="Sub" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/HeaderRow/TitleBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.42, 0.45, 0.5, 1)
theme_override_font_sizes/font_size = 8
text = "D-390: 15 PTS BUDGET • SMT III SEGMENTED PIPS"

[node name="Spacer" type="Control" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/HeaderRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="PointsAvailablePill" type="PanelContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/HeaderRow"]
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_pill_volt")

[node name="Margin" type="MarginContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/HeaderRow/PointsAvailablePill"]
layout_mode = 2
theme_override_constants/margin_left = 6
theme_override_constants/margin_right = 6

[node name="Label" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/HeaderRow/PointsAvailablePill/Margin"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 0, 0, 1)
theme_override_font_sizes/font_size = 10
text = "AVAILABLE: 1 PT"

[node name="NatureBanner" type="PanelContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox"]
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_dark_card")

[node name="Margin" type="MarginContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/NatureBanner"]
layout_mode = 2
theme_override_constants/margin_left = 6
theme_override_constants/margin_top = 3
theme_override_constants/margin_right = 6
theme_override_constants/margin_bottom = 3

[node name="HBox" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/NatureBanner/Margin"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="NatureName" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/NatureBanner/Margin/HBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.984, 0.749, 0.141, 1)
theme_override_font_sizes/font_size = 9
text = "NATURE: MODEST"

[node name="NatureMods" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/NatureBanner/Margin/HBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.2, 0.8, 0.4, 1)
theme_override_font_sizes/font_size = 9
text = "(+3 MAG, -2 STR, -1 AGI)"

[node name="Spacer" type="Control" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/NatureBanner/Margin/HBox"]
layout_mode = 2
size_flags_horizontal = 3

[node name="NatureTactic" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/NatureBanner/Margin/HBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.6, 0.65, 0.75, 1)
theme_override_font_sizes/font_size = 9
text = "Ranged Spellcaster (D-393) ℹ"

[node name="StatsVBox" type="VBoxContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox"]
layout_mode = 2
theme_override_constants/separation = 3

[node name="STR" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="NameLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/STR"]
custom_minimum_size = Vector2(28, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 11
text = "STR"

[node name="NatModLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/STR"]
custom_minimum_size = Vector2(20, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.95, 0.35, 0.45, 1)
theme_override_font_sizes/font_size = 9
text = "-2"
horizontal_alignment = 1

[node name="ValLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/STR"]
custom_minimum_size = Vector2(18, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 11
text = "1"
horizontal_alignment = 1

[node name="StatPipsStrip" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/STR" instance=ExtResource("5_pips")]
layout_mode = 2
size_flags_horizontal = 3

[node name="MinusBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/STR"]
material = SubResource("ShaderMaterial_btn_minus")
custom_minimum_size = Vector2(22, 18)
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "-"
script = ExtResource("6_sbtn")

[node name="PlusBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/STR"]
material = SubResource("ShaderMaterial_btn_plus")
custom_minimum_size = Vector2(22, 18)
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "+"
script = ExtResource("6_sbtn")

[node name="MAG" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="NameLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/MAG"]
custom_minimum_size = Vector2(28, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 11
text = "MAG"

[node name="NatModLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/MAG"]
custom_minimum_size = Vector2(20, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.2, 0.8, 0.4, 1)
theme_override_font_sizes/font_size = 9
text = "+3"
horizontal_alignment = 1

[node name="ValLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/MAG"]
custom_minimum_size = Vector2(18, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 11
text = "8"
horizontal_alignment = 1

[node name="StatPipsStrip" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/MAG" instance=ExtResource("5_pips")]
layout_mode = 2
size_flags_horizontal = 3

[node name="MinusBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/MAG"]
material = SubResource("ShaderMaterial_btn_minus")
custom_minimum_size = Vector2(22, 18)
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "-"
script = ExtResource("6_sbtn")

[node name="PlusBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/MAG"]
material = SubResource("ShaderMaterial_btn_plus")
custom_minimum_size = Vector2(22, 18)
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "+"
script = ExtResource("6_sbtn")

[node name="VIT" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="NameLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/VIT"]
custom_minimum_size = Vector2(28, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 11
text = "VIT"

[node name="NatModLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/VIT"]
custom_minimum_size = Vector2(20, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.5, 0.5, 0.5, 1)
theme_override_font_sizes/font_size = 9
horizontal_alignment = 1

[node name="ValLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/VIT"]
custom_minimum_size = Vector2(18, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 11
text = "2"
horizontal_alignment = 1

[node name="StatPipsStrip" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/VIT" instance=ExtResource("5_pips")]
layout_mode = 2
size_flags_horizontal = 3

[node name="MinusBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/VIT"]
material = SubResource("ShaderMaterial_btn_minus")
custom_minimum_size = Vector2(22, 18)
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "-"
script = ExtResource("6_sbtn")

[node name="PlusBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/VIT"]
material = SubResource("ShaderMaterial_btn_plus")
custom_minimum_size = Vector2(22, 18)
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "+"
script = ExtResource("6_sbtn")

[node name="WIS" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="NameLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/WIS"]
custom_minimum_size = Vector2(28, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 11
text = "WIS"

[node name="NatModLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/WIS"]
custom_minimum_size = Vector2(20, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.5, 0.5, 0.5, 1)
theme_override_font_sizes/font_size = 9
horizontal_alignment = 1

[node name="ValLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/WIS"]
custom_minimum_size = Vector2(18, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 11
text = "4"
horizontal_alignment = 1

[node name="StatPipsStrip" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/WIS" instance=ExtResource("5_pips")]
layout_mode = 2
size_flags_horizontal = 3

[node name="MinusBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/WIS"]
material = SubResource("ShaderMaterial_btn_minus")
custom_minimum_size = Vector2(22, 18)
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "-"
script = ExtResource("6_sbtn")

[node name="PlusBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/WIS"]
material = SubResource("ShaderMaterial_btn_plus")
custom_minimum_size = Vector2(22, 18)
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "+"
script = ExtResource("6_sbtn")

[node name="AGI" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="NameLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/AGI"]
custom_minimum_size = Vector2(28, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 11
text = "AGI"

[node name="NatModLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/AGI"]
custom_minimum_size = Vector2(20, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.95, 0.35, 0.45, 1)
theme_override_font_sizes/font_size = 9
text = "-1"
horizontal_alignment = 1

[node name="ValLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/AGI"]
custom_minimum_size = Vector2(18, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 11
text = "1"
horizontal_alignment = 1

[node name="StatPipsStrip" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/AGI" instance=ExtResource("5_pips")]
layout_mode = 2
size_flags_horizontal = 3

[node name="MinusBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/AGI"]
material = SubResource("ShaderMaterial_btn_minus")
custom_minimum_size = Vector2(22, 18)
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "-"
script = ExtResource("6_sbtn")

[node name="PlusBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/AGI"]
material = SubResource("ShaderMaterial_btn_plus")
custom_minimum_size = Vector2(22, 18)
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "+"
script = ExtResource("6_sbtn")

[node name="LUK" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="NameLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/LUK"]
custom_minimum_size = Vector2(28, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 11
text = "LUK"

[node name="NatModLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/LUK"]
custom_minimum_size = Vector2(20, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.5, 0.5, 0.5, 1)
theme_override_font_sizes/font_size = 9
horizontal_alignment = 1

[node name="ValLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/LUK"]
custom_minimum_size = Vector2(18, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 11
text = "1"
horizontal_alignment = 1

[node name="StatPipsStrip" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/LUK" instance=ExtResource("5_pips")]
layout_mode = 2
size_flags_horizontal = 3

[node name="MinusBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/LUK"]
material = SubResource("ShaderMaterial_btn_minus")
custom_minimum_size = Vector2(22, 18)
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "-"
script = ExtResource("6_sbtn")

[node name="PlusBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/LUK"]
material = SubResource("ShaderMaterial_btn_plus")
custom_minimum_size = Vector2(22, 18)
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "+"
script = ExtResource("6_sbtn")

[node name="AllyProfPanel" type="PanelContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox"]
visible = false
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_dark_card")

[node name="Label" type="Label" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/AllyProfPanel"]
layout_mode = 2
theme_override_colors/font_color = Color(0.984, 0.749, 0.141, 1)
theme_override_font_sizes/font_size = 10
text = "AUTOMATIC LEVEL UP (D-394):
+1 STR GRANTED"
autowrap_mode = 2

[node name="Spacer" type="Control" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox"]
layout_mode = 2
size_flags_vertical = 3

[node name="LeaderControls" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="ResetBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/LeaderControls"]
custom_minimum_size = Vector2(70, 26)
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "RESET"

[node name="ConfirmAllocBtn" type="Button" parent="MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/LeaderControls"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0, 0, 0, 1)
theme_override_font_sizes/font_size = 11
theme_override_styles/normal = SubResource("StyleBoxFlat_pill_volt")
text = "CONFIRM ALLOCATION (D-401)"

[node name="AdvanceLockNotice" type="PanelContainer" parent="MainVBox/ContentArea/LeftCol"]
material = SubResource("ShaderMaterial_lock_notice")
custom_minimum_size = Vector2(360, 36)
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_quad")

[node name="Margin" type="MarginContainer" parent="MainVBox/ContentArea/LeftCol/AdvanceLockNotice"]
layout_mode = 2
theme_override_constants/margin_left = 32
theme_override_constants/margin_right = 24
theme_override_constants/margin_top = 4
theme_override_constants/margin_bottom = 4

[node name="HBox" type="HBoxContainer" parent="MainVBox/ContentArea/LeftCol/AdvanceLockNotice/Margin"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="Icon" type="Label" parent="MainVBox/ContentArea/LeftCol/AdvanceLockNotice/Margin/HBox"]
layout_mode = 2
text = "⚠️"

[node name="NoticeLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AdvanceLockNotice/Margin/HBox"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0, 0, 0, 1)
theme_override_font_sizes/font_size = 9
text = "Leader has unallocated stat points! Distribution is required (D-401)."

[node name="Badge" type="PanelContainer" parent="MainVBox/ContentArea/LeftCol/AdvanceLockNotice/Margin/HBox"]
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_pill_black")

[node name="Margin" type="MarginContainer" parent="MainVBox/ContentArea/LeftCol/AdvanceLockNotice/Margin/HBox/Badge"]
layout_mode = 2
theme_override_constants/margin_left = 4
theme_override_constants/margin_right = 4

[node name="BadgeLabel" type="Label" parent="MainVBox/ContentArea/LeftCol/AdvanceLockNotice/Margin/HBox/Badge/Margin"]
layout_mode = 2
theme_override_colors/font_color = Color(0.831, 1, 0.196, 1)
theme_override_font_sizes/font_size = 8
text = "REQUIRED (D-401)"

[node name="CenterCol" type="VBoxContainer" parent="MainVBox/ContentArea"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 4

[node name="ViewportContainer" type="SubViewportContainer" parent="MainVBox/ContentArea/CenterCol"]
layout_mode = 2
size_flags_vertical = 3
stretch = true

[node name="SubViewport" type="SubViewport" parent="MainVBox/ContentArea/CenterCol/ViewportContainer"]
own_world_3d = true
transparent_bg = true
handle_input_locally = false
size = Vector2i(2, 2)
render_target_update_mode = 4

[node name="Camera3D" type="Camera3D" parent="MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport"]
transform = Transform3D(1, 0, 0, 0, 0.965926, 0.258819, 0, -0.258819, 0.965926, 0, 1.8, 4.2)
current = true

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport"]
transform = Transform3D(0.866025, -0.25, 0.433013, 0, 0.866025, 0.5, -0.5, -0.433013, 0.75, 2, 4, 3)
light_color = Color(0.9, 0.95, 1, 1)
light_energy = 1.2

[node name="ModelMount" type="Node3D" parent="MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport"]

[node name="AuraCylinder" type="MeshInstance3D" parent="MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.8, 0)
visible = false
mesh = SubResource("CylinderMesh_aura")

[node name="ShockRing1" type="MeshInstance3D" parent="MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.02, 0)
visible = false
mesh = SubResource("QuadMesh_ring")

[node name="ShockRing2" type="MeshInstance3D" parent="MainVBox/ContentArea/CenterCol/ViewportContainer/SubViewport"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.02, 0)
visible = false
mesh = SubResource("QuadMesh_ring")

[node name="RotateHint" type="Label" parent="MainVBox/ContentArea/CenterCol"]
layout_mode = 2
theme_override_colors/font_color = Color(0.42, 0.45, 0.5, 1)
theme_override_font_sizes/font_size = 9
text = "Click & Drag to Rotate 3D Model"
horizontal_alignment = 1

[node name="RightCol" type="PanelContainer" parent="MainVBox/ContentArea"]
material = SubResource("ShaderMaterial_right_panel")
custom_minimum_size = Vector2(520, 0)
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_quad")

[node name="Margin" type="MarginContainer" parent="MainVBox/ContentArea/RightCol"]
layout_mode = 2
theme_override_constants/margin_left = 32
theme_override_constants/margin_top = 10
theme_override_constants/margin_right = 24
theme_override_constants/margin_bottom = 10

[node name="VBox" type="VBoxContainer" parent="MainVBox/ContentArea/RightCol/Margin"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="HeaderBox" type="VBoxContainer" parent="MainVBox/ContentArea/RightCol/Margin/VBox"]
layout_mode = 2

[node name="Title" type="Label" parent="MainVBox/ContentArea/RightCol/Margin/VBox/HeaderBox"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 18
text = "MOVES & SKILLS (8 SLOTS)"

[node name="Subtitle" type="Label" parent="MainVBox/ContentArea/RightCol/Margin/VBox/HeaderBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.612, 0.64, 0.686, 1)
theme_override_font_sizes/font_size = 9
text = "FLAT ELEMENT COLOR CARDS • EMBOSSED WATERMARK • CLICK FOR RULES"

[node name="MovesGrid" type="GridContainer" parent="MainVBox/ContentArea/RightCol/Margin/VBox"]
layout_mode = 2
theme_override_constants/h_separation = 8
theme_override_constants/v_separation = 6
columns = 2

[node name="LootPanel" type="PanelContainer" parent="MainVBox/ContentArea/RightCol/Margin/VBox"]
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_dark_card")

[node name="Margin" type="MarginContainer" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel"]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 6
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 6

[node name="VBox" type="VBoxContainer" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="TopRow" type="HBoxContainer" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox"]
layout_mode = 2

[node name="Label" type="Label" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/TopRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0.984, 0.749, 0.141, 1)
theme_override_font_sizes/font_size = 10
text = "BATTLE SPOILS & LOOT (D-400)"

[node name="Spacer" type="Control" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/TopRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Sub" type="Label" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/TopRow"]
layout_mode = 2
theme_override_colors/font_color = Color(0.612, 0.64, 0.686, 1)
theme_override_font_sizes/font_size = 9
text = "ALL FOES DEFEATED"

[node name="ItemsRow" type="HBoxContainer" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox"]
layout_mode = 2
theme_override_constants/separation = 16

[node name="GoldItem" type="HBoxContainer" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Badge" type="PanelContainer" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow/GoldItem"]
custom_minimum_size = Vector2(22, 22)
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_dark_card")

[node name="Label" type="Label" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow/GoldItem/Badge"]
layout_mode = 2
theme_override_colors/font_color = Color(0.984, 0.749, 0.141, 1)
theme_override_font_sizes/font_size = 10
text = "G"
horizontal_alignment = 1
vertical_alignment = 1

[node name="VBox" type="VBoxContainer" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow/GoldItem"]
layout_mode = 2
alignment = 1

[node name="Val" type="Label" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow/GoldItem/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 11
text = "+140 GOLD"

[node name="Desc" type="Label" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow/GoldItem/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.612, 0.64, 0.686, 1)
theme_override_font_sizes/font_size = 8
text = "Dungeon Currency"

[node name="PotionItem" type="HBoxContainer" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="Badge" type="PanelContainer" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow/PotionItem"]
custom_minimum_size = Vector2(22, 22)
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_dark_card")

[node name="Label" type="Label" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow/PotionItem/Badge"]
layout_mode = 2
theme_override_colors/font_color = Color(0.2, 0.8, 0.4, 1)
theme_override_font_sizes/font_size = 10
text = "🧪"
horizontal_alignment = 1
vertical_alignment = 1

[node name="VBox" type="VBoxContainer" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow/PotionItem"]
layout_mode = 2
alignment = 1

[node name="Val" type="Label" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow/PotionItem/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 11
text = "POTION x1"

[node name="Desc" type="Label" parent="MainVBox/ContentArea/RightCol/Margin/VBox/LootPanel/Margin/VBox/ItemsRow/PotionItem/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.612, 0.64, 0.686, 1)
theme_override_font_sizes/font_size = 8
text = "Restores 50 HP"

[node name="MarginRight" type="Control" parent="MainVBox/ContentArea"]
custom_minimum_size = Vector2(16, 0)
layout_mode = 2

[node name="FooterBar" type="PanelContainer" parent="MainVBox"]
custom_minimum_size = Vector2(0, 36)
layout_mode = 2

[node name="Margin" type="MarginContainer" parent="MainVBox/FooterBar"]
layout_mode = 2
theme_override_constants/margin_left = 28
theme_override_constants/margin_right = 28

[node name="HBox" type="HBoxContainer" parent="MainVBox/FooterBar/Margin"]
layout_mode = 2
theme_override_constants/separation = 16

[node name="KeysRow" type="HBoxContainer" parent="MainVBox/FooterBar/Margin/HBox"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="SwitchHeroKey" type="HBoxContainer" parent="MainVBox/FooterBar/Margin/HBox/KeysRow"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="KbdQ" type="Label" parent="MainVBox/FooterBar/Margin/HBox/KeysRow/SwitchHeroKey"]
layout_mode = 2
theme_override_styles/normal = SubResource("StyleBoxFlat_kbd")
text = " Q "

[node name="KbdD" type="Label" parent="MainVBox/FooterBar/Margin/HBox/KeysRow/SwitchHeroKey"]
layout_mode = 2
theme_override_styles/normal = SubResource("StyleBoxFlat_kbd")
text = " D "

[node name="Label" type="Label" parent="MainVBox/FooterBar/Margin/HBox/KeysRow/SwitchHeroKey"]
layout_mode = 2
theme_override_colors/font_color = Color(0.612, 0.64, 0.686, 1)
theme_override_font_sizes/font_size = 10
text = "Switch Hero"

[node name="ShiftKey" type="HBoxContainer" parent="MainVBox/FooterBar/Margin/HBox/KeysRow"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="KbdShift" type="Label" parent="MainVBox/FooterBar/Margin/HBox/KeysRow/ShiftKey"]
layout_mode = 2
theme_override_colors/font_color = Color(0.984, 0.749, 0.141, 1)
theme_override_styles/normal = SubResource("StyleBoxFlat_kbd")
text = " SHIFT "

[node name="Label" type="Label" parent="MainVBox/FooterBar/Margin/HBox/KeysRow/ShiftKey"]
layout_mode = 2
theme_override_colors/font_color = Color(0.612, 0.64, 0.686, 1)
theme_override_font_sizes/font_size = 10
text = "Toggle Advanced Formulas"

[node name="Spacer1" type="Control" parent="MainVBox/FooterBar/Margin/HBox"]
layout_mode = 2
size_flags_horizontal = 3

[node name="StatusLabel" type="Label" parent="MainVBox/FooterBar/Margin/HBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.42, 0.45, 0.5, 1)
theme_override_font_sizes/font_size = 10
text = "STATUS: Click any card to inspect mechanics & visual effects."

[node name="Spacer2" type="Control" parent="MainVBox/FooterBar/Margin/HBox"]
layout_mode = 2
size_flags_horizontal = 3

[node name="ReturnBtn" type="Button" parent="MainVBox/FooterBar/Margin/HBox"]
material = SubResource("ShaderMaterial_return_btn")
custom_minimum_size = Vector2(230, 28)
layout_mode = 2
theme_override_colors/font_color = Color(0, 0, 0, 1)
theme_override_font_sizes/font_size = 11
text = "RETURN TO DUNGEON (LOCKED)"
script = ExtResource("6_sbtn")

[node name="InspectionModal" parent="." instance=ExtResource("7_modal")]
visible = false
layout_mode = 1
'''

with open('scenes/ui/level_up_hud.tscn', 'w', encoding='utf-8') as f:
    f.write(tscn_content.strip() + '\n')
print('DONE')
