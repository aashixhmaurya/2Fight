extends Node2D

var min_gap = 125.0
var left_edge = 60.0
var right_edge = 1220.0
var round_time = 60.0

var time_left = 60.0
var fight_on = false
var fight_over = false

@onready var player1 = $player1
@onready var player2 = $player2
@onready var p1_bar = $hud/p1_hp
@onready var p2_bar = $hud/p2_hp
@onready var title = $hud/title


func _ready():
	setup_roles()
	player1.enemy = player2
	player2.enemy = player1
	p1_bar.max_value = player1.max_health
	p2_bar.max_value = player2.max_health
	update_bars()
	start_fight()


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
		title.text = "HELL — P1 vs Shadow"
	else:
		player2.is_ai = false
		player2.is_shadow = false
		player2.player_number = 2
		player1.is_ai = true
		player1.is_shadow = true
		player1.player_number = 1
		title.text = "HELL — P2 vs Shadow"

	player1.apply_look()
	player2.apply_look()


func _physics_process(delta):
	keep_apart()
	update_bars()

	if not fight_on:
		return

	time_left = max(time_left - delta, 0)
	if time_left == 0:
		var winner = null
		if player1.health > player2.health:
			winner = player1
		elif player2.health > player1.health:
			winner = player2
		end_fight(winner)


func _unhandled_input(event):
	if event.is_action_pressed("restart"):
		get_tree().change_scene_to_file("res://scenes/node_2d.tscn")
	if fight_over and event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://scenes/node_2d.tscn")


func start_fight():
	fight_on = false
	fight_over = false
	time_left = round_time
	player1.reset_fighter()
	player2.reset_fighter()
	set_controls(false)
	update_bars()

	await wait(1.0)
	await wait(0.5)
	fight_on = true
	set_controls(true)


func end_fight(winner):
	if not fight_on:
		return
	fight_on = false
	set_controls(false)
	fight_over = true

	if winner == null:
		title.text = "HELL — Draw  (Enter / R)"
	elif winner.is_shadow:
		title.text = "HELL — Shadow wins  (Enter / R)"
	else:
		title.text = "HELL — You won training  (Enter / R)"


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


func update_bars():
	p1_bar.value = player1.health
	p2_bar.value = player2.health


func wait(seconds):
	var t = Timer.new()
	t.one_shot = true
	t.wait_time = seconds
	t.timeout.connect(t.queue_free)
	add_child(t)
	t.start()
	return t.timeout
