extends Control

## Simple title screen: tap / press start, plus control keys.
const MAIN_SCENE = "res://scenes/node_2d.tscn"
const GOLD = Color(1.0, 0.92, 0.55)
const AMBER = Color(0.95, 0.75, 0.15)

var start_btn: Button
var pulse: Tween
var starting = false


func _ready():
	_build_bg()
	_build_title()
	_build_start()
	_build_controls()
	start_btn.grab_focus()


func _build_bg():
	var bg = TextureRect.new()
	bg.texture = load("res://assets/image.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)


func _build_title():
	var title = Label.new()
	title.text = "2FIGHT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -400
	title.offset_right = 400
	title.offset_top = 90
	title.offset_bottom = 170
	UiTheme.apply_label(title, 64, GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0.55, 0.12, 0.05, 1))
	title.add_theme_constant_override("shadow_offset_x", 6)
	title.add_theme_constant_override("shadow_offset_y", 6)
	add_child(title)


func _build_start():
	var box = StyleBoxFlat.new()
	box.bg_color = Color(0.1, 0.1, 0.12, 0.88)
	box.set_border_width_all(3)
	box.border_color = AMBER
	box.set_corner_radius_all(4)
	box.content_margin_left = 28
	box.content_margin_right = 28
	box.content_margin_top = 18
	box.content_margin_bottom = 18

	var hover = box.duplicate()
	hover.border_color = GOLD
	hover.bg_color = Color(0.16, 0.14, 0.1, 0.94)

	start_btn = Button.new()
	start_btn.text = "TAP TO START"
	start_btn.custom_minimum_size = Vector2(420, 64)
	start_btn.set_anchors_preset(Control.PRESET_CENTER)
	start_btn.offset_left = -210
	start_btn.offset_right = 210
	start_btn.offset_top = -20
	start_btn.offset_bottom = 44
	start_btn.add_theme_font_override("font", UiTheme.pixel_font)
	start_btn.add_theme_font_size_override("font_size", 18)
	start_btn.add_theme_color_override("font_color", Color.WHITE)
	start_btn.add_theme_color_override("font_hover_color", GOLD)
	start_btn.add_theme_color_override("font_focus_color", GOLD)
	start_btn.add_theme_color_override("font_pressed_color", Color(0.1, 0.1, 0.12))
	start_btn.add_theme_stylebox_override("normal", box)
	start_btn.add_theme_stylebox_override("hover", hover)
	start_btn.add_theme_stylebox_override("focus", hover)
	start_btn.add_theme_stylebox_override("pressed", hover)
	start_btn.pressed.connect(_go)
	add_child(start_btn)

	pulse = create_tween().set_loops()
	pulse.tween_property(start_btn, "modulate:a", 0.65, 0.55).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(start_btn, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)


func _build_controls():
	var wrap = VBoxContainer.new()
	wrap.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	wrap.offset_left = -560
	wrap.offset_right = 560
	wrap.offset_top = -160
	wrap.offset_bottom = -36
	wrap.add_theme_constant_override("separation", 12)
	add_child(wrap)

	var head = Label.new()
	head.text = "CONTROLS"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTheme.apply_label(head, 12, AMBER)
	wrap.add_child(head)

	for line in [
		"P1   A D MOVE    W JUMP    F ATTACK    S BLOCK    L-SHIFT POWER",
		"P2   ARROWS MOVE    ENTER ATTACK    DOWN BLOCK    R-SHIFT POWER",
		"R  RESTART",
	]:
		var l = Label.new()
		l.text = line
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTheme.apply_label(l, 8, Color(1, 1, 1, 0.65))
		wrap.add_child(l)


func _unhandled_input(event):
	if starting:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("p1_attack") or event.is_action_pressed("p2_attack"):
		_go()


func _go():
	if starting:
		return
	starting = true
	if pulse:
		pulse.kill()
	start_btn.modulate.a = 1.0
	start_btn.disabled = true
	GameState.reset_all()
	SceneFade.change_scene(MAIN_SCENE)
