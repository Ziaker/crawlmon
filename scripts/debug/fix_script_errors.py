with open('scripts/ui/components/move_inspection_modal.gd', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace(
    "@onready var type_pill: Label = $CenterContainer/ModalCard/Margin/VBox/TopBar/TitleBox/PillsRow/TypePill\n@onready var range_pill: Label = $CenterContainer/ModalCard/Margin/VBox/TopBar/TitleBox/PillsRow/RangePill\n@onready var element_pill: Label = $CenterContainer/ModalCard/Margin/VBox/TopBar/TitleBox/PillsRow/ElementPill",
    "@onready var type_pill: Label = $CenterContainer/ModalCard/Margin/VBox/TopBar/TitleBox/PillsRow/TypePillBox/Margin/TypePill\n@onready var range_pill: Label = $CenterContainer/ModalCard/Margin/VBox/TopBar/TitleBox/PillsRow/RangePillBox/Margin/RangePill\n@onready var element_pill_box: PanelContainer = $CenterContainer/ModalCard/Margin/VBox/TopBar/TitleBox/PillsRow/ElementPillBox\n@onready var element_pill: Label = $CenterContainer/ModalCard/Margin/VBox/TopBar/TitleBox/PillsRow/ElementPillBox/Margin/ElementPill"
)

text = text.replace(
    'element_pill.get_parent().add_theme_stylebox_override("panel", el_pill_sb)',
    'if element_pill_box:\n\t\telement_pill_box.add_theme_stylebox_override("panel", el_pill_sb)'
)

with open('scripts/ui/components/move_inspection_modal.gd', 'w', encoding='utf-8') as f:
    f.write(text)

print("Updated move_inspection_modal.gd")

with open('scripts/ui/level_up_hud.gd', 'r', encoding='utf-8') as f:
    text_hud = f.read()

text_hud = text_hud.replace(
    'h.theme_override_constants.separation = 5',
    'h.add_theme_constant_override("separation", 5)'
)

text_hud = text_hud.replace(
    'slot_box.theme_override_constants.separation = 2',
    'slot_box.add_theme_constant_override("separation", 2)'
)

with open('scripts/ui/level_up_hud.gd', 'w', encoding='utf-8') as f:
    f.write(text_hud)

print("Updated level_up_hud.gd")
