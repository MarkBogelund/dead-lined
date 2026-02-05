extends StaticBody2D

@onready var canon: Sprite2D = $Canon
@onready var muzzle: Marker2D = $Canon/Muzzle
@onready var shoot: ShootComponent = $ShootComponent

@export var projectile_scene: PackedScene
@export var detection_range := 500.0		# in pixels
@export var detection_angle := 0.2
@export var rotation_speed := 6.0			# radians per second
@export var fire_rate := 0.5				# seconds per shot

var game_manager: Node

const UP_FACING_OFFSET := PI / 2

var fire_timer := 0.0
var build_phase := true

func _ready():
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		push_error("GameManager not found in group game_managers")
		return

	game_manager.connect(
		"build_phase_started",
		Callable(self, "_on_build_phase_started")
	)

	game_manager.connect(
		"combat_phase_started",
		Callable(self, "_on_combat_phase_started")
	)

func _process(delta):
	if build_phase:
		return
	
	fire_timer -= delta

	var target := get_closest_enemy_in_range()
	if target == null:
		return

	rotate_towards(target.global_position, delta)

	if can_fire_at(target):
		shoot.shoot(target.global_position, muzzle.global_position)

func _on_build_phase_started() -> void:
	build_phase = true

func _on_combat_phase_started(_wave_index: int) -> void:
	build_phase = false

func get_closest_enemy_in_range() -> CharacterBody2D:
	var targets: Array[Node] = []
	targets.append_array(get_tree().get_nodes_in_group("enemies"))
	targets.append_array(get_tree().get_nodes_in_group("player"))

	var closest: CharacterBody2D = null
	var closest_dist := detection_range * detection_range

	for target in targets:
		if target.is_dead():
			continue
		var dist := global_position.distance_squared_to(target.global_position)
		if dist <= closest_dist:
			closest_dist = dist
			closest = target

	return closest

func rotate_towards(target_pos: Vector2, delta: float):
	var dir := target_pos - canon.global_position
	var target_angle := dir.angle() + UP_FACING_OFFSET

	canon.rotation = lerp_angle(
		canon.rotation,
		target_angle,
		rotation_speed * delta
	)

func can_fire_at(target: Node2D) -> bool:
	if fire_timer > 0:
		return false

	var dir := target.global_position - canon.global_position
	var target_angle := dir.angle() + UP_FACING_OFFSET

	return abs(angle_difference(canon.rotation, target_angle)) < detection_angle
