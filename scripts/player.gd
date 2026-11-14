extends CharacterBody2D

@export var player_number = 1
@export var facing = "right"

var speed = 280.0
var jump_power = -820.0
var gravity = 2200.0
var enemy

@onready var anim = $AnimatedSprite2D


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	var p = "p" + str(player_number) + "_"
	var dir = Input.get_axis(p + "left", p + "right")

	if Input.is_action_just_pressed(p + "jump") and is_on_floor():
		velocity.y = jump_power

	velocity.x = dir * speed

	look_at_enemy()

	move_and_slide()

	if dir != 0 and is_on_floor():
		anim.play("run_" + facing)
	else:
		anim.play("idle_" + facing)


func look_at_enemy():
	if enemy == null:
		return
	var gap = enemy.global_position.x - global_position.x
	if gap > 4:
		facing = "right"
	elif gap < -4:
		facing = "left"
