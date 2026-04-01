extends Node
class_name LineOfSightComponent

@export var sight_margin := 10.0

var entity: Node2D
var ray_cast: RayCast2D

func _ready() -> void:
	entity = get_parent() as Node2D
	if not entity:
		push_error("LineOfSightComponent must be a child of a Node2D")
		return
	
	ray_cast = RayCast2D.new()
	ray_cast.enabled = true
	ray_cast.hit_from_inside = false
	ray_cast.collide_with_areas = false
	ray_cast.collide_with_bodies = true
	ray_cast.collision_mask = 1
	add_child(ray_cast)

func can_see(target_position: Vector2) -> bool:
	if not entity or not ray_cast:
		return false
	
	var direction := (target_position - entity.global_position)
	var distance := direction.length()
	
	if distance < 1.0:
		return false
	
	var check_distance = max(distance - sight_margin, 0.0)
	if check_distance < 1.0:
		return false
	
	ray_cast.global_position = entity.global_position
	ray_cast.target_position = direction.normalized() * check_distance
	ray_cast.force_raycast_update()
	
	return not ray_cast.is_colliding()
