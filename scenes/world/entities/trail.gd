extends Line2D
class_name Trail

var queue: Array = []
@export var max_length: int = 20
var is_tracking: bool = false

func start_tracking() -> void:
	is_tracking = true
	queue.clear()
	clear_points()

func stop_tracking() -> void:
	is_tracking = false

func _process(_delta: float) -> void:
	if is_tracking:
		# Store current global position
		queue.push_front(global_position)
		
		if queue.size() > max_length:
			queue.pop_back()
	else:
		# Gradually remove points from the end
		if queue.size() > 0:
			queue.pop_back()
	
	# Convert global positions to local coordinates
	clear_points()
	for global_point in queue:
		add_point(to_local(global_point))