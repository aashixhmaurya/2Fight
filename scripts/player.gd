extends CharacterBody2D

@export var player_number = 1

var speed = 280.0
var jump_power = -820.0
var gravity = 2200.0
var facing = "right"

@onready var anim = $AnimatedSprite2D


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	var p = "p" + str(player_number) + "_"
	var dir = Input.get_axis(p + "left", p + "right")

	if Input.is_action_just_pressed(p + "jump") and is_on_floor():
		velocity.y = jump_power

	velocity.x = dir * speed

	if dir > 0:
		facing = "right"
	elif dir < 0:
		facing = "left"

	move_and_slide()

	if dir != 0 and is_on_floor():
		anim.play("run_" + facing)
	else:
		anim.play("idle_" + facing)
