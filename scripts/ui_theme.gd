extends Node

## Shared pixel-art font for HUD / titles.
const FONT_PATH = "res://assets/fonts/PressStart2P-Regular.ttf"

var pixel_font: Font


func _ready():
	pixel_font = load(FONT_PATH)


func apply_label(label: Label, size: int = 12, color: Color = Color.WHITE):
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
