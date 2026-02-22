extends CharacterBody2D
class_name Player

signal damaged(current_health: int)

@onready var resource_manager: ResourceManager = get_tree().get_first_node_in_group("resource_manager")
@onready var turret_placer: TurretPlacer = get_tree().get_first_node_in_group("turret_placer")

@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var animation: AnimationComponent = $AnimationComponent

@onready var melee_weapon: MeleeWeapon = $MeleeWeapon

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var player_knockback := 200.0
@export var player_body_damage := 5

var can_move := true

const SHOOT_COST := 1
const SLASH_SELF_KNOCKBACK := 50.0
const MIN_MOVE_SPEED := 10.0

func _ready():
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	hurtbox.hit.connect(_on_hurtbox_hit)
	melee_weapon.slash_started.connect(_on_slash_started)
	turret_placer.placement_started.connect(_on_turret_placement_started)
	turret_placer.placement_ended.connect(_on_turret_placement_ended)

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	if knockback.is_active():
		velocity = knockback.velocity
	elif can_move:
		velocity = movement.calculate_velocity(velocity, input_dir, delta)
	else:
		velocity = Vector2.ZERO
	
	knockback.process(delta)
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

func _update_animation():
	if health.is_dead:
		animation.set_state(AnimationComponent.State.DIE)
		return
	
	if velocity.length() > MIN_MOVE_SPEED:
		animation.set_state(AnimationComponent.State.MOVE)
	else:
		animation.set_state(AnimationComponent.State.IDLE)

func _set_sprite_direction(dir_x: float):
	if dir_x != 0:
		animated_sprite.flip_h = dir_x < 0

func _on_slash_started(target_pos: Vector2):
	_set_sprite_direction(target_pos.x - global_position.x)
	animation.set_state(AnimationComponent.State.SLASH)

func _on_hurtbox_hit(attacker: Node) -> void:
	if health.is_dead:
		return
	
	health.take_damage(attacker.get_damage())
	knockback.apply(attacker.global_position, attacker.get_knockback())

func _on_died():
	collision_shape.set_deferred("disabled", true)
	can_move = false
	shoot.set_enabled(false)
	melee_weapon.set_enabled(false)

func _on_damaged(current_health: int):
	animation.set_state(AnimationComponent.State.DAMAGE)
	emit_signal("damaged", current_health)

func is_dead():
	return health.is_dead

func get_damage() -> int:
	return player_body_damage

func get_knockback() -> float:
	return player_knockback

func get_health():
	return health.current_health

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
