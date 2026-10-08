extends TileMapLayer
class_name NavigationMapLayer

## Replaces the per-tile navigation with one mesh baked at runtime: walkable = cells whose tile has a navigation
## polygon, minus wall/block colliders and conveyor belts, all shrunk by agent_radius so paths keep enemy bodies
## clear of walls and corners.

## Roughly the enemy body radius; paths stay at least this far from obstacles.
@export var agent_radius := 14.0
## Extra distance paths keep from conveyor belts on top of agent_radius, so enemy bodies never brush a belt edge.
@export var conveyor_clearance := 10.0
## Physics layers whose colliders block walking.
@export_flags_2d_physics var obstacle_collision_mask := 1
## Static bodies in this group (plus this tilemap) are parsed as obstacles, e.g. the shop station.
@export var obstacle_group: StringName = &"navigation_obstacles"

const NAVIGATION_LAYER := 0

var _region: NavigationRegion2D

func _ready() -> void:
	add_to_group(obstacle_group)
	navigation_enabled = false
	_region = NavigationRegion2D.new()
	add_child(_region)
	_region.navigation_polygon = _bake()

func _bake() -> NavigationPolygon:
	var nav_polygon := NavigationPolygon.new()
	nav_polygon.agent_radius = agent_radius
	nav_polygon.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_polygon.parsed_collision_mask = obstacle_collision_mask
	nav_polygon.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav_polygon.source_geometry_group_name = obstacle_group
	var source := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(nav_polygon, source, self)
	_add_walkable_cells(source)
	_add_conveyor_obstructions(source)
	NavigationServer2D.bake_from_source_geometry_data(nav_polygon, source)
	return nav_polygon

func _add_walkable_cells(source: NavigationMeshSourceGeometryData2D) -> void:
	var half := Vector2(tile_set.tile_size) * 0.5
	for cell: Vector2i in get_used_cells():
		var tile_data := get_cell_tile_data(cell)
		if not tile_data or not tile_data.get_navigation_polygon(NAVIGATION_LAYER):
			continue
		var center := map_to_local(cell)
		source.add_traversable_outline(PackedVector2Array([
			center + Vector2(-half.x, -half.y), center + Vector2(half.x, -half.y),
			center + Vector2(half.x, half.y), center + Vector2(-half.x, half.y)]))

## Belts push faster than enemies walk, so paths must never run along them.
func _add_conveyor_obstructions(source: NavigationMeshSourceGeometryData2D) -> void:
	for belt: Node in get_tree().get_nodes_in_group(&"conveyor_belts"):
		for child: Node in belt.get_children():
			var shape_node := child as CollisionShape2D
			if not shape_node or not shape_node.shape is RectangleShape2D:
				continue
			var half_size := (shape_node.shape as RectangleShape2D).size * 0.5 + Vector2.ONE * conveyor_clearance
			var outline := PackedVector2Array()
			for corner: Vector2 in [Vector2(-half_size.x, -half_size.y), Vector2(half_size.x, -half_size.y), Vector2(half_size.x, half_size.y), Vector2(-half_size.x, half_size.y)]:
				outline.append(to_local(shape_node.global_transform * corner))
			source.add_projected_obstruction(outline, false)
