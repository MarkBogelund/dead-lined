extends Node
class_name ChaseComponent

@export var speed := 30.0
@export var separation_radius := 40.0
@export var separation_force := 120.0
@export var target_group := "player"

var entity: CharacterBody2D
var target: Node2D

func _ready() -> void:
	var parent = get_parent()
	if parent is CharacterBody2D:
		entity = parent
	else:
		push_error("ChaseComponent must be a child of a CharacterBody2D")
	
	await get_tree().process_frame
	target = get_tree().get_first_node_in_group(target_group)

func get_velocity() -> Vector2:
	if GameOverManager.is_game_over:
		return Vector2.ZERO
	
	if not target or not entity:
		return Vector2.ZERO
	
	var chase_velocity := _get_chase_velocity()
	var separation_velocity := _get_separation_velocity()
	var desired_velocity := chase_velocity + separation_velocity
	
	if desired_velocity.length() > speed:
		desired_velocity = desired_velocity.normalized() * speed
	
	return desired_velocity

func _get_chase_velocity() -> Vector2:
	var direction := (target.global_position - entity.global_position).normalized()
	return direction * speed

func _get_separation_velocity() -> Vector2:
	var push := Vector2.ZERO
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy == entity:
			continue
		if enemy.health.is_dead:
			continue
		
		var offset: Vector2 = entity.global_position - enemy.global_position
		var dist := offset.length()
		
		if dist > 0.0 and dist < separation_radius:
			var strength := (separation_radius - dist) / separation_radius
			push += offset.normalized() * strength
	
	return push * separation_force
