extends CharacterBody2D

enum {
	MOVE,
	ATTACK,
	ATTACK2,
	ATTACK3,
	BLOCK,
	SLIDE,
	DAMAGE,
	CAST,
	DEATH
}

const SPEED = 150.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = $AnimatedSprite2D
@onready var animPlayer = $AnimationPlayer
@onready var stats = $stats
@onready var leafs: GPUParticles2D = $Leafs


var state = MOVE
var run_speed = 1
var combo = false 
var attack_cooldown = false
var damage_basic = 10
var damage_multiplier = 1
var damage_current
var recovery = false

func _ready() -> void:
	Signals.connect("enemy_attack", Callable (self, "_on_damage_received"))
	

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	if velocity.y > 0:
		animPlayer.play("Fall")
		
	Global.player_damage = damage_basic * damage_multiplier
		
	
	match state:
		MOVE:
			move_state()
		ATTACK:
			attack_state()
		ATTACK2:
			attack2_state()
		ATTACK3:
			attack_state3()
		BLOCK:
			block_state()
		SLIDE:
			slide_state()
		DEATH:
			death_state()
		DAMAGE:
			damage_state()
	
	move_and_slide()
	
	Global.player_pos = self.position
	
func move_state ():
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED * run_speed
		if velocity.y == 0:
			if run_speed == 1:
				animPlayer.play("Walk")
			else:
				animPlayer.play("Run")
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0:
			animPlayer.play("Idol")
	if direction == -1:
		$AnimatedSprite2D.flip_h = true
		$AttackDiriction.rotation_degrees = 180
	elif direction == 1:
		$AnimatedSprite2D.flip_h = false
		$AttackDiriction.rotation_degrees = 0
		
	if Input.is_action_pressed("run") and not recovery:
		run_speed = 1.5
		stats.stamina -= stats.run_cost
	else:
		run_speed = 1 
	if Input.is_action_just_pressed("attack"):
		if recovery == false:
			stats.stamina_cost = stats.attack_cost
			if attack_cooldown == false and stats.stamina > stats.stamina_cost:
				state = ATTACK
	
	if Input.is_action_just_pressed("slide") and velocity.x != 0:
		if recovery == false:
			stats.stamina_cost = stats.slide_coct
			if stats.stamina > stats.stamina_cost:
				state = SLIDE
		
	elif Input.is_action_pressed("slide") and velocity.x == 0:
		if recovery == false:
			if stats.stamina > 1:
				state = BLOCK

func attack_state():
	stats.stamina_cost = stats.attack_cost
	damage_multiplier = 1
	if Input.is_action_just_pressed("attack") and combo == true and stats.stamina > stats.stamina_cost:
		state = ATTACK2
	velocity.x = move_toward(velocity.x, 0, SPEED)
	animPlayer.play("Attack")
	await animPlayer.animation_finished
	attack_freeze()
	state = MOVE
	
func block_state ():
	stats.stamina -= stats.block_cost
	velocity.x = move_toward(velocity.x, 0, SPEED)
	animPlayer.play("Block")
	if Input.is_action_just_released("slide") or recovery == true:
		state = MOVE
		
func slide_state():
	animPlayer.play("Slide")
	await animPlayer.animation_finished
	state = MOVE
	
func death_state ():
	velocity.x =0
	animPlayer.play ("Death")
	await animPlayer.animation_finished
	queue_free()
	get_tree().change_scene_to_file.bind("res://menu.tscn").call_deferred()

func combo1 ():
	combo = true 
	await animPlayer.animation_finished
	combo = false 
	
func attack2_state():
	stats.stamina_cost = stats.attack_cost
	damage_multiplier = 1.2
	if Input.is_action_just_pressed("attack") and combo == true and stats.stamina > stats.stamina_cost: 
		state = ATTACK3
	animPlayer.play ("Attack2")
	await animPlayer.animation_finished
	state = MOVE
	
func combo2():
	combo = true
	await animPlayer.animation_finished
	combo = false
	
func attack_state3():
	damage_multiplier = 2
	animPlayer.play ("Attack3")
	await animPlayer.animation_finished
	state = MOVE

func attack_freeze ():
	attack_cooldown = true 
	await get_tree().create_timer(0.5).timeout
	attack_cooldown = false 
	
func damage_state ():
	animPlayer.play ("Damage")
	await animPlayer.animation_finished
	state = MOVE
	
func _on_damage_received (enemy_damage):
	if state == BLOCK:
		enemy_damage /= 2
	elif state == SLIDE:
		enemy_damage = 0
	else:
		state = DAMAGE
		damage_anim()
	stats.health -= enemy_damage
	if stats.health <= 0:
		stats.health = 0
		state = DEATH

func _on_stats_no_stamina() -> void:
	recovery = true
	await get_tree().create_timer(2).timeout
	recovery = false

func damage_anim ():
	velocity.x = 0
	self.modulate = Color (1, 0, 0, 1)
	if $AnimatedSprite2D.flip_h == true:
		velocity.x += 200
	else:
		velocity.x -= 200
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(self, "velocity", Vector2(0, 0), 0.1)
	tween.parallel().tween_property(self, "modulate", Color (1, 1, 1, 1), 0.1 )
	
func steps ():
	leafs.emitting = true
	leafs.one_shot = true
