extends Node
class_name ChaseComponent

## Handles movement with separation/avoidance between enemies

@export var speed := 30.0
@export var separation_radius := 40.0
@export var separation_force := 120.0
@export_range(0.0, 1.0) var smoothing := 0.1 ## Lower = more momentum, Higher = more responsive

var entity: CharacterBody2D
var current_velocity := Vector2.ZERO

func _ready() -> void:
	entity = get_parent() as CharacterBody2D
	if not entity:
		push_error("ChaseComponent must be a child of a CharacterBody2D")

## Returns velocity with movement direction + separation applied, with smoothing
func move_towards(direction: Vector2) -> Vector2:
	if not entity:
		return Vector2.ZERO
	
	var move_velocity := direction * speed
	var separation_velocity := _get_separation()
	var target_velocity := move_velocity + separation_velocity
	
	if target_velocity.length() > speed:
		target_velocity = target_velocity.normalized() * speed
	
	current_velocity = current_velocity.lerp(target_velocity, smoothing)
	return current_velocity

func _get_separation() -> Vector2:
	var push := Vector2.ZERO
	var enemies := get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy == entity or enemy.is_dead():
			continue
		
		var offset: Vector2 = entity.global_position - enemy.global_position
		var dist: float = offset.length()
		
		if dist > 0.0 and dist < separation_radius:
			var strength: float = (separation_radius - dist) / separation_radius
			push += offset.normalized() * strength
	
	return push * separation_force
