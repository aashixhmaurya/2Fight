extends Node2D

var min_gap = 125.0
var left_edge = 60.0
var right_edge = 1220.0

var fight_on = false
var fight_over = false
var returning = false
var p1_shown_hp = 100.0
var p2_shown_hp = 100.0
var hp_anim_speed = 90.0

@onready var player1 = $player1
@onready var player2 = $player2
@onready var p1_bar = $hud/p1_hp
@onready var p2_bar = $hud/p2_hp
@onready var title = $hud/title
@onready var hud = $hud

var p1_hp_text: Label
var p2_hp_text: Label
var intro_layer: ColorRect
var intro_label: Label


func _ready():
	setup_roles()
	player1.enemy = player2
	player2.enemy = player1
	_build_hud_extras()
	UiTheme.apply_label(title, 14, Color(1, 0.55, 0.25, 1))
	title.text = "HELL"
	start_fight()


func _build_hud_extras():
	p1_hp_text = Label.new()
	p1_hp_text.name = "p1_hp_text"
	p1_hp_text.offset_left = 40
	p1_hp_text.offset_top = 16
	p1_hp_text.offset_right = 220
	p1_hp_text.offset_bottom = 36
	UiTheme.apply_label(p1_hp_text, 10, Color(1, 1, 1, 0.9))
	hud.add_child(p1_hp_text)

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

	intro_layer = ColorRect.new()
	intro_layer.name = "intro_layer"
	intro_layer.color = Color(0.15, 0.02, 0.02, 0)
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
	UiTheme.apply_label(intro_label, 36, Color(1.0, 0.55, 0.25))
	hud.add_child(intro_label)


func setup_roles():
	var loser = GameState.loser_number

	# Human loser keeps their own controls and normal look.
	# Winner's body becomes a black shadow NPC.
	if loser == 1:
		player1.is_ai = false
		player1.is_shadow = false
		player1.player_number = 1
		player2.is_ai = true
		player2.is_shadow = true
		player2.player_number = 2
		title.text = "HELL"
	else:
		player2.is_ai = false
		player2.is_shadow = false
		player2.player_number = 2
		player1.is_ai = true
		player1.is_shadow = true
		player1.player_number = 1
		title.text = "HELL"

	player1.apply_look()
	player2.apply_look()


func _physics_process(delta):
	keep_apart()
	update_bars(delta)


func _unhandled_input(event):
	if returning:
		return
	if event.is_action_pressed("restart"):
		_full_restart()
	if fight_over and event.is_action_pressed("ui_accept"):
		_full_restart()


func start_fight():
	fight_on = false
	fight_over = false
	player1.reset_fighter()
	player2.reset_fighter()
	p1_bar.max_value = player1.max_health
	p2_bar.max_value = player2.max_health
	p1_shown_hp = player1.health
	p2_shown_hp = player2.health
	set_controls(false)
	update_bars(0.0)

	await _play_hell_intro()
	fight_on = true
	set_controls(true)


func _play_hell_intro():
	intro_layer.visible = true
	intro_label.visible = true
	intro_layer.color = Color(0.12, 0.02, 0.02, 0)
	intro_label.modulate = Color(1.0, 0.55, 0.25, 0.0)
	intro_label.text = "HELL"

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(intro_layer, "color:a", 0.75, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(intro_label, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished

	await wait(0.85)

	intro_label.modulate.a = 0.0
	intro_label.text = "FIGHT"
	var fight_in = create_tween()
	fight_in.tween_property(intro_label, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fight_in.finished

	await wait(0.35)

	var fade = create_tween()
	fade.set_parallel(true)
	fade.tween_property(intro_layer, "color:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade.tween_property(intro_label, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade.finished

	intro_layer.visible = false
	intro_label.visible = false


func end_fight(winner):
	if not fight_on:
		return
	fight_on = false
	set_controls(false)
	fight_over = true

	# Lose in Hell = game over. Ground winner takes the match.
	if winner == null or winner.is_shadow:
		returning = true
		var champ = GameState.winner_number
		title.text = "GAME OVER  P%d WINS" % champ
		await wait(2.0)
		_full_restart()
		return

	# Win Hell → final power round on ground (no Hell after that).
	returning = true
	var rewarded = GameState.loser_number
	GameState.grant_special(rewarded)
	GameState.power_round = true
	title.text = "HELL CLEAR - FINAL"
	await wait(1.4)
	GameState.resume_from_hell = true
	SceneFade.change_scene("res://scenes/node_2d.tscn")


func _full_restart():
	returning = true
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

	if fight_on:
		if player1.dead and player2.dead:
			end_fight(null)
		elif player1.dead:
			end_fight(player2)
		elif player2.dead:
			end_fight(player1)


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


func wait(seconds):
	var t = Timer.new()
	t.one_shot = true
	t.wait_time = seconds
	t.timeout.connect(t.queue_free)
	add_child(t)
	t.start()
	return t.timeout
