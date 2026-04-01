extends Node
class_name CircleMovementComponent

@export var drift_speed_multiplier := 0.4
@export var drift_change_interval := 0.8
@export var oscillation_amplitude := 15.0
@export var oscillation_period := 3.0

var entity: Node2D
var drift_direction: Vector2 = Vector2.ZERO
var drift_change_timer := 0.0
var oscillation_time := 0.0

func _ready() -> void:
	entity = get_parent() as Node2D
	if not entity:
		push_error("CircleMovementComponent must be a child of a Node2D")
		return
	
	oscillation_time = randf() * oscillation_period
	_randomize_drift()

func _process(delta: float) -> void:
	drift_change_timer += delta
	oscillation_time += delta
	
	if drift_change_timer >= drift_change_interval:
		drift_change_timer = 0.0
		_randomize_drift()

func _randomize_drift() -> void:
	var angle := randf() * TAU
	drift_direction = Vector2(cos(angle), sin(angle))

func get_hover_direction(player_position: Vector2, min_range: float, max_range: float) -> Vector2:
	if not entity:
		return Vector2.ZERO
	
	var orbit_distance := (min_range + max_range) / 2.0
	
	var to_target := player_position - entity.global_position
	var distance := to_target.length()
	
	if distance < 0.1:
		return drift_direction
	
	var direction_to_target := to_target.normalized()
	var tangent := Vector2(-direction_to_target.y, direction_to_target.x)
	
	var drift_bias := drift_direction.dot(tangent)
	var biased_drift := tangent * drift_bias + drift_direction * 0.3
	biased_drift = biased_drift.normalized()
	
	var oscillation_offset := sin(oscillation_time * TAU / oscillation_period) * oscillation_amplitude
	var target_distance := orbit_distance + oscillation_offset
	var distance_error := distance - target_distance
	
	var radial_component := direction_to_target if distance_error < 0 else -direction_to_target
	var radial_strength: float = clamp(abs(distance_error) / 40.0, 0.0, 0.5)
	
	return (biased_drift * (1.0 - radial_strength) + radial_component * radial_strength).normalized()
