extends Line2D
class_name Trail

enum CoordinateMode {
	WORLD_SPACE, ## Trail points stored in world space - shows path through level
	ANCHOR_LOCAL_SPACE, ## Trail points relative to specified anchor node
	ANCHOR_PARENT_LEVEL ## Automatically find anchor by traversing up parent hierarchy
}

@export var coordinate_mode: CoordinateMode = CoordinateMode.ANCHOR_PARENT_LEVEL
@export var max_length: int = 20

@export_group("Coordinate Anchor Settings")
@export var coordinate_anchor: Node2D ## Used in ANCHOR_LOCAL_SPACE mode - manually assign the anchor node
@export var parent_levels: int = 2 ## Used in ANCHOR_PARENT_LEVEL mode - number of levels to traverse up from Trail

var queue: Array[Vector2] = []
var is_tracking: bool = false
var _resolved_anchor: Node2D ## The actual anchor node being used (resolved in _ready)

func _ready() -> void:
	match coordinate_mode:
		CoordinateMode.WORLD_SPACE:
			# No anchor needed for world space
			_resolved_anchor = null
		
		CoordinateMode.ANCHOR_LOCAL_SPACE:
			# Use manually assigned anchor
			if not coordinate_anchor:
				push_error("Trail: ANCHOR_LOCAL_SPACE mode requires coordinate_anchor to be set!")
			_resolved_anchor = coordinate_anchor
		
		CoordinateMode.ANCHOR_PARENT_LEVEL:
			# Automatically find anchor by traversing up
			if parent_levels <= 0:
				push_error("Trail: ANCHOR_PARENT_LEVEL mode requires parent_levels > 0!")
				return
			
			var current: Node = self
			for i in range(parent_levels):
				if current:
					current = current.get_parent()
			
			if not current:
				push_error("Trail: Could not find parent at level %d" % parent_levels)
			
			_resolved_anchor = current

func start_tracking() -> void:
	is_tracking = true
	queue.clear()
	clear_points()

func stop_tracking() -> void:
	is_tracking = false

func _process(_delta: float) -> void:
	if is_tracking:
		# Store position based on coordinate mode
		match coordinate_mode:
			CoordinateMode.WORLD_SPACE:
				# Store in world space
				queue.push_front(global_position)
			
			CoordinateMode.ANCHOR_LOCAL_SPACE, CoordinateMode.ANCHOR_PARENT_LEVEL:
				# Store in anchor's local space
				if not _resolved_anchor:
					return
				var anchor_local_pos := _resolved_anchor.to_local(global_position)
				queue.push_front(anchor_local_pos)
		
		if queue.size() > max_length:
			queue.pop_back()
	else:
		# Gradually remove points from the end
		if queue.size() > 0:
			queue.pop_back()
	
	# Draw points by converting to Trail's local space
	clear_points()
	for point: Vector2 in queue:
		var trail_local_point: Vector2
		
		match coordinate_mode:
			CoordinateMode.WORLD_SPACE:
				# Convert from world space to Trail's local space
				trail_local_point = to_local(point)
			
			CoordinateMode.ANCHOR_LOCAL_SPACE, CoordinateMode.ANCHOR_PARENT_LEVEL:
				# Convert from anchor's local space to Trail's local space
				if not _resolved_anchor:
					continue
				var global_point := _resolved_anchor.to_global(point)
				trail_local_point = to_local(global_point)
		
		add_point(trail_local_point)