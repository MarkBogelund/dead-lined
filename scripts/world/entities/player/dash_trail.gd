extends Line2D
class_name DashTrail

## Visual trail effect for player dash

@export var max_length: int = 20

var queue: Array = []
var is_tracking: bool = false

func _ready() -> void:
	# Connect to parent dash component
	var dash = get_parent()
	if dash and dash is DashComponent:
		dash.dash_started.connect(_on_dash_started)
		dash.dash_ended.connect(_on_dash_ended)

func _on_dash_started(_direction: Vector2) -> void:
	start_tracking()

func _on_dash_ended() -> void:
	stop_tracking()

func start_tracking() -> void:
	is_tracking = true
	queue.clear()
	clear_points()

func stop_tracking() -> void:
	is_tracking = false

func _process(_delta: float) -> void:
	if is_tracking:
		# Store current global position of this node
		queue.push_front(global_position)
		
		if queue.size() > max_length:
			queue.pop_back()
	else:
		# Gradually fade out by removing points
		if queue.size() > 0:
			queue.pop_back()
	
	# Convert global positions to local coordinates
	clear_points()
	for global_point in queue:
		add_point(to_local(global_point))
