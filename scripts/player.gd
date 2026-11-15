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
var heal_amount = 40 ## +40 HP on Shift heart (never above max_health 100)
var heart_ready = false

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
var special_color = Color(0.45, 0.78, 1.0, 1.0)
var ai_attack_range = 150.0
var ai_cooldown = 0.0
var special_ready = false
var special_active = false
var special_duration = 4.0
var special_left = 0.0
var glow_mat: ShaderMaterial
var aura: AnimatedSprite2D
var glow_pulse_t = 0.0

@onready var anim = $AnimatedSprite2D
@onready var hitbox = $hitbox


func _ready():
	# Collide with ground/walls only — fighters pass through each other in air.
	collision_layer = 2
	collision_mask = 1
	anim.animation_finished.connect(on_anim_done)
	start_pos = global_position
	start_facing = facing
	_setup_special_fx()
	apply_look()


func _setup_special_fx():
	var sh = load("res://shaders/special_glow.gdshader")
	if sh:
		glow_mat = ShaderMaterial.new()
		glow_mat.shader = sh
		glow_mat.set_shader_parameter("enabled", 0.0)
		glow_mat.set_shader_parameter("pulse", 0.0)
		glow_mat.set_shader_parameter("glow_strength", 2.2)
		anim.material = glow_mat

	# Bigger cyan/orange silhouette behind the fighter = visible flame-edge glow.
	aura = AnimatedSprite2D.new()
	aura.name = "AuraGlow"
	aura.sprite_frames = anim.sprite_frames
	aura.scale = anim.scale * 1.18
	aura.offset = anim.offset
	aura.z_index = -1
	aura.visible = false
	aura.modulate = Color(0.25, 0.85, 1.0, 0.75)
	add_child(aura)
	move_child(aura, 0)


func apply_look():
	if is_shadow:
		anim.modulate = shadow_color
		_set_glow(false)
	elif special_active:
		anim.modulate = special_color
		_set_glow(true)
	else:
		anim.modulate = Color.WHITE
		_set_glow(false)


func _set_glow(on: bool):
	if glow_mat:
		glow_mat.set_shader_parameter("enabled", 1.0 if on else 0.0)
	if aura:
		aura.visible = on
		if on:
			_sync_aura()


func reset_fighter():
	global_position = start_pos
	velocity = Vector2.ZERO
	facing = start_facing
	max_health = 100
	health = max_health
	dead = false
	hurt = false
	attacking = false
	blocking = false
	hurt_left = 0.0
	already_hit = false
	controls_on = false
	ai_cooldown = 0.0
	# Keep heart_ready / special_ready across round resets; cancel mid-burst only.
	if special_active:
		end_special(false)
	apply_look()
	anim.play("idle_" + facing)
	look_at_enemy()


func _sync_aura():
	if aura == null or not aura.visible:
		return
	aura.animation = anim.animation
	aura.frame = anim.frame
	aura.flip_h = anim.flip_h
	aura.offset = anim.offset


func _physics_process(delta):
	if special_active:
		special_left = max(special_left - delta, 0.0)
		glow_pulse_t += delta * 10.0
		var pulse = 0.5 + 0.5 * sin(glow_pulse_t)
		if glow_mat:
			glow_mat.set_shader_parameter("pulse", pulse)
		if aura:
			# Flicker between icy blue and flame orange while power is on.
			var c = Color(0.2, 0.8, 1.0, 0.55 + 0.35 * pulse).lerp(Color(1.0, 0.45, 0.1, 0.7), pulse * 0.55)
			aura.modulate = c
			aura.scale = anim.scale * (1.12 + 0.12 * pulse)
			_sync_aura()
		# Keep body tint pulsing so the glow is obvious for the full 4s.
		anim.modulate = special_color.lerp(Color(1.0, 0.75, 0.45), pulse * 0.35)
		if special_left == 0.0:
			end_special(true)

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

	if Input.is_action_just_pressed(p + "special"):
		# Shift: heart heal (+40, cap 100) or blue x2 power.
		if heart_ready:
			try_activate_heart()
		elif special_ready:
			try_activate_special()

	if Input.is_action_just_pressed(p + "attack"):
		blocking = false
		attacking = true
		already_hit = false
		SFX.play("empty-attack-swing")
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

	# In air, full speed either way so jump-overs aren't slowed when facing flips.
	var going_back = false
	if dir != 0 and is_on_floor():
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

	# Don't chase under a jump-over — hold X so the player can pass like vs a human.
	var enemy_airborne = not enemy.is_on_floor()
	var jump_cross = enemy_airborne and dist < 200 and enemy.global_position.y < global_position.y - 30
	if jump_cross:
		blocking = false
		velocity.x = move_toward(velocity.x, 0, 2400 * delta)
		move_and_slide()
		anim.play("idle_" + facing)
		return

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
		SFX.play("empty-attack-swing")
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
			var hit_damage = damage * 2 if special_active else damage
			enemy.got_hit(hit_damage, side)
			already_hit = true


func try_activate_heart():
	if is_ai or is_shadow or dead or not controls_on:
		return
	if not heart_ready:
		return
	heart_ready = false
	GameState.consume_heart(player_number)
	# Fill +40 HP, never above 100. Bar animates smoothly in main.
	health = mini(health + heal_amount, max_health)
	var flash = create_tween()
	flash.tween_property(anim, "modulate", Color(1.0, 0.55, 0.7), 0.12)
	flash.tween_property(anim, "modulate", special_color if special_active else Color.WHITE, 0.3)


func try_activate_special():
	if is_ai or is_shadow or dead or not controls_on:
		return
	if not special_ready or special_active:
		return
	special_ready = false
	special_active = true
	special_left = special_duration
	glow_pulse_t = 0.0
	GameState.consume_special(player_number)
	apply_look()
	_set_glow(true)


func end_special(consumed: bool):
	special_active = false
	special_left = 0.0
	if consumed:
		special_ready = false
	_set_glow(false)
	apply_look()


func special_bar_value() -> float:
	if special_active:
		return (special_left / special_duration) * 100.0
	if special_ready:
		return 100.0
	return 0.0


func has_power_ui() -> bool:
	return special_ready or special_active


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
		tw.tween_property(anim, "modulate", shadow_color if is_shadow else (special_color if special_active else Color.WHITE), 0.25)
	else:
		attacking = false
		hurt = true
		hurt_left = hurt_time
		velocity = Vector2(from_side * knockback, -180)
		anim.modulate = Color(1, 0.35, 0.35) if not is_shadow else Color(0.25, 0.08, 0.08)
		anim.speed_scale = 1
		anim.play("hurt_" + facing)
		SFX.play("damage")

	health = max(health - dmg, 0)
	if health == 0:
		die()


func die():
	dead = true
	hurt = false
	attacking = false
	blocking = false
	controls_on = false
	if special_active:
		end_special(true)
	velocity.y = min(velocity.y, -200)
	apply_look()
	anim.speed_scale = 1
	anim.play("die")
	SFX.play_death_for(player_number)


func on_anim_done():
	attacking = false


func is_dead():
	return dead
