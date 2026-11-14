extends CharacterBody2D

@export var player_number = 1
@export var facing = "right"

var speed = 280.0
var back_speed = 200.0
var jump_power = -820.0
var gravity = 2200.0
var enemy

var health = 100
var max_health = 100
var damage = 10
var knockback = 380.0
var block_damage = 0.2

var controls_on = false
var attacking = false
var blocking = false
var hurt = false
var dead = false
var hurt_time = 0.35
var hurt_left = 0.0
var already_hit = false
var hit_start_frame = 4
var hit_end_frame = 6
var start_pos = Vector2.ZERO
var start_facing = "right"

@onready var anim = $AnimatedSprite2D
@onready var hitbox = $hitbox


func _ready():
	anim.animation_finished.connect(on_anim_done)
	start_pos = global_position
	start_facing = facing


func reset_fighter():
	global_position = start_pos
	velocity = Vector2.ZERO
	facing = start_facing
	health = max_health
	dead = false
	hurt = false
	attacking = false
	blocking = false
	hurt_left = 0.0
	already_hit = false
	controls_on = false
	anim.modulate = Color.WHITE
	anim.play("idle_" + facing)
	look_at_enemy()


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if dead:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, 1800 * delta)
		move_and_slide()
		return

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
			velocity.x = move_toward(velocity.x, 0, 1800 * delta)
		check_hit()
		move_and_slide()
		return

	if not controls_on:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, 1800 * delta)
		look_at_enemy()
		move_and_slide()
		anim.play("idle_" + facing)
		return

	var p = "p" + str(player_number) + "_"
	var dir = Input.get_axis(p + "left", p + "right")

	look_at_enemy()

	if Input.is_action_just_pressed(p + "attack"):
		blocking = false
		attacking = true
		already_hit = false
		anim.play("attack_" + facing)
		return

	if is_on_floor() and Input.is_action_pressed(p + "block"):
		blocking = true
		velocity.x = 0
		anim.play("idle_" + facing)
		anim.pause()
		move_and_slide()
		return

	blocking = false

	if Input.is_action_just_pressed(p + "jump") and is_on_floor():
		velocity.y = jump_power

	var going_back = false
	if dir != 0:
		if facing == "right" and dir < 0:
			going_back = true
		if facing == "left" and dir > 0:
			going_back = true

	if dir == 0:
		velocity.x = move_toward(velocity.x, 0, 1800 * delta)
	elif going_back:
		velocity.x = dir * back_speed
	else:
		velocity.x = dir * speed

	move_and_slide()

	anim.speed_scale = 1
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
		if body == enemy and not enemy.dead:
			var side = 1
			if facing == "left":
				side = -1
			enemy.got_hit(damage, side)
			already_hit = true


func got_hit(dmg, from_side):
	if dead:
		return

	var blocked = false
	if blocking:
		if facing == "right" and from_side < 0:
			blocked = true
		if facing == "left" and from_side > 0:
			blocked = true

	if blocked:
		dmg = max(1, int(round(dmg * block_damage)))
		velocity.x = from_side * knockback * 0.5
		anim.modulate = Color(0.5, 0.7, 1)
		var tw = create_tween()
		tw.tween_property(anim, "modulate", Color.WHITE, 0.25)
	else:
		attacking = false
		hurt = true
		hurt_left = hurt_time
		velocity = Vector2(from_side * knockback, -180)
		anim.modulate = Color(1, 0.35, 0.35)
		anim.speed_scale = 1
		anim.play("hurt_" + facing)

	health = max(health - dmg, 0)
	if health == 0:
		die()


func die():
	dead = true
	hurt = false
	attacking = false
	blocking = false
	controls_on = false
	velocity.y = min(velocity.y, -200)
	anim.modulate = Color.WHITE
	anim.speed_scale = 1
	anim.play("die")


func on_anim_done():
	attacking = false


func is_dead():
	return dead
