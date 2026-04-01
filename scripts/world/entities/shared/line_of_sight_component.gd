extends Node2D
class_name LineOfSightComponent

@export var ray_offset := 6.0 ## Perpendicular offset for left/right raycasts (should be >= projectile radius)
@export var debug_draw := false ## Visualize raycasts in-game

var entity: Node2D
var ray_cast_center: RayCast2D
var ray_cast_left: RayCast2D
var ray_cast_right: RayCast2D

# Store last check results for debug drawing
var last_target: Vector2
var last_has_los := false

func _ready() -> void:
	entity = get_parent() as Node2D
	if not entity:
		push_error("LineOfSightComponent must be a child of a Node2D")
		return
	
	# Create center raycast
	ray_cast_center = RayCast2D.new()
	ray_cast_center.enabled = true
	ray_cast_center.hit_from_inside = false
	ray_cast_center.collide_with_areas = false
	ray_cast_center.collide_with_bodies = true
	ray_cast_center.collision_mask = 1
	add_child(ray_cast_center)
	
	# Create left raycast
	ray_cast_left = RayCast2D.new()
	ray_cast_left.enabled = true
	ray_cast_left.hit_from_inside = false
	ray_cast_left.collide_with_areas = false
	ray_cast_left.collide_with_bodies = true
	ray_cast_left.collision_mask = 1
	add_child(ray_cast_left)
	
	# Create right raycast
	ray_cast_right = RayCast2D.new()
	ray_cast_right.enabled = true
	ray_cast_right.hit_from_inside = false
	ray_cast_right.collide_with_areas = false
	ray_cast_right.collide_with_bodies = true
	ray_cast_right.collision_mask = 1
	add_child(ray_cast_right)

func can_see(target_position: Vector2) -> bool:
	if not entity or not ray_cast_center:
		return false
	
	var direction := (target_position - entity.global_position)
	var distance := direction.length()
	
	if distance < 1.0:
		return false
	
	var direction_normalized := direction.normalized()
	var perpendicular := Vector2(-direction_normalized.y, direction_normalized.x)
	
	# Check center ray
	ray_cast_center.global_position = entity.global_position
	ray_cast_center.target_position = direction_normalized * distance
	ray_cast_center.force_raycast_update()
	
	# Check left ray (offset perpendicular to direction)
	ray_cast_left.global_position = entity.global_position + perpendicular * ray_offset
	ray_cast_left.target_position = direction_normalized * distance
	ray_cast_left.force_raycast_update()
	
	# Check right ray (offset opposite direction)
	ray_cast_right.global_position = entity.global_position - perpendicular * ray_offset
	ray_cast_right.target_position = direction_normalized * distance
	ray_cast_right.force_raycast_update()
	
	# Store for debug drawing
	last_target = target_position
	last_has_los = not ray_cast_center.is_colliding() and not ray_cast_left.is_colliding() and not ray_cast_right.is_colliding()
	
	if debug_draw:
		queue_redraw()
	
	# All three rays must be clear
	return last_has_los

func _draw() -> void:
	if not debug_draw or not entity:
		return
	
	var direction := (last_target - entity.global_position)
	var distance := direction.length()
	
	if distance < 1.0:
		return
	
	var direction_normalized := direction.normalized()
	var perpendicular := Vector2(-direction_normalized.y, direction_normalized.x)
	
	# Choose color based on LOS status
	var color := Color.GREEN if last_has_los else Color.RED
	color.a = 0.5
	
	# Draw all three rays from entity position
	var entity_to_local := entity.global_position - global_position
	
	# Center ray
	draw_line(
		entity_to_local,
		entity_to_local + direction_normalized * distance,
		color,
		1.5
	)
	
	# Left ray
	draw_line(
		entity_to_local + perpendicular * ray_offset,
		entity_to_local + perpendicular * ray_offset + direction_normalized * distance,
		color,
		1.0
	)
	
	# Right ray
	draw_line(
		entity_to_local - perpendicular * ray_offset,
		entity_to_local - perpendicular * ray_offset + direction_normalized * distance,
		color,
		1.0
	)
