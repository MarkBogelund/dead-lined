extends CharacterBody2D
class_name Player

signal damaged(current_capacity: float)
signal died

@onready var wave_manager: WaveManager = %WaveManager
@onready var shop_manager: ShopManager = %ShopManager
@onready var game_over_manager: GameOverManager = %GameOverManager
@onready var camera_shake_manager: CameraShakeManager = %CameraShakeManager
@onready var freeze_frame_manager: FreezeFrameManager = %FreezeFrameManager

@onready var capacity: CapacityComponent = $CapacityComponent
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var animation: AnimationHandler = $AnimationHandler
@onready var melee_weapon: MeleeWeapon = $MeleeWeapon
@onready var dash: DashComponent = $DashComponent
@onready var aiming: AimingComponent = $AimingComponent
@onready var crunch_time: CrunchTimeComponent = $CrunchTimeComponent
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var stats: PlayerStats

var shoot_cost: float = 2.0
var damage_knockback_force := 200.0
var damage_freeze_duration := 0.1
var damage_screen_shake_intensity := 0.2
var death_knockback_force := 400.0
var death_freeze_duration := 0.15
var death_screen_shake_intensity := 0.35

enum MoveState {NORMAL, DASHING, KNOCKED, FROZEN}

var can_move := true
var _facing_right := true
var _is_dead := false
var _base_velocity := Vector2.ZERO

const MIN_MOVE_SPEED := 10.0
const PLAYER_BODY_LAYER := 2 ## Matches project.godot 2d_physics layer_2 ("PlayerBody")

var _conveyor_velocity := Vector2.ZERO

func set_conveyor_velocity(conveyor_velocity: Vector2) -> void:
	_conveyor_velocity = conveyor_velocity

func clear_conveyor_velocity() -> void:
	_conveyor_velocity = Vector2.ZERO

func _add_conveyor_velocity() -> void:
	velocity += _conveyor_velocity

func _ready() -> void:
	_initialize()
	_setup_animations()
	_connect_signals()

func _initialize() -> void:
	if not stats:
		return
	movement.initialize(stats.speed, stats.acceleration, stats.friction)
	dash.initialize(stats.dash_distance, stats.dash_duration, stats.dash_cooldown)
	melee_weapon.initialize(stats.slash_damage, stats.slash_knockback, stats.slash_self_knockback, stats.slash_radius, stats.slash_arc_angle, stats.slash_duration, stats.slash_cooldown)
	shoot.initialize(stats.shoot_cooldown, stats.projectile_damage, stats.projectile_knockback, stats.projectile_speed)
	capacity.initialize(stats.initial_capacity, stats.max_capacity, stats.crunch_threshold, stats.threshold_step, stats.min_crunch_threshold)
	crunch_time.initialize(
		stats.crunch_activation_cost,
		stats.crunch_deactivation_threshold,
		stats.drain_seconds_per_unit,
		stats.damage_multiplier,
		stats.radius_multiplier,
		stats.speed_multiplier,
		stats.arc_angle_multiplier,
		stats.weapon_size_multiplier,
		stats.cooldown_multiplier)
	shoot_cost = stats.shoot_cost
	damage_knockback_force = stats.damage_knockback_force
	damage_freeze_duration = stats.damage_freeze_duration
	damage_screen_shake_intensity = stats.damage_screen_shake_intensity
	death_knockback_force = stats.death_knockback_force
	death_freeze_duration = stats.death_freeze_duration
	death_screen_shake_intensity = stats.death_screen_shake_intensity

func _setup_animations() -> void:
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("move", 1, false)
	animation.configure_animation("slash", 2, true)
	animation.configure_animation("dash", 2, true)
	animation.configure_animation("take_damage", 3, true)
	animation.configure_animation("die", 4, true)

func _connect_signals() -> void:
	# Components
	melee_weapon.camera_shake_manager = camera_shake_manager
	melee_weapon.hit_obstacle.connect(_on_melee_hit_obstacle)
	aiming.muzzle = $Muzzle
	crunch_time.crunch_time_started.connect(_on_crunch_time_started)
	crunch_time.crunch_time_ended.connect(_on_crunch_time_ended)
	crunch_time.drain_tick.connect(_on_crunch_drain_tick)
	# Systems
	shop_manager.turret_placement_started.connect(_on_turret_placement_started)
	shop_manager.turret_placement_ended.connect(_on_turret_placement_ended)
	shop_manager.turret_bought.connect(_on_turret_bought)
	shop_manager.turret_lost.connect(_on_turret_lost)
	wave_manager.build_phase_started.connect(func() -> void: crunch_time.set_build_phase(true))
	wave_manager.combat_phase_started.connect(func(_i: int) -> void: crunch_time.set_build_phase(false))
	dash.dash_ended.connect(_on_dash_ended)

func _physics_process(delta: float) -> void:
	_process_movement(delta)
	_process_locomotion()

func _get_move_state() -> MoveState:
	if dash.is_dashing(): return MoveState.DASHING
	if knockback.is_active(): return MoveState.KNOCKED
	if not can_move: return MoveState.FROZEN
	return MoveState.NORMAL

func _process_movement(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "up", "down")
	knockback.process(delta)
	match _get_move_state():
		MoveState.DASHING:
			_base_velocity = Vector2.ZERO
			velocity = dash.get_dash_velocity()
			_add_conveyor_velocity()
			move_and_slide()
		MoveState.KNOCKED:
			_base_velocity = Vector2.ZERO
			velocity = knockback.velocity
			_add_conveyor_velocity()
			move_and_slide()
		MoveState.FROZEN:
			_base_velocity = Vector2.ZERO
			velocity = Vector2.ZERO
			move_and_slide()
		MoveState.NORMAL:
			_base_velocity = movement.calculate_velocity(_base_velocity, input_dir, delta)
			velocity = _base_velocity + _conveyor_velocity
			move_and_slide()

