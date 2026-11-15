extends Node2D

var min_gap = 125.0
var left_edge = 60.0
var right_edge = 1220.0

var round_num = 1
var round_on = false
var power_round = false
var match_over = false
var p1_shown_hp = 100.0
var p2_shown_hp = 100.0
var hp_anim_speed = 90.0

@onready var player1 = $player1
@onready var player2 = $player2
@onready var p1_bar = $hud/p1_hp
@onready var p2_bar = $hud/p2_hp
@onready var hud = $hud

var p1_power: ProgressBar
var p2_power: ProgressBar
var p1_heart: TextureRect
var p2_heart: TextureRect
var p1_hp_text: Label
var p2_hp_text: Label
var heart_tex: Texture2D
var round_label: Label
var center_msg: Label
var intro_layer: ColorRect
var intro_label: Label


func _ready():
	player1.enemy = player2
	player2.enemy = player1
	heart_tex = load("res://assets/ui/heart_ui.png")
	_build_power_bars()
	_build_heart_ui()
	_build_round_ui()
	_build_intro_ui()
	_restore_from_hell_if_needed()
	_sync_hp_bar_max()
	p1_shown_hp = player1.health
	p2_shown_hp = player2.health
	update_bars(0.0)
	start_round()


func _build_power_bars():
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.12, 0.2, 0.9)
	bg.set_border_width_all(2)
	bg.border_color = Color(0.45, 0.7, 1.0, 0.95)
	bg.set_corner_radius_all(3)

	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.25, 0.7, 1.0, 1)
	fill.set_corner_radius_all(2)

	p1_power = ProgressBar.new()
	p1_power.name = "p1_power"
	p1_power.max_value = 100
	p1_power.value = 0
	p1_power.show_percentage = false
	p1_power.visible = false
	p1_power.offset_left = 40
	p1_power.offset_top = 76
	p1_power.offset_right = 220
	p1_power.offset_bottom = 92
	p1_power.add_theme_stylebox_override("background", bg)
	p1_power.add_theme_stylebox_override("fill", fill)
	hud.add_child(p1_power)

	var bg2 = bg.duplicate()
	var fill2 = fill.duplicate()

	p2_power = ProgressBar.new()
	p2_power.name = "p2_power"
	p2_power.max_value = 100
	p2_power.value = 0
	p2_power.show_percentage = false
	p2_power.visible = false
	p2_power.fill_mode = ProgressBar.FILL_BEGIN_TO_END
	p2_power.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p2_power.offset_left = -220
	p2_power.offset_top = 76
	p2_power.offset_right = -40
	p2_power.offset_bottom = 92
	p2_power.add_theme_stylebox_override("background", bg2)
	p2_power.add_theme_stylebox_override("fill", fill2)
	hud.add_child(p2_power)


func _build_heart_ui():
	p1_heart = TextureRect.new()
	p1_heart.name = "p1_heart"
	p1_heart.texture = heart_tex
	p1_heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p1_heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p1_heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p1_heart.visible = false
	p1_heart.offset_left = 40
	p1_heart.offset_top = 98
	p1_heart.offset_right = 76
	p1_heart.offset_bottom = 134
	p1_heart.pivot_offset = Vector2(18, 18)
	hud.add_child(p1_heart)

	p1_hp_text = Label.new()
	p1_hp_text.name = "p1_hp_text"
	p1_hp_text.offset_left = 40
	p1_hp_text.offset_top = 16
	p1_hp_text.offset_right = 220
	p1_hp_text.offset_bottom = 36
	UiTheme.apply_label(p1_hp_text, 10, Color(1, 1, 1, 0.9))
	hud.add_child(p1_hp_text)

	p2_heart = TextureRect.new()
	p2_heart.name = "p2_heart"
	p2_heart.texture = heart_tex
	p2_heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p2_heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p2_heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p2_heart.visible = false
	p2_heart.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p2_heart.offset_left = -76
	p2_heart.offset_top = 98
	p2_heart.offset_right = -40
	p2_heart.offset_bottom = 134
	p2_heart.pivot_offset = Vector2(18, 18)
	hud.add_child(p2_heart)

	p2_hp_text = Label.new()
	p2_hp_text.name = "p2_hp_text"
	p2_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	p2_hp_text.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p2_hp_text.offset_left = -220
	p2_hp_text.offset_top = 16
	p2_hp_text.offset_right = -40
	p2_hp_text.offset_bottom = 36
	UiTheme.apply_label(p2_hp_text, 10, Color(1, 1, 1, 0.9))
	hud.add_child(p2_hp_text)


