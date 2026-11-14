extends Node2D

var min_gap = 125.0
var left_edge = 60.0
var right_edge = 1220.0

@onready var player1 = $player1
@onready var player2 = $player2


func _ready():
	player1.enemy = player2
	player2.enemy = player1


func _physics_process(delta):
	var gap = player2.global_position.x - player1.global_position.x
	var both_on_ground = player1.is_on_floor() and player2.is_on_floor()

	if both_on_ground and abs(gap) < min_gap:
		var side = sign(gap)
		if side == 0:
			side = 1
		var push = (min_gap - abs(gap)) / 2 * side
		player1.global_position.x -= push
		player2.global_position.x += push

	player1.global_position.x = clamp(player1.global_position.x, left_edge, right_edge)
	player2.global_position.x = clamp(player2.global_position.x, left_edge, right_edge)