func _process_locomotion() -> void:
	if _is_dead:
		return
	var is_moving := velocity.length() > MIN_MOVE_SPEED
	animation.play_animation("move" if is_moving else "idle")
	if not animation.is_locked() and velocity.x != 0.0:
		_set_facing(velocity.x)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("crunch_time"):
		var can_activate := capacity.can_crunch_time() and capacity.can_afford(crunch_time.activation_cost)
		crunch_time.toggle(can_activate)
	
	if event.is_action_pressed("shoot") and capacity.can_afford(shoot_cost):
		var mouse_pos := get_global_mouse_position()
		aiming.aim_at(mouse_pos, 0.0)
		if shoot.try_shoot(aiming.get_muzzle_position(), aiming.get_aim_direction()):
			capacity.spend(shoot_cost)
			animation.play_animation("slash") # Reuse slash animation for shooting since it has the same timing needs
	
	if event.is_action_pressed("slash"):
		var mouse_pos := get_global_mouse_position()
		if melee_weapon.try_slash(mouse_pos):
			_set_facing(mouse_pos.x - global_position.x)
			animation.play_animation("slash")
	
	if event.is_action_pressed("dash"):
		var dash_dir := _get_dash_direction()
		if dash.try_dash(dash_dir):
			_handle_dash_started(dash_dir)

func _set_facing(dir_x: float) -> void:
	if dir_x == 0.0:
		return
	_facing_right = dir_x > 0.0
	animated_sprite.flip_h = not _facing_right

func _get_dash_direction() -> Vector2:
	if velocity.length() > MIN_MOVE_SPEED:
		return velocity.normalized()
	return Vector2.RIGHT if _facing_right else Vector2.LEFT

func _handle_dash_started(direction: Vector2) -> void:
	_set_facing(direction.x)
	animation.play_animation("dash")
	camera_shake_manager.shake_screen(0.15, 0.15)
	set_collision_layer_value(PLAYER_BODY_LAYER, false)

func _on_dash_ended() -> void:
	set_collision_layer_value(PLAYER_BODY_LAYER, true)

func was_hit(amount: int, knockback_force: float, from_position: Vector2) -> void:
	if _is_dead or _is_invincible():
		return
	dash.cancel_dash()
	capacity.spend(float(amount))
	if capacity.current_capacity <= 0.0:
		_handle_death(from_position)
	else:
		_handle_damage(from_position, knockback_force)

func _on_melee_hit_obstacle(hit_position: Vector2, self_knockback_force: float) -> void:
	knockback.apply(hit_position, self_knockback_force)

func _handle_damage(from_position: Vector2, knockback_force: float) -> void:
	# Apply knockback
	knockback.apply(from_position, knockback_force)
	
	# Impact effects
	freeze_frame_manager.freeze(damage_freeze_duration)
	camera_shake_manager.shake_screen(damage_screen_shake_intensity, 0.3)
	
	# Animation
	animation.play_animation("take_damage")
	
	# Notify external systems
	damaged.emit(capacity.current_capacity)

func _handle_death(from_position: Vector2) -> void:
	_is_dead = true
	crunch_time.deactivate()
	knockback.apply(from_position, death_knockback_force)
	
	# Stronger impact effects on death
	freeze_frame_manager.freeze(death_freeze_duration)
	camera_shake_manager.shake_screen(death_screen_shake_intensity, 0.3)
	
	# Disable controls
	can_move = false
	shoot.set_enabled(false)
	melee_weapon.set_enabled(false)
	dash.set_enabled(false)
	
	animation.play_animation("die")
	
	# Notify external systems
	damaged.emit(0.0)
	died.emit()

func _is_invincible() -> bool:
	return crunch_time.is_crunch_time_active() or dash.is_invincible()

func can_afford(price: float) -> bool:
	return capacity.can_afford(price)

var can_pickup: bool:
	get: return not _is_dead and not crunch_time.is_crunch_time_active() and capacity.get_current() < capacity.get_max()

func pickup(amount: int) -> void:
	capacity.gain(float(amount))

func _on_crunch_drain_tick() -> void:
	var max_drain := maxf(0.0, capacity.current_capacity - crunch_time.deactivation_threshold)
	capacity.spend(minf(1.0, max_drain))
	if capacity.current_capacity <= crunch_time.deactivation_threshold:
		crunch_time.deactivate()

func _on_turret_placement_started() -> void:
	shoot.set_enabled(false)
	melee_weapon.set_enabled(false)

func _on_turret_placement_ended() -> void:
	shoot.set_enabled(true)
	melee_weapon.set_enabled(true)

func _on_turret_bought(price: float) -> void:
	capacity.spend(price)
	capacity.lower_threshold()

func _on_turret_lost() -> void:
	capacity.raise_threshold()

func _on_crunch_time_started(buffs: Dictionary) -> void:
	capacity.spend(crunch_time.activation_cost)
	melee_weapon.set_crunch_time_active(true, buffs)
	movement.set_crunch_time_active(true, buffs["speed"])
	melee_weapon.scale *= buffs["weapon_size"]
	animated_sprite.modulate = Color(1.5, 0.5, 0.5, 1.0)

func _on_crunch_time_ended(buffs: Dictionary, _duration: float) -> void:
	melee_weapon.set_crunch_time_active(false, buffs)
	movement.set_crunch_time_active(false, buffs["speed"])
	melee_weapon.scale /= buffs["weapon_size"]
	animated_sprite.modulate = Color.WHITE