func _build_round_ui():
	round_label = Label.new()
	round_label.name = "round_label"
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	round_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	round_label.offset_left = -220
	round_label.offset_top = 18
	round_label.offset_right = 220
	round_label.offset_bottom = 52
	UiTheme.apply_label(round_label, 14, Color(1.0, 0.92, 0.55))
	hud.add_child(round_label)

	center_msg = Label.new()
	center_msg.name = "center_msg"
	center_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_msg.set_anchors_preset(Control.PRESET_CENTER)
	center_msg.offset_left = -360
	center_msg.offset_top = -24
	center_msg.offset_right = 360
	center_msg.offset_bottom = 40
	center_msg.visible = false
	UiTheme.apply_label(center_msg, 22, Color(1.0, 0.85, 0.35))
	hud.add_child(center_msg)

	_refresh_round_text()


func _build_intro_ui():
	intro_layer = ColorRect.new()
	intro_layer.name = "intro_layer"
	intro_layer.color = Color(0, 0, 0, 0)
	intro_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_layer.visible = false
	hud.add_child(intro_layer)

	intro_label = Label.new()
	intro_label.name = "intro_label"
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intro_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_label.visible = false
	intro_label.modulate.a = 0.0
	UiTheme.apply_label(intro_label, 36, Color(1.0, 0.95, 0.7))
	hud.add_child(intro_label)


func _refresh_round_text():
	if power_round:
		round_label.text = "FINAL"
	else:
		round_label.text = "ROUND %d" % round_num


func _restore_from_hell_if_needed():
	if not GameState.resume_from_hell:
		return
	round_num = GameState.round_num + 1
	power_round = true
	GameState.power_round = true
	player1.special_ready = GameState.has_special(1)
	player2.special_ready = GameState.has_special(2)
	player1.heart_ready = GameState.has_heart(1)
	player2.heart_ready = GameState.has_heart(2)
	GameState.clear_resume()
	_refresh_round_text()


func _sync_hp_bar_max():
	p1_bar.max_value = player1.max_health
	p2_bar.max_value = player2.max_health


func _physics_process(delta):
	keep_apart()
	update_bars(delta)


func _unhandled_input(event):
	if event.is_action_pressed("restart"):
		GameState.reset_all()
		get_tree().reload_current_scene()
	if match_over and event.is_action_pressed("ui_accept"):
		GameState.reset_all()
		get_tree().reload_current_scene()


func start_round():
	round_on = false
	match_over = false
	center_msg.visible = false
	player1.reset_fighter()
	player2.reset_fighter()
	_sync_hp_bar_max()
	p1_shown_hp = player1.health
	p2_shown_hp = player2.health
	set_controls(false)
	_refresh_round_text()
	update_bars(0.0)

	await _play_round_intro()
	round_on = true
	set_controls(true)


