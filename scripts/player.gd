extends CharacterBody2D

@export var player_number = 1
@export var facing = "right"

var speed = 280.0
var jump_power = -820.0
var gravity = 2200.0
var enemy

var health = 100
var max_health = 100
var damage = 10
var knockback = 380.0

var attacking = false
var hurt = false
var hurt_time = 0.35
var hurt_left = 0.0
var already_hit = false
var hit_start_frame = 4
var hit_end_frame = 6

@onready var anim = $AnimatedSprite2D
@onready var hitbox = $hitbox


func _ready():
	anim.animation_finished.connect(attack_done)


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if hurt:
		hurt_left -= delta
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, 1800 * delta)
		if hurt_left <= 0 and is_on_floor():
			hurt = false
			anim.modulate = Color.WHITE
		move_and_slide()
		return

	if attacking:
		if is_on_floor():
			velocity.x = 0
		check_hit()
		move_and_slide()
		return

	var p = "p" + str(player_number) + "_"
	var dir = Input.get_axis(p + "left", p + "right")

	look_at_enemy()

	if Input.is_action_just_pressed(p + "attack"):
		attacking = true
		already_hit = false
		anim.play("attack_" + facing)
		return

	if Input.is_action_just_pressed(p + "jump") and is_on_floor():
		velocity.y = jump_power

	velocity.x = dir * speed

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

	if facing == "right":
		hitbox.position.x = 90
	else:
		hitbox.position.x = -90


func check_hit():
	if already_hit:
		return
	if anim.frame < hit_start_frame or anim.frame > hit_end_frame:
		return
	for body in hitbox.get_overlapping_bodies():
		if body == enemy:
			var side = 1
			if facing == "left":
				side = -1
			enemy.got_hit(damage, side)
			already_hit = true


func got_hit(dmg, from_side):
	attacking = false
	hurt = true
	hurt_left = hurt_time
	health = max(health - dmg, 0)
	velocity = Vector2(from_side * knockback, -180)
	anim.modulate = Color(1, 0.35, 0.35)
	anim.play("hurt_" + facing)
	print(name + " hp " + str(health))


func attack_done():
	attacking = false
