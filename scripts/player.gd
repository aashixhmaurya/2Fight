extends CharacterBody2D

@export var player_number = 1
@export var facing = "right"
@export var is_ai = false
@export var is_shadow = false

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
var shadow_color = Color(0.04, 0.04, 0.06, 0.92)
var ai_attack_range = 150.0
var ai_cooldown = 0.0

@onready var anim = $AnimatedSprite2D
@onready var hitbox = $hitbox


func _ready():
	anim.animation_finished.connect(on_anim_done)
	start_pos = global_position
	start_facing = facing
	apply_look()


func apply_look():
	if is_shadow:
		anim.modulate = shadow_color
	else:
		anim.modulate = Color.WHITE


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
	ai_cooldown = 0.0
	apply_look()
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
			apply_look()
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

	if is_ai:
		run_ai(delta)
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


func run_ai(delta):
	ai_cooldown = max(ai_cooldown - delta, 0.0)
	look_at_enemy()

	if enemy == null:
		velocity.x = move_toward(velocity.x, 0, 1800 * delta)
		move_and_slide()
		anim.play("idle_" + facing)
		return

	var gap = enemy.global_position.x - global_position.x
	var dist = abs(gap)
	var dir = sign(gap)

	if enemy.attacking and dist < ai_attack_range + 40 and is_on_floor() and randf() < 0.55:
		blocking = true
		velocity.x = 0
		anim.play("idle_" + facing)
		anim.pause()
		move_and_slide()
		return

	blocking = false

	if dist <= ai_attack_range and ai_cooldown == 0.0 and is_on_floor():
		attacking = true
		already_hit = false
		ai_cooldown = 0.55 + randf() * 0.35
		anim.play("attack_" + facing)
		return

	if dist > ai_attack_range:
		velocity.x = dir * speed
	elif dist < 90:
		velocity.x = -dir * back_speed
	else:
		velocity.x = move_toward(velocity.x, 0, 1800 * delta)

	if is_on_floor() and dist > 220 and randf() < 0.01:
		velocity.y = jump_power

	move_and_slide()

	anim.speed_scale = 1
	if abs(velocity.x) > 20 and is_on_floor():
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
		anim.modulate = Color(0.5, 0.7, 1) if not is_shadow else Color(0.2, 0.25, 0.4)
		var tw = create_tween()
		tw.tween_property(anim, "modulate", shadow_color if is_shadow else Color.WHITE, 0.25)
	else:
		attacking = false
		hurt = true
		hurt_left = hurt_time
		velocity = Vector2(from_side * knockback, -180)
		anim.modulate = Color(1, 0.35, 0.35) if not is_shadow else Color(0.25, 0.08, 0.08)
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
	apply_look()
	anim.speed_scale = 1
	anim.play("die")


func on_anim_done():
	attacking = false


func is_dead():
	return dead
