extends Node
class_name CircleMovementComponent

@export var orbit_distance := 150.0
@export var drift_speed_multiplier := 0.15

var entity: Node2D
var drift_direction: Vector2 = Vector2.ZERO
var drift_change_timer := 0.0
var drift_change_interval := 1.5

func _ready() -> void:
	entity = get_parent() as Node2D
	if not entity:
		push_error("CircleMovementComponent must be a child of a Node2D")
		return
	
	_randomize_drift()

func _process(delta: float) -> void:
	drift_change_timer += delta
	
	if drift_change_timer >= drift_change_interval:
		drift_change_timer = 0.0
		_randomize_drift()

func _randomize_drift() -> void:
	var angle := randf() * TAU
	drift_direction = Vector2(cos(angle), sin(angle))

func get_hover_direction(player_position: Vector2) -> Vector2:
	if not entity:
		return Vector2.ZERO
	
	var to_target := player_position - entity.global_position
	var distance := to_target.length()
	
	if distance < 0.1:
		return drift_direction
	
	var distance_error := distance - orbit_distance
	var radial_component := to_target.normalized() if distance_error < 0 else -to_target.normalized()
	var radial_strength: float = clamp(abs(distance_error) / 30.0, 0.0, 1.0)
	
	return (drift_direction * (1.0 - radial_strength) + radial_component * radial_strength).normalized()

func is_in_range(distance: float) -> bool:
	return distance >= 120.0 and distance <= 180.0
