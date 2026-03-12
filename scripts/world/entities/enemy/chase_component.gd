extends Node
class_name ChaseComponent

## Handles movement with separation/avoidance between enemies

@export var speed := 30.0
@export var separation_radius := 40.0
@export var separation_force := 120.0

var entity: CharacterBody2D

func _ready() -> void:
	entity = get_parent() as CharacterBody2D
	if not entity:
		push_error("ChaseComponent must be a child of a CharacterBody2D")

## Returns velocity with movement direction + separation applied
func move_towards(direction: Vector2) -> Vector2:
	if not entity:
		return Vector2.ZERO
	
	var move_velocity := direction * speed
	var separation_velocity := _get_separation()
	var final_velocity := move_velocity + separation_velocity
	
	if final_velocity.length() > speed:
		final_velocity = final_velocity.normalized() * speed
	
	return final_velocity

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
