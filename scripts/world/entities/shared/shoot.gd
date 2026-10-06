extends Node
class_name ShootComponent

@export var projectile_scene: PackedScene
@export var projectile_damage := 10
@export var projectile_knockback := 200.0
@export var shoot_cooldown := 0.5
@export var projectile_speed := 300.0
## Seconds before each projectile despawns on its own. 0 or less = never.
@export var projectile_lifetime := 2.0
## Projectiles per shot, spread evenly across spread_angle.
@export var projectile_count := 1
## Total fan angle in degrees between the outermost projectiles.
@export var spread_angle := 0.0

var _shoot_timer := 0.0
var shooting_activated := true

func _process(delta: float) -> void:
	if _shoot_timer > 0.0:
		_shoot_timer -= delta

func initialize(p_shoot_cooldown: float, p_damage: int, p_knockback: float, p_speed: float, p_lifetime: float) -> void:
	shoot_cooldown = p_shoot_cooldown
	projectile_damage = p_damage
	projectile_knockback = p_knockback
	projectile_speed = p_speed
	projectile_lifetime = p_lifetime

func set_spread(p_projectile_count: int, p_spread_angle: float) -> void:
	projectile_count = p_projectile_count
	spread_angle = p_spread_angle

func set_enabled(enabled: bool) -> void:
	shooting_activated = enabled

func is_ready() -> bool:
	return _shoot_timer <= 0.0 and shooting_activated

func get_cooldown_progress() -> float:
	if shoot_cooldown <= 0.0:
		return 1.0
	return clampf(1.0 - _shoot_timer / shoot_cooldown, 0.0, 1.0)

func start_cooldown() -> void:
	_shoot_timer = shoot_cooldown

func try_shoot(from_pos: Vector2, direction: Vector2) -> bool:
	if _shoot_timer > 0.0 or not shooting_activated:
		return false

	if projectile_scene == null:
		push_error("No projectile scene assigned to ShootComponent")
		return false

	for i in projectile_count:
		var spread_offset := 0.0
		if projectile_count > 1:
			spread_offset = deg_to_rad(spread_angle) * (float(i) / (projectile_count - 1) - 0.5)
		var projectile_direction := direction.rotated(spread_offset)
		var projectile := projectile_scene.instantiate()
		projectile.set_orientation(from_pos, projectile_direction.angle(), projectile_direction)
		projectile.set_parameters(projectile_speed, projectile_damage, projectile_knockback, projectile_lifetime)
		get_tree().current_scene.add_child(projectile)

	start_cooldown()
	
	return true