func _play_round_intro():
	intro_layer.visible = true
	intro_label.visible = true
	intro_layer.color = Color(0, 0, 0, 0)
	intro_label.modulate = Color(1.0, 0.95, 0.7, 0.0)
	intro_label.text = "FINAL" if power_round else ("ROUND %d" % round_num)

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(intro_layer, "color:a", 0.72, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(intro_label, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished

	await wait(0.9)

	intro_label.modulate.a = 0.0
	intro_label.text = "FIGHT"
	var fight_in = create_tween()
	fight_in.tween_property(intro_label, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fight_in.finished

	await wait(0.4)

	var fade = create_tween()
	fade.set_parallel(true)
	fade.tween_property(intro_layer, "color:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade.tween_property(intro_label, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade.finished

	intro_layer.visible = false
	intro_label.visible = false


func end_round(winner):
	if not round_on:
		return
	round_on = false
	set_controls(false)

	if winner == player1:
		GameState.winner_number = 1
		GameState.loser_number = 2
	elif winner == player2:
		GameState.winner_number = 2
		GameState.loser_number = 1

	await wait(1.2)

	# Final power round (after Hell clear): KO = game over, no more Hell.
	if power_round:
		await _game_over(winner)
		return

	# First ground round: loser goes to Hell. Winner gets heart for the final.
	if winner != null:
		GameState.grant_heart(GameState.winner_number)
		GameState.save_match(round_num)
		SceneFade.go_to_hell()
		return

	round_num += 1
	start_round()


func _game_over(winner):
	match_over = true
	if winner == null:
		center_msg.text = "GAME OVER  DRAW"
	elif winner == player1:
		center_msg.text = "GAME OVER  P1 WINS"
	else:
		center_msg.text = "GAME OVER  P2 WINS"
	center_msg.visible = true
	await wait(2.2)
	GameState.reset_all()
	SceneFade.change_scene("res://scenes/node_2d.tscn")


func keep_apart():
	var gap = player2.global_position.x - player1.global_position.x
	var both_on_ground = player1.is_on_floor() and player2.is_on_floor()

	if both_on_ground and abs(gap) < min_gap:
		var side = sign(gap)
		if side == 0:
			side = 1
		var need = min_gap - abs(gap)
		var p1_pushing = player1.velocity.x * side > 0
		var p2_pushing = player2.velocity.x * (-side) > 0

		if p1_pushing and not p2_pushing:
			player1.global_position.x -= need * side
			player1.velocity.x = 0
		elif p2_pushing and not p1_pushing:
			player2.global_position.x += need * side
			player2.velocity.x = 0
		else:
			player1.global_position.x -= need * 0.5 * side
			player2.global_position.x += need * 0.5 * side
			if p1_pushing:
				player1.velocity.x = 0
			if p2_pushing:
				player2.velocity.x = 0

	player1.global_position.x = clamp(player1.global_position.x, left_edge, right_edge)
	player2.global_position.x = clamp(player2.global_position.x, left_edge, right_edge)

	if round_on:
		if player1.dead and player2.dead:
			end_round(null)
		elif player1.dead:
			end_round(player2)
		elif player2.dead:
			end_round(player1)


func set_controls(on):
	player1.controls_on = on
	player2.controls_on = on


func update_bars(delta: float):
	p1_bar.max_value = max(player1.max_health, 1)
	p2_bar.max_value = max(player2.max_health, 1)

	if delta <= 0.0:
		p1_shown_hp = player1.health
		p2_shown_hp = player2.health
	else:
		p1_shown_hp = move_toward(p1_shown_hp, float(player1.health), hp_anim_speed * delta)
		p2_shown_hp = move_toward(p2_shown_hp, float(player2.health), hp_anim_speed * delta)

	p1_bar.value = p1_shown_hp
	p2_bar.value = p2_shown_hp
	p1_hp_text.text = "%d/%d" % [int(round(p1_shown_hp)), int(player1.max_health)]
	p2_hp_text.text = "%d/%d" % [int(round(p2_shown_hp)), int(player2.max_health)]

	_update_power_bar(p1_power, player1)
	_update_power_bar(p2_power, player2)
	p1_heart.visible = player1.heart_ready
	p2_heart.visible = player2.heart_ready


func _update_power_bar(bar: ProgressBar, fighter):
	var show = fighter.has_power_ui()
	bar.visible = show
	bar.value = fighter.special_bar_value()
	if fighter.special_active:
		bar.modulate = Color(0.75, 0.95, 1.0)
	else:
		bar.modulate = Color.WHITE


func wait(seconds):
	var t = Timer.new()
	t.one_shot = true
	t.wait_time = seconds
	t.timeout.connect(t.queue_free)
	add_child(t)
	t.start()
	return t.timeout
