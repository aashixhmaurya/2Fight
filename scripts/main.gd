extends Node2D

var min_gap = 125.0
var left_edge = 60.0
var right_edge = 1220.0
var rounds_to_win = 2
var round_time = 60.0

var wins = [0, 0]
var round_num = 1
var time_left = 60.0
var round_on = false
var match_over = false

@onready var player1 = $player1
@onready var player2 = $player2
@onready var p1_bar = $hud/p1_hp
@onready var p2_bar = $hud/p2_hp


func _ready():
	player1.enemy = player2
	player2.enemy = player1
	p1_bar.max_value = player1.max_health
	p2_bar.max_value = player2.max_health
	update_bars()
	start_round()


func _physics_process(delta):
	keep_apart()
	update_bars()

	if not round_on:
		return

	time_left = max(time_left - delta, 0)
	if time_left == 0:
		var winner = null
		if player1.health > player2.health:
			winner = player1
		elif player2.health > player1.health:
			winner = player2
		end_round(winner)


func _unhandled_input(event):
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	if match_over and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()


func start_round():
	round_on = false
	match_over = false
	time_left = round_time
	player1.reset_fighter()
	player2.reset_fighter()
	set_controls(false)
	update_bars()

	await wait(1.2)
	await wait(0.6)
	round_on = true
	set_controls(true)


func end_round(winner):
	if not round_on:
		return
	round_on = false
	set_controls(false)

	if winner == player1:
		wins[0] += 1
		GameState.winner_number = 1
		GameState.loser_number = 2
	elif winner == player2:
		wins[1] += 1
		GameState.winner_number = 2
		GameState.loser_number = 1

	await wait(2.2)

	# Loser drops into Hell to train against the winner's black shadow.
	if winner != null:
		get_tree().change_scene_to_file("res://scenes/hell.tscn")
		return

	if wins[0] >= rounds_to_win or wins[1] >= rounds_to_win:
		match_over = true
	else:
		round_num += 1
		start_round()


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
