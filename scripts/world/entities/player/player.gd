extends CharacterBody2D
class_name Player

signal damaged(current_health: int)

@onready var resource_manager: ResourceManager = %ResourceManager
@onready var shop_manager: ShopManager = %ShopManager
@onready var game_over_manager: GameOverManager = %GameOverManager
@onready var camera_shake_manager = %CameraShakeManager
@onready var freeze_frame_manager = %FreezeFrameManager

@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var animation: AnimationComponent = $AnimationComponent
@onready var melee_weapon: MeleeWeapon = $MeleeWeapon
@onready var dash: DashComponent = $DashComponent
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var dash_particles: GPUParticles2D = $DashParticles
@onready var flash_vfx: FlashVfx = $FlashVFX
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var player_knockback := 200.0
@export var player_body_damage := 5
@export var death_knockback_force := 400.0 ## Exact knockback force on killing blow
@export var freeze_on_damage := true ## Freeze frame when taking damage
@export var damage_freeze_duration := 0.04 ## Freeze duration on normal damage
@export var death_freeze_duration := 0.08 ## Freeze duration on killing blow

var can_move := true

const SHOOT_COST := 1
const SLASH_SELF_KNOCKBACK := 50.0
const MIN_MOVE_SPEED := 10.0

func _ready():
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	melee_weapon.slash_started.connect(_on_slash_started)
	dash.dash_started.connect(_on_dash_started)
	dash.dash_ended.connect(_on_dash_ended)
	shop_manager.turret_placement_started.connect(_on_turret_placement_started)
	shop_manager.turret_placement_ended.connect(_on_turret_placement_ended)

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	knockback.process(delta)
	
	if dash.is_dashing():
		velocity = dash.get_dash_velocity()
		# Use move_and_collide for fixed-distance dash without wall sliding
		var collision = move_and_collide(velocity * delta)
		if collision:
			dash.cancel_dash()
	else:
		if knockback.is_active():
			velocity = knockback.velocity
		elif can_move:
			velocity = movement.calculate_velocity(velocity, input_dir, delta)
		else:
			velocity = Vector2.ZERO
		
		move_and_slide()
	
	_update_animation()
	
	if animation.current_state != AnimationComponent.State.SLASH:
		_set_sprite_direction(velocity.x)

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("shoot") and resource_manager.can_buy(SHOOT_COST):
		if shoot.try_shoot(get_global_mouse_position(), global_position):
			resource_manager.subtract_scrap(SHOOT_COST)
	
	if event.is_action_pressed("slash"):
		melee_weapon.try_slash(get_global_mouse_position())
	
	if event.is_action_pressed("dash"):
		var dash_dir = _get_dash_direction()
		dash.try_dash(dash_dir)

func _update_animation():
	if is_dead():
		animation.set_state(AnimationComponent.State.DIE)
		return
	
	if velocity.length() > MIN_MOVE_SPEED:
		animation.set_state(AnimationComponent.State.MOVE)
	else:
		animation.set_state(AnimationComponent.State.IDLE)

func _set_sprite_direction(dir_x: float):
	if dir_x != 0:
		animated_sprite.flip_h = dir_x < 0

func _get_dash_direction() -> Vector2:
	# If moving, dash in movement direction
	if velocity.length() > MIN_MOVE_SPEED:
		return velocity.normalized()
	
	# If idle, dash in the direction sprite is facing
	if animated_sprite.flip_h:
		return Vector2.LEFT
	else:
		return Vector2.RIGHT

func _on_slash_started(target_pos: Vector2):
	_set_sprite_direction(target_pos.x - global_position.x)
	animation.set_state(AnimationComponent.State.SLASH)

func _on_dash_started(direction: Vector2):
	_set_sprite_direction(direction.x)
	animation.set_state(AnimationComponent.State.DASH)
	
	# Light screen shake on dash
	camera_shake_manager.shake_screen(0.15, 0.15)
	
	if dash_particles:
		dash_particles.emitting = true

func _on_dash_ended():
	if dash_particles:
		dash_particles.emitting = false

func take_damage(amount: int, knockback_force: float, from_position: Vector2) -> void:
	if is_dead() or dash.is_invincible():
		return
	
	# Apply damage first
	health.take_damage(amount)
	
	# Check if this was the killing blow
	var is_killing_blow = is_dead()
	
	# Apply knockback (use death force if killed)
	var kb_force = death_knockback_force if is_killing_blow else knockback_force
	knockback.apply(from_position, kb_force)
	
	# Hit particles (always)
	if hit_particles:
		hit_particles.restart()
	
	# Screen shake (skip on death - sequence handles it)
	if not is_killing_blow:
		camera_shake_manager.shake_screen(0.2, 0.3)
	
	# Freeze frames
	if freeze_on_damage and freeze_frame_manager:
		var freeze_time = death_freeze_duration if is_killing_blow else damage_freeze_duration
		freeze_frame_manager.freeze(freeze_time)

func _on_died():
	emit_signal("damaged", 0)
	
	# Disable player controls and collision
	can_move = false
	shoot.set_enabled(false)
	melee_weapon.set_enabled(false)
	collision_shape.set_deferred("disabled", true)
	
	# Death flash VFX
	if flash_vfx:
		flash_vfx.start()
	
	# Play death animation
	animation.set_state(AnimationComponent.State.DIE)

func _on_damaged(current_health: int):
	animation.set_state(AnimationComponent.State.DAMAGE)
	emit_signal("damaged", current_health)

func is_dead():
	return health.is_dead()

func get_health():
	return health.get_current_health()

func collect_scrap(amount: int) -> void:
	resource_manager.add_scrap(amount)

func set_shooting_enabled(enabled: bool):
	shoot.set_enabled(enabled)

func set_slashing_enabled(enabled: bool):
	melee_weapon.set_enabled(enabled)

func _on_turret_placement_started():
	shoot.set_enabled(false)
	melee_weapon.set_enabled(false)

func _on_turret_placement_ended():
	shoot.set_enabled(true)
	melee_weapon.set_enabled(true)
